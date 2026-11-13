'use strict';
/**
 * Клиент платного API реестра предприятий Inforegister (https://api.ir.ee).
 * Каждый HTTP-вызов тратит годовой лимит (в т.ч. 404), поэтому: формат кода проверяется до вызова,
 * ответы (и «данных нет») кэшируются, число платных вызовов за запуск ограничено, резерв годового лимита не расходуется.
 * Код совместим с Node < 14 (без ?? и ?.).
 */
const https = require('https');

const BASE_URL = 'https://api.ir.ee';
const REG_CODE_RE = /^\d{8}$/;
const DAY_MS = 24 * 60 * 60 * 1000;
const BUNDLE_TTL_MS = 30 * DAY_MS;
const NEGATIVE_TTL_MS = 30 * DAY_MS;
const RATE_LIMIT_PAUSE_MS = 60 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 20000;
const META_KEY = 'meta:ratelimit';

function toNumber(v) {
    if (v === null || v === undefined || v === '') return null;
    const n = typeof v === 'number' ? v : parseFloat(String(v));
    return isFinite(n) ? n : null;
}

function str(v) {
    return typeof v === 'string' && v.trim() !== '' ? v.trim() : null;
}

function intEnv(name, fallback) {
    const n = parseInt(process.env[name], 10);
    return isFinite(n) && n >= 0 ? n : fallback;
}

/** Год данных EMTA: в январе-феврале текущий год ещё не опубликован */
function defaultDataYear(nowMs) {
    const d = new Date(nowMs === undefined ? Date.now() : nowMs);
    return d.getUTCMonth() <= 1 ? d.getUTCFullYear() - 1 : d.getUTCFullYear();
}

/** Сжатие ответа base_info_summation до нужных полей */
function summarizeBundle(raw, year) {
    raw = raw || {};
    const info = raw.base_info || {};
    const addr = Array.isArray(raw.base_info_address) && raw.base_info_address.length ? raw.base_info_address[0] : null;
    const contacts = {emails: [], phones: [], webs: []};
    const seen = {};
    (Array.isArray(raw.base_info_contact) ? raw.base_info_contact : []).forEach(function (c) {
        const value = str(c && c.contact);
        const type = String((c && c.type) || '').toLowerCase();
        if (!value) return;
        const key = type + '|' + value.toLowerCase();
        if (seen[key]) return;
        seen[key] = true;
        if (type === 'email') contacts.emails.push(value);
        else if (type === 'web') contacts.webs.push(value);
        else if (/phone|tel|mobile/.test(type)) contacts.phones.push(value);
    });

    const quarters = (Array.isArray(raw.base_info_emta_company_taxes) ? raw.base_info_emta_company_taxes : [])
        .map(function (q) {
            return {period: String((q && q.period) || ''), employeeCount: toNumber(q && q.employee_count)};
        })
        .filter(function (q) {
            return q.period !== '';
        })
        .sort(function (a, b) {
            return a.period.localeCompare(b.period);
        });
    const latest = quarters.length ? quarters[quarters.length - 1] : null;

    return {
        name: str(info.company_name),
        regCode: str(info.reg_code),
        registryStatus: str(info.registry_status_text),
        businessType: str(info.business_type),
        vatNumber: str(info.kmkr_number),
        address: addr ? {fullAddress: str(addr.full_address), city: str(addr.city), street: str(addr.street)} : null,
        contacts: contacts,
        latestEmployeeCount: latest ? latest.employeeCount : null,
        latestPeriod: latest ? latest.period : null,
        year: year
    };
}

/** HTTPS GET с таймаутом; не бросает исключение на HTTP-статусы */
function httpGet(url, headers, insecureTls) {
    return new Promise(function (resolve, reject) {
        const reqOptions = {headers: headers};
        if (insecureTls) {
            reqOptions.rejectUnauthorized = false; // осознанно: сертификат цепочки не проверяется (см. параметр insecureTls)
        }
        const req = https.get(url, reqOptions, function (res) {
            const chunks = [];
            res.on('data', function (c) {
                chunks.push(c);
            });
            res.on('end', function () {
                resolve({status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks).toString('utf8')});
            });
        });
        req.setTimeout(REQUEST_TIMEOUT_MS, function () {
            req.destroy(new Error('timeout'));
        });
        req.on('error', reject);
    });
}

function fail(regCode, reason, message) {
    return {ok: false, regCode: regCode, reason: reason, message: message};
}

/**
 * Создает клиент с собственным счетчиком расходов (один клиент на запуск).
 * @param {Object} opts {store, apiKey, maxCalls, minRemaining, dryRun, insecureTls, http, now}
 *   insecureTls: не проверять TLS-сертификат api.ir.ee (для сети с подменой сертификата); по умолчанию false
 *   store: {get(key) => Promise<{payload, negative}|null>, set(key, payload, negative, ttlMs) => Promise}
 */
function createClient(opts) {
    opts = opts || {};
    const store = opts.store || null;
    const http = opts.http || httpGet;
    const nowFn = opts.now || Date.now;
    const state = {spent: 0, remainingYear: null, authFailed: false, rateLimitedUntil: 0, metaLoaded: false};

    async function getBundle(regCodeInput, year) {
        const regCode = String(regCodeInput === undefined || regCodeInput === null ? '' : regCodeInput).trim();
        if (!REG_CODE_RE.test(regCode)) {
            return fail(regCode, 'invalid_reg_code', 'Reg.kood ei ole 8-kohaline (päringut ei tehta)');
        }
        const y = year || defaultDataYear(nowFn());
        const cacheKey = 'bundle:' + regCode + ':' + y;
        const now = nowFn();

        if (store) {
            let cached = null;
            try {
                cached = await store.get(cacheKey);
            } catch (e) {
                cached = null; // кэш недоступен: работаем без него
            }
            if (cached) {
                if (cached.negative) return fail(regCode, 'not_found', 'Inforegister: andmeid ei ole (cache)');
                return {ok: true, regCode: regCode, data: cached.payload, source: 'cache', remainingYear: state.remainingYear};
            }
        }

        if (opts.dryRun) {
            return fail(regCode, 'dry_run_no_spend', 'Dry-run: päringut ei tehta, cache on tühi');
        }
        const apiKey = opts.apiKey;
        if (!apiKey || String(apiKey).trim() === '') {
            return fail(regCode, 'no_api_key', 'API võti puudub (ou.config.properties.INFOREGISTER_API_KEY)');
        }
        if (state.authFailed) return fail(regCode, 'unauthorized', 'Inforegister 401: võti on vale, päringud keelatud');
        if (now < state.rateLimitedUntil) return fail(regCode, 'rate_limited', 'Inforegister 429: päringud peatatud');

        if (store && !state.metaLoaded) {
            state.metaLoaded = true;
            try {
                const meta = await store.get(META_KEY);
                const rem = meta && meta.payload ? toNumber(meta.payload.remainingYear) : null;
                if (rem !== null && state.remainingYear === null) state.remainingYear = rem;
            } catch (e) {
                // хранилище недоступно: опираемся на заголовки ответа и потолок запуска
            }
        }

        const maxCalls = opts.maxCalls !== undefined ? opts.maxCalls : intEnv('INFOREGISTER_MAX_CALLS', 10);
        if (state.spent >= maxCalls) {
            return fail(regCode, 'budget_exhausted', 'Päringute limiit täis (' + maxCalls + ')');
        }
        const minRemaining = opts.minRemaining !== undefined ? opts.minRemaining : intEnv('INFOREGISTER_MIN_REMAINING', 20);
        if (state.remainingYear !== null && state.remainingYear <= minRemaining) {
            return fail(regCode, 'year_limit_reserve', 'Aastalimiidi jääk ' + state.remainingYear + ' <= reserv ' + minRemaining);
        }

        state.spent += 1; // резервируем вызов до отправки

        try {
            const url = (opts.baseUrl || process.env.INFOREGISTER_BASE_URL || BASE_URL) +
                '/base_info_summation/reg_code/' + regCode + '/year/' + y;
            const resp = await http(url, {Authorization: apiKey}, !!opts.insecureTls);
            const h = resp.headers || {};
            const remaining = toNumber(h['x-ratelimit-remaining-year'] !== undefined ? h['x-ratelimit-remaining-year'] : h['ratelimit-remaining']);
            if (remaining !== null) {
                state.remainingYear = remaining;
                if (store) {
                    const resetSec = toNumber(h['ratelimit-reset']);
                    try {
                        await store.set(META_KEY, {remainingYear: remaining}, false, resetSec !== null && resetSec > 0 ? resetSec * 1000 : 30 * DAY_MS);
                    } catch (e) {
                        // не критично
                    }
                }
            }

            if (resp.status === 401) {
                state.authFailed = true;
                return fail(regCode, 'unauthorized', 'Inforegister 401');
            }
            if (resp.status === 429) {
                state.rateLimitedUntil = now + RATE_LIMIT_PAUSE_MS;
                return fail(regCode, 'rate_limited', 'Inforegister 429');
            }
            if (resp.status === 404) {
                if (store) {
                    try {
                        await store.set(cacheKey, null, true, NEGATIVE_TTL_MS);
                    } catch (e) {
                        // не критично
                    }
                }
                return fail(regCode, 'not_found', 'Inforegister: andmeid ei ole (404)');
            }
            if (resp.status < 200 || resp.status >= 300) {
                return fail(regCode, 'http_error', 'Inforegister HTTP ' + resp.status);
            }

            const data = summarizeBundle(JSON.parse(resp.body), y);
            if (store) {
                try {
                    await store.set(cacheKey, data, false, BUNDLE_TTL_MS);
                } catch (e) {
                    // не критично
                }
            }
            return {ok: true, regCode: regCode, data: data, source: 'api', remainingYear: state.remainingYear};
        } catch (err) {
            return fail(regCode, err && err.message === 'timeout' ? 'timeout' : 'http_error',
                'Inforegister: ' + (err && err.message ? err.message : 'võrgu viga'));
        }
    }

    return {
        getBundle: getBundle,
        getUsage: function () {
            return {spent: state.spent, remainingYear: state.remainingYear};
        }
    };
}

exports.createClient = createClient;
exports.summarizeBundle = summarizeBundle;
exports.defaultDataYear = defaultDataYear;
exports.REG_CODE_RE = REG_CODE_RE;
