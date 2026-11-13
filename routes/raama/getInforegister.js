'use strict';
const db = require('./../../libs/db');
const inforegister = require('./../../libs/inforegister');
const Doc = require('./../../classes/DocumentTemplate');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const CONFIG_REKV_ID = 3; // учреждение, в чьем ou.config хранится ключ Inforegister (переопределяется параметром config_rekv_id)
const FLOW_NAME = 'getInforegister';
const SOURCE_FLOW_NAME = 'checkAsutusAvailability'; // лог с result.missing (рег.коды отсутствующих организаций)
const SOURCE_LOG_WINDOW_HOURS = 24;

// статусы обработки организации
const STATUS = {
    CREATED: 'created',
    WOULD_CREATE: 'would_create', // dry_run: данные получены, запись в libs.asutus не выполнялась
    EXISTS: 'exists',
    NEEDS_MANUAL: 'needs_manual', // рег.код не из 8 цифр (физлицо, иностранная организация)
    NOT_FOUND: 'not_found',
    CLOSED: 'closed',
    UNAVAILABLE: 'registry_unavailable',
    ERROR: 'error'
};

/**
 * Express handler POST /task/getInforegister/
 * Берет из лога check_asutus (checkAsutusAvailability) рег.коды отсутствующих организаций, получает данные из
 * Inforegister и (если dry_run выключен) сохраняет организации через libs.sp_salvesta_asutus.
 * Работает асинхронно: создает лог, запускает обработку в фоне, сразу возвращает log_id.
 *
 * Параметры: user_id, rekv_id, log_id (необязательный: id лога check_asutus; по умолчанию последний за 24 часа),
 * dry_run (по умолчанию true: записи в справочник не создаются), max_calls (потолок платных вызовов за запуск).
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const userId = Number(params.user_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvId || DEFAULT_REKV_ID);
    const sourceLogParam = params.log_id || params.logId || null;
    const dryRun = parseDryRun(params.dry_run !== undefined ? params.dry_run : params.dryRun);
    const configRekvId = Number(params.config_rekv_id || params.configRekvId || CONFIG_REKV_ID);
    const insecureTls = params.insecure_tls === true || params.insecure_tls === 'true' || params.insecureTls === true;
    const maxCalls = params.max_calls !== undefined && !isNaN(Number(params.max_calls)) ? Number(params.max_calls) : undefined;

    let logId = null;

    try {
        const logResult = await createLog(rekvId, userId);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }
        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        runInBackground(logId, userId, rekvId, sourceLogParam, {dryRun: dryRun, maxCalls: maxCalls, configRekvId: configRekvId, insecureTls: insecureTls});

        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: FLOW_NAME,
                status: 'STARTED',
                log_id: logId,
                result: {doc_id: logId, error_code: 0, error_message: null, tulemused: 'STARTED'}
            },
            error_message: null
        });
    } catch (error) {
        console.error('Error starting getInforegister task:', error);
        if (logId) {
            try {
                await endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('Failed to update log on startup error:', logErr);
            }
        }
        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: `Start getInforegister failed: ${error.message}`
        });
    }
};

/** dry_run включен по умолчанию; выключается только явным false / 'false' / 0 / '0' */
function parseDryRun(value) {
    if (value === false || value === 0 || value === '0') return false;
    if (typeof value === 'string' && value.trim().toLowerCase() === 'false') return false;
    return true;
}

async function runInBackground(logId, userId, rekvId, sourceLogParam, options) {
    try {
        const result = await processMissingAsutused(userId, rekvId, sourceLogParam, options);
        await endLog(logId, 'success', null, result);
    } catch (error) {
        console.error(`[getInforegister] Background task failed. log_id: ${logId}`, error);
        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[getInforegister] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
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
 * userId нужен модели config (u.id = $2), к учреждению configRekvId он может не относиться.
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

/** Постоянный кэш в libs.registry_cache; при отсутствии таблицы клиент работает без кэша */
function makeCacheStore() {
    return {
        get: async function (key) {
            const r = await db.queryDb(
                `select payload, negative from libs.registry_cache where cache_key = $1 and expires_at > now()`,
                [key], null, null, null, null, config);
            const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
            return row ? {payload: row.payload, negative: !!row.negative} : null;
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

async function asutusExists(regkood) {
    const r = await db.queryDb(
        `select id from libs.asutus where ltrim(rtrim(regkood)) = $1 and staatus < 3 limit 1`,
        [regkood], null, null, null, null, config);
    return r && Array.isArray(r.data) && r.data[0] ? Number(r.data[0].id) : null;
}

/**
 * Формирует JSON для libs.sp_salvesta_asutus из данных реестра.
 * omvorm в libs.asutus char(20) NOT NULL, поэтому передаем пустую строку, название уже содержит форму (OÜ, AS).
 */
function buildAsutusPayload(regkood, bundle) {
    const contacts = bundle.contacts || {emails: [], phones: []};
    return {
        id: 0,
        data: {
            id: 0,
            regkood: regkood,
            nimetus: bundle.name,
            omvorm: '',
            aadress: bundle.address && bundle.address.fullAddress ? bundle.address.fullAddress : '',
            kontakt: '',
            tel: contacts.phones && contacts.phones.length ? contacts.phones[0] : '',
            email: contacts.emails && contacts.emails.length ? contacts.emails[0] : '',
            kmkr: bundle.vatNumber || '',
            mark: 'Inforegister (automaatselt lisatud)',
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

const UNAVAILABLE_REASONS = ['no_api_key', 'unauthorized', 'rate_limited', 'budget_exhausted', 'year_limit_reserve', 'timeout', 'http_error', 'dry_run_no_spend'];

/**
 * Обрабатывает одну организацию. Не бросает исключение: ошибка фиксируется в статусе.
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
            if (res.reason === 'invalid_reg_code') item.status = STATUS.NEEDS_MANUAL;
            else if (res.reason === 'not_found') item.status = STATUS.NOT_FOUND;
            else if (UNAVAILABLE_REASONS.indexOf(res.reason) !== -1) item.status = STATUS.UNAVAILABLE;
            else item.status = STATUS.ERROR;
            item.error = res.reason + ': ' + res.message;
            return item;
        }

        const bundle = res.data;
        item.source = res.source;
        item.nimetus = bundle.name;

        if (!bundle.name) {
            item.status = STATUS.NOT_FOUND;
            item.error = 'Inforegister ei tagastanud nimetust';
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
 * Основная логика: читает missing из лога check_asutus и обрабатывает организации по одной
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

    const client = clientOverride || inforegister.createClient({
        apiKey: await getApiKey(userId, options.configRekvId || CONFIG_REKV_ID),
        store: makeCacheStore(),
        maxCalls: options.maxCalls,
        insecureTls: options.insecureTls === true
    });

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

async function createLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp())))
                 returning id;`;
    try {
        return await db.queryDb(sql, [rekvId, userId, FLOW_NAME], null, null, null, null, config);
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

exports.processMissingAsutused = processMissingAsutused;
exports.processOne = processOne;
exports.buildAsutusPayload = buildAsutusPayload;
exports.findMissing = findMissing;
exports.getApiKey = getApiKey;
exports.parseDryRun = parseDryRun;
exports.isClosed = isClosed;
exports.runInBackground = runInBackground;
exports.createLog = createLog;
exports.endLog = endLog;
exports.FLOW_NAME = FLOW_NAME;
exports.STATUS = STATUS;
