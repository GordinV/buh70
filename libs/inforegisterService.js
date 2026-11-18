'use strict';
const crypto = require('crypto');
const db = require('./db');
const inforegister = require('./inforegister');
const ariregisterStore = require('./ariregisterStore');
const Doc = require('./../classes/DocumentTemplate');
const config = require('./inforegisterConfig');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const CONFIG_REKV_ID = 3; // учреждение, в чьем ou.config хранятся ключ и токены Inforegister
const FLOW_NAME = 'getInforegister';
const LOOKUP_FLOW_NAME = 'inforegisterLookup';
const SOURCE_FLOW_NAME = 'checkAsutusAvailability';
const SOURCE_LOG_WINDOW_HOURS = 24;

// статусы обработки организации
const STATUS = {
    CREATED: 'created',
    WOULD_CREATE: 'would_create',
    EXISTS: 'exists',
    FOUND: 'found',
    NEEDS_MANUAL: 'needs_manual',
    NOT_FOUND: 'not_found',
    CLOSED: 'closed',
    UNAVAILABLE: 'registry_unavailable',
    ERROR: 'error'
};

const UNAVAILABLE_REASONS = [
    'no_api_key',
    'registry_not_loaded',
    'unauthorized',
    'rate_limited',
    'budget_exhausted',
    'year_limit_reserve',
    'timeout',
    'http_error',
    'dry_run_no_spend'
];

/** dry_run включен по умолчанию; выключается только явным false / 'false' / 0 / '0' */
function parseDryRun(value) {
    if (value === false || value === 0 || value === '0') return false;
    if (typeof value === 'string' && value.trim().toLowerCase() === 'false') return false;
    return true;
}

/**
 * Находит лог check_asutus и возвращает его result.missing
 * @returns {Promise<{sourceLogId: number|null, missing: string[]}>}
 */
async function findMissing(sourceLogParam) {
    let sql;
    let sqlParams;
    const paramId = Number(sourceLogParam);
    if (Number.isInteger(paramId) && paramId > 0) {
        sql = `select l.id, l.propertis -> 'result' -> 'missing' as missing
               from ou.logs l
               where l.id = $1
                 and l.propertis ->> 'flow' = $2`;
        sqlParams = [paramId, SOURCE_FLOW_NAME];
    } else {
        sql = `select l.id, l.propertis -> 'result' -> 'missing' as missing
               from ou.logs l
               where l.propertis ->> 'flow' = $1
                 and (l.propertis ->> 'exec_start')::timestamptz >= now() - ($2::integer * interval '1 hour')
               order by l.id desc
               limit 1`;
        sqlParams = [SOURCE_FLOW_NAME, SOURCE_LOG_WINDOW_HOURS];
    }
    const r = await db.queryDb(sql, sqlParams, null, null, null, null, config);
    const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
    if (!row) return {sourceLogId: null, missing: []};

    const list = Array.isArray(row.missing) ? row.missing : [];
    const unique = [];
    list.forEach(function (v) {
        const s = String(v === undefined || v === null ? '' : v).trim();
        if (s !== '' && unique.indexOf(s) === -1) unique.push(s);
    });
    return {sourceLogId: Number(row.id), missing: unique};
}

/**
 * Ключ Inforegister из конфигурации учреждения configRekvId (ou.config.properties.INFOREGISTER_API_KEY) через модель config.
 * Ключ нигде не логируется и не попадает в result.
 * @returns {Promise<string>} ключ или пустая строка
 */
async function getApiKey(userId, configRekvId) {
    try {
        const docConfig = new Doc('config', configRekvId, userId, configRekvId, 'lapsed');
        const configData = await docConfig.select();
        const row = configData && configData.row && configData.row[0] ? configData.row[0] : null;
        return row && row.inforegister_api_key ? String(row.inforegister_api_key).trim() : '';
    } catch (error) {
        console.error('[getInforegister] Config read failed:', error.message);
        return '';
    }
}

/**
 * Проверяет hash-токен по ou.config.properties.INFOREGISTER_TOKENS (sha256 + timingSafeEqual) и scope ('batch'|'lookup').
 * Сам hash не логируется.
 */
async function resolveInforegisterToken(hash, scope, configRekvId) {
    const rawHash = typeof hash === 'string' ? hash.trim() : '';
    if (!rawHash) {
        return {ok: false, status: 401, reason: 'unauthorized_hash', error: 'Autoriseerimise hash puudub'};
    }

    const effectiveRekvId = configRekvId || CONFIG_REKV_ID;
    let tokens = [];
    try {
        const r = await db.queryDb(
            `select properties -> 'INFOREGISTER_TOKENS' as tokens from ou.config where rekvid = $1 limit 1`,
            [effectiveRekvId],
            null, null, null, null, config
        );
        const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
        tokens = row && Array.isArray(row.tokens) ? row.tokens : [];
    } catch (error) {
        console.error('[inforegister] Token config read failed:', error.message);
        return {ok: false, status: 401, reason: 'unauthorized_hash', error: 'Autoriseerimine ebaõnnestus'};
    }

    const digestBuf = crypto.createHash('sha256').update(rawHash, 'utf8').digest();
    let matched = null;
    for (let i = 0; i < tokens.length; i++) {
        const entry = tokens[i];
        if (!entry || entry.active === false || typeof entry.token_sha256 !== 'string') continue;
        const hex = entry.token_sha256.trim().toLowerCase();
        if (!/^[0-9a-f]{64}$/.test(hex)) continue;
        const entryBuf = Buffer.from(hex, 'hex');
        if (entryBuf.length === digestBuf.length && crypto.timingSafeEqual(digestBuf, entryBuf)) {
            matched = entry;
            break;
        }
    }

    if (!matched) {
        return {ok: false, status: 401, reason: 'unauthorized_hash', error: 'Vigane või tühistatud hash'};
    }

    if (scope) {
        const scopes = Array.isArray(matched.scopes) ? matched.scopes : [];
        if (scopes.indexOf(scope) === -1) {
            return {ok: false, status: 403, reason: 'forbidden_scope', error: 'Puudub õigus sellele päringule'};
        }
    }

    return {
        ok: true,
        userId: Number(matched.user_id),
        rekvId: Number(matched.rekv_id),
        label: matched.label ? String(matched.label) : null
    };
}

/** Постоянный кэш в libs.registry_cache; при отсутствии таблицы клиент работает без кэша */
function makeCacheStore() {
    return {
        get: async function (key) {
            const r = await db.queryDb(
                `select payload, negative, fetched_at from libs.registry_cache where cache_key = $1 and expires_at > now()`,
                [key], null, null, null, null, config);
            const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
            return row ? {payload: row.payload, negative: !!row.negative, fetchedAt: row.fetched_at || null} : null;
        },
        set: async function (key, payload, negative, ttlMs) {
            await db.queryDb(
                `insert into libs.registry_cache (cache_key, payload, negative, fetched_at, expires_at)
                 values ($1, $2::jsonb, $3, now(), now() + ($4::bigint * interval '1 millisecond'))
                 on conflict (cache_key) do update
                     set payload = excluded.payload, negative = excluded.negative,
                         fetched_at = excluded.fetched_at, expires_at = excluded.expires_at`,
                [key, payload === null || payload === undefined ? null : JSON.stringify(payload), !!negative, Math.round(ttlMs)],
                null, null, null, null, config);
        }
    };
}

function createInforegisterClient(opts) {
    opts = opts || {};
    return inforegister.createClient({
        apiKey: opts.apiKey,
        store: opts.store || makeCacheStore(),
        maxCalls: opts.maxCalls,
        minRemaining: opts.minRemaining,
        dryRun: opts.dryRun === true,
        skipCacheRead: opts.skipCacheRead === true,
        insecureTls: opts.insecureTls === true,
        http: opts.http,
        now: opts.now
    });
}

async function asutusExists(regkood) {
    const r = await db.queryDb(
        `select id from libs.asutus where ltrim(rtrim(regkood)) = $1 and staatus < 3 limit 1`,
        [regkood], null, null, null, null, config);
    return r && Array.isArray(r.data) && r.data[0] ? Number(r.data[0].id) : null;
}

async function readLocalAsutus(regkood) {
    const r = await db.queryDb(
        `select id, regkood, nimetus, aadress, kmkr, email, tel, staatus
         from libs.asutus
         where ltrim(rtrim(regkood)) = $1 and staatus < 3
         order by id asc
         limit 1`,
        [regkood], null, null, null, null, config);
    return r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
}

function resolveOmvorm(businessType) {
    if (!businessType) return '';
    const trimmed = String(businessType).trim();
    if (!trimmed) return '';
    const abbrevValues = Object.keys(ariregisterStore.LEGAL_FORM_ABBREV).map(function (k) {
        return ariregisterStore.LEGAL_FORM_ABBREV[k];
    });
    if (abbrevValues.indexOf(trimmed) !== -1 && trimmed.length <= 20) {
        return trimmed;
    }
    const mapped = ariregisterStore.abbreviateLegalForm(trimmed);
    if (mapped && abbrevValues.indexOf(mapped) !== -1 && mapped.length <= 20) {
        return mapped;
    }
    return '';
}

/**
 * Формирует JSON для libs.sp_salvesta_asutus из данных реестра.
 * omvorm в libs.asutus char(20) NOT NULL: заполняется сокращением из LEGAL_FORM_ABBREV (если есть и <= 20 символов), иначе ''.
 */
function buildAsutusPayload(regkood, bundle) {
    const contacts = bundle.contacts || {emails: [], phones: []};
    return {
        id: 0,
        data: {
            id: 0,
            regkood: regkood,
            nimetus: bundle.name,
            omvorm: resolveOmvorm(bundle.businessType),
            aadress: bundle.address && bundle.address.fullAddress ? bundle.address.fullAddress : '',
            kontakt: '',
            tel: contacts.phones && contacts.phones.length ? contacts.phones[0] : '',
            email: contacts.emails && contacts.emails.length ? contacts.emails[0] : '',
            kmkr: bundle.vatNumber || '',
            mark: 'Äriregister (automaatselt lisatud)',
            muud: '',
            pank: '',
            tp: ''
        }
    };
}

async function saveAsutus(payload, userId, rekvId) {
    const r = await db.queryDb(`select libs.sp_salvesta_asutus($1::json, $2::integer, $3::integer) as id`,
        [JSON.stringify(payload), userId, rekvId], null, null, null, null, config);
    const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
    return row && row.id ? Number(row.id) : null;
}

/** Закрытое предприятие: статус реестра не содержит «kantud» (напр. «Registrisse kantud») */
function isClosed(bundle) {
    const s = bundle && bundle.registryStatus ? String(bundle.registryStatus).toLowerCase() : '';
    return s !== '' && s.indexOf('kantud') === -1;
}

function mapReasonToStatus(reason) {
    if (reason === 'invalid_reg_code') return STATUS.NEEDS_MANUAL;
    if (reason === 'not_found') return STATUS.NOT_FOUND;
    if (UNAVAILABLE_REASONS.indexOf(reason) !== -1) return STATUS.UNAVAILABLE;
    return STATUS.ERROR;
}

function normStr(v) {
    return v === undefined || v === null ? '' : String(v).trim().replace(/\s+/g, ' ').toLowerCase();
}

function buildDiff(local, bundle) {
    if (!local || !bundle) return [];
    const diff = [];

    const regName = bundle.name ? String(bundle.name).trim() : '';
    if (regName && normStr(local.nimetus) !== normStr(regName)) {
        diff.push({field: 'nimetus', local: local.nimetus || null, registry: regName});
    }

    const regAddr = bundle.address && bundle.address.fullAddress ? String(bundle.address.fullAddress).trim() : '';
    if (regAddr && normStr(local.aadress) !== normStr(regAddr)) {
        diff.push({field: 'aadress', local: local.aadress || null, registry: regAddr});
    }

    const regKmkr = bundle.vatNumber ? String(bundle.vatNumber).trim() : '';
    if (regKmkr && normStr(local.kmkr) !== normStr(regKmkr)) {
        diff.push({field: 'kmkr', local: local.kmkr || null, registry: regKmkr});
    }

    const contacts = bundle.contacts || {};
    const regEmails = Array.isArray(contacts.emails) ? contacts.emails : [];
    if (regEmails.length > 0) {
        const localEmail = normStr(local.email);
        const hasEmail = localEmail !== '' && regEmails.some(function (e) {
            return normStr(e) === localEmail;
        });
        if (!hasEmail) {
            diff.push({field: 'email', local: local.email || null, registry: regEmails[0]});
        }
    }

    const regPhones = Array.isArray(contacts.phones) ? contacts.phones : [];
    if (regPhones.length > 0) {
        const localPhone = normStr(local.tel).replace(/\s+/g, '');
        const hasPhone = localPhone !== '' && regPhones.some(function (p) {
            return normStr(p).replace(/\s+/g, '') === localPhone;
        });
        if (!hasPhone) {
            diff.push({field: 'tel', local: local.tel || null, registry: regPhones[0]});
        }
    }

    if (isClosed(bundle)) {
        diff.push({field: 'closed', local: false, registry: bundle.registryStatus || true});
    }

    return diff;
}

/**
 * Обрабатывает одну организацию (пакетный режим). Не бросает исключение: ошибка фиксируется в статусе.
 */
async function processOne(regkood, client, ctx) {
    const item = {regkood: regkood, status: null, nimetus: null, asutus_id: null, source: null, error: null};
    try {
        const existingId = await asutusExists(regkood);
        if (existingId) {
            item.status = STATUS.EXISTS;
            item.asutus_id = existingId;
            return item;
        }

        const res = await client.getBundle(regkood);
        if (!res.ok) {
            item.status = mapReasonToStatus(res.reason);
            item.error = res.reason + ': ' + (res.message || res.error || '');
            return item;
        }

        const bundle = res.data;
        item.source = res.source;
        item.nimetus = bundle.name;

        if (!bundle.name) {
            item.status = STATUS.NOT_FOUND;
            item.error = 'Äriregister ei tagastanud nimetust';
            return item;
        }
        if (isClosed(bundle)) {
            item.status = STATUS.CLOSED;
            item.error = 'Registri staatus: ' + bundle.registryStatus;
            return item;
        }

        if (ctx.dryRun) {
            item.status = STATUS.WOULD_CREATE;
            return item;
        }

        item.asutus_id = await saveAsutus(buildAsutusPayload(regkood, bundle), ctx.userId, ctx.rekvId);
        item.status = item.asutus_id ? STATUS.CREATED : STATUS.ERROR;
        if (!item.asutus_id) item.error = 'libs.sp_salvesta_asutus ei tagastanud id';
    } catch (error) {
        item.status = STATUS.ERROR;
        item.error = error.message;
    }
    return item;
}

/**
 * Синхронный поиск одной организации по regkood с перепроверкой локальных данных (без сохранения в libs.asutus).
 */
async function lookupOne(regkood, client, options) {
    options = options || {};
    const local = await readLocalAsutus(regkood);
    const res = await client.getBundle(regkood, options.year);

    if (!res.ok) {
        return {
            ok: false,
            regkood: regkood,
            status: mapReasonToStatus(res.reason),
            reason: res.reason,
            error: res.message,
            source: null,
            fetched_at: null,
            closed: false,
            local: local,
            registry: null,
            diff: []
        };
    }

    const bundle = res.data;
    const closed = isClosed(bundle);
    return {
        ok: true,
        regkood: regkood,
        status: closed ? STATUS.CLOSED : STATUS.FOUND,
        source: res.source,
        fetched_at: res.fetchedAt || null,
        closed: closed,
        local: local,
        registry: bundle,
        diff: buildDiff(local, bundle)
    };
}

/**
 * Основная логика пакетного режима: читает missing из лога check_asutus и обрабатывает организации по одной
 * @returns {Promise<Object>} result для ou.logs
 */
async function processMissingAsutused(userId, rekvId, sourceLogParam, options, clientOverride) {
    options = options || {};
    const dryRun = options.dryRun !== false;
    const found = await findMissing(sourceLogParam);

    const summary = {
        error_code: 0,
        dry_run: dryRun,
        source_log_id: found.sourceLogId,
        total: found.missing.length,
        created: 0,
        would_create: 0,
        exists: 0,
        needs_manual: 0,
        not_found: 0,
        closed: 0,
        registry_unavailable: 0,
        error: 0,
        calls_spent: 0,
        remaining_year: null,
        items: [],
        error_message: null
    };

    if (!found.sourceLogId) {
        summary.error_message = 'check_asutus logi ei leitud';
        return summary;
    }
    if (found.missing.length === 0) {
        summary.error_message = 'Puuduvaid asutusi ei ole';
        return summary;
    }

    // maxCalls и insecureTls принимаются для обратной совместимости и игнорируются
    const client = clientOverride || ariregisterStore.createStoreClient();

    for (let i = 0; i < found.missing.length; i++) {
        const item = await processOne(found.missing[i], client, {dryRun: dryRun, userId: userId, rekvId: rekvId});
        summary.items.push(item);
        summary[item.status] = (summary[item.status] || 0) + 1;
    }

    const usage = client.getUsage();
    summary.calls_spent = usage.spent;
    summary.remaining_year = usage.remainingYear;
    summary.error_message = found.missing.length + ' asutust: ' + summary.items.map(function (it) {
        return it.regkood + '=' + it.status;
    }).join(', ');
    return summary;
}

async function createLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID, flow = FLOW_NAME) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp())))
                 returning id;`;
    try {
        return await db.queryDb(sql, [rekvId, userId, flow], null, null, null, null, config);
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

async function endLog(logId, status = 'success', errorMessage = null, resultData = null) {
    if (!logId) return;

    let resultJson = null;
    let responseText = null;
    if (resultData !== null && resultData !== undefined) {
        responseText = resultData.error_message || null;
        try {
            resultJson = JSON.stringify(resultData);
        } catch (e) {
            resultJson = JSON.stringify({raw: String(resultData)});
        }
    }

    const sql = `update ou.logs
                 set propertis = propertis || jsonb_build_object(
                     'exec_end', (clock_timestamp()),
                     'status', $1::text,
                     'error', $2::text
                 )
                 || case when $3::text is not null then jsonb_build_object('result', $3::jsonb) else '{}'::jsonb end
                 || case when $4::text is not null then jsonb_build_object('response', $4::text) else '{}'::jsonb end
                 where id = $5;`;
    try {
        await db.queryDb(sql, [status, errorMessage, resultJson, responseText, logId], null, null, null, null, config);
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

exports.DEFAULT_USER_ID = DEFAULT_USER_ID;
exports.DEFAULT_REKV_ID = DEFAULT_REKV_ID;
exports.CONFIG_REKV_ID = CONFIG_REKV_ID;
exports.FLOW_NAME = FLOW_NAME;
exports.LOOKUP_FLOW_NAME = LOOKUP_FLOW_NAME;
exports.STATUS = STATUS;
exports.UNAVAILABLE_REASONS = UNAVAILABLE_REASONS;
exports.parseDryRun = parseDryRun;
exports.findMissing = findMissing;
exports.getApiKey = getApiKey;
exports.resolveInforegisterToken = resolveInforegisterToken;
exports.makeCacheStore = makeCacheStore;
exports.createInforegisterClient = createInforegisterClient;
exports.asutusExists = asutusExists;
exports.readLocalAsutus = readLocalAsutus;
exports.buildAsutusPayload = buildAsutusPayload;
exports.saveAsutus = saveAsutus;
exports.isClosed = isClosed;
exports.mapReasonToStatus = mapReasonToStatus;
exports.buildDiff = buildDiff;
exports.processOne = processOne;
exports.lookupOne = lookupOne;
exports.processMissingAsutused = processMissingAsutused;
exports.createLog = createLog;
exports.endLog = endLog;
exports.config = config;
