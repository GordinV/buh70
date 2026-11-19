'use strict';
/**
 * Сервис автоматического закрытия карточек ликвидированных/удалённых контрагентов (libs.asutus.properties.kehtivus)
 * на основе локальной копии Äriregister (libs.ariregister / libs.ariregister_meta).
 * Код совместим с Node < 14 (без ?? и ?.).
 */
const fs = require('fs');
const path = require('path');
const {Client} = require('pg');
const db = require('./db');
const config = require('./inforegisterConfig');
const inforegisterService = require('./inforegisterService');

const FLOW_NAME = 'checkAsutusKehtivus';
const DEFAULT_USER_ID = 11770;
const DEFAULT_MAX_CLOSE = 100;
const MIN_REGISTRY_ROWS = 300000;
const ADVISORY_LOCK_KEY = 707002;
const TIMEZONE = 'Europe/Tallinn';

function defaultQueryFn(sqlString, params) {
    return db.queryDb(sqlString, params, null, null, null, null, config);
}

function attachErrorHandler(client) {
    if (client && typeof client.on === 'function') {
        client.on('error', function (e) {
            console.error('[asutusKehtivus] pg client error:', e && e.message);
        });
    }
    return client;
}

function createPgClient() {
    let client;
    if (config && config.pg && config.pg.ssl) {
        const cfgDir = path.join(__dirname, '..', 'config');
        const caPath = path.join(cfgDir, 'client.crt');
        const keyPath = path.join(cfgDir, 'server.key');
        const certPath = path.join(cfgDir, 'client.crt');
        client = new Client({
            user: config.pg.user,
            password: config.pg.password,
            database: config.pg.database,
            port: config.pg.port,
            host: config.pg.host,
            ssl: {
                rejectUnauthorized: false,
                require: true,
                ca: fs.readFileSync(caPath).toString(),
                key: fs.readFileSync(keyPath).toString(),
                cert: fs.readFileSync(certPath).toString()
            }
        });
    } else {
        client = new Client(config.pg.connection);
    }
    return attachErrorHandler(client);
}

function toTallinnDateStr(val) {
    const d = val ? (val instanceof Date ? val : new Date(val)) : new Date();
    if (isNaN(d.getTime())) return null;
    try {
        return new Intl.DateTimeFormat('en-CA', {
            timeZone: TIMEZONE,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(d);
    } catch (e) {
        return d.toISOString().slice(0, 10);
    }
}

function formatDateOnly(val) {
    if (!val) return null;
    if (val instanceof Date) {
        return isNaN(val.getTime()) ? null : toTallinnDateStr(val);
    }
    const s = String(val).trim();
    if (!s) return null;
    if (/^\d{4}-\d{2}-\d{2}/.test(s)) return s.slice(0, 10);
    const d = new Date(s);
    return isNaN(d.getTime()) ? s : toTallinnDateStr(d);
}

async function readRegistryMeta(queryFn) {
    const q = queryFn || defaultQueryFn;
    const res = await q(
        'SELECT file_date::text AS file_date, applied_at, rows_total ' +
        'FROM libs.ariregister_meta WHERE id = 1 LIMIT 1',
        []
    );
    if (res && res.error_code) {
        throw new Error(res.error_message || 'Failed to read libs.ariregister_meta');
    }
    return res && res.data && res.data[0] ? res.data[0] : null;
}

function isRegistryFresh(meta, nowDate) {
    if (!meta) return false;
    const rowsTotal = Number(meta.rows_total) || 0;
    if (rowsTotal < MIN_REGISTRY_ROWS) return false;
    const appliedDate = toTallinnDateStr(meta.applied_at);
    const todayDate = toTallinnDateStr(nowDate || new Date());
    return Boolean(appliedDate && todayDate && appliedDate === todayDate);
}

async function findClosedCandidates(queryFn, todayStr) {
    const q = queryFn || defaultQueryFn;
    const effectiveToday = todayStr || toTallinnDateStr(new Date());

    const sql =
        "SELECT " +
        "a.id AS asutus_id, " +
        "ltrim(rtrim(a.regkood)) AS regkood, " +
        "ltrim(rtrim(a.nimetus)) AS nimetus, " +
        "a.aadress, " +
        "ltrim(rtrim(coalesce(a.properties ->> 'kehtivus', ''))) AS old_kehtivus, " +
        "(r.regkood IS NOT NULL) AS in_registry, " +
        "r.deleted_at::date::text AS deleted_date " +
        "FROM libs.asutus a " +
        "LEFT JOIN libs.ariregister r " +
        "ON r.regkood = ltrim(rtrim(a.regkood)) " +
        "WHERE a.staatus < 3 " +
        "AND ltrim(rtrim(a.regkood)) ~ '^[0-9]{8}$' " +
        "AND (" +
        "coalesce(ltrim(rtrim(a.properties ->> 'kehtivus')), '') !~ '^\\d{4}-\\d{2}-\\d{2}' " +
        "OR substring(ltrim(rtrim(a.properties ->> 'kehtivus')) FROM 1 FOR 10)::date > current_date" +
        ") " +
        "AND (" +
        "r.deleted_at IS NOT NULL " +
        "OR (r.regkood IS NULL AND ltrim(rtrim(a.regkood)) ~ '^[189]')" +
        ") " +
        "ORDER BY a.id ASC";

    const res = await q(sql, []);
    if (res && res.error_code) {
        throw new Error(res.error_message || 'Failed to query closed candidates');
    }

    const rows = Array.isArray(res && res.data) ? res.data : [];
    const candidates = [];

    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const oldKehtivus = row.old_kehtivus && String(row.old_kehtivus).trim() !== ''
            ? String(row.old_kehtivus).trim()
            : null;

        if (row.in_registry) {
            const delDate = formatDateOnly(row.deleted_date) || effectiveToday;
            candidates.push({
                asutus_id: Number(row.asutus_id),
                regkood: String(row.regkood).trim(),
                nimetus: row.nimetus ? String(row.nimetus).trim() : '',
                aadress: row.aadress || null,
                reason: 'deleted_from_registry',
                kehtivus: delDate,
                old_kehtivus: oldKehtivus
            });
        } else if (inforegisterService.matchesNotInRegistryRule(row.regkood, row.aadress)) {
            candidates.push({
                asutus_id: Number(row.asutus_id),
                regkood: String(row.regkood).trim(),
                nimetus: row.nimetus ? String(row.nimetus).trim() : '',
                aadress: row.aadress || null,
                reason: 'not_in_registry',
                kehtivus: effectiveToday,
                old_kehtivus: oldKehtivus
            });
        }
    }

    return candidates;
}

async function runKehtivusCheck(options) {
    const opts = options || {};
    const dryRun = opts.dryRun !== false;
    const maxClose = opts.maxClose !== undefined && opts.maxClose !== null
        ? Number(opts.maxClose)
        : DEFAULT_MAX_CLOSE;
    const userId = opts.userId || DEFAULT_USER_ID;
    const queryFn = opts.queryFn || defaultQueryFn;
    const nowDate = opts.now ? new Date(opts.now) : new Date();
    const todayStr = toTallinnDateStr(nowDate);

    const meta = await readRegistryMeta(queryFn);
    const fileDate = meta ? formatDateOnly(meta.file_date) : null;

    if (!isRegistryFresh(meta, nowDate)) {
        return {
            status: 'skipped',
            reason: 'registry_stale',
            retryable: true,
            dry_run: dryRun,
            registry_file_date: fileDate,
            candidates_total: 0,
            closed: [],
            would_close: [],
            skipped_already: [],
            errors: [],
            totalClosed: 0,
            totalErrors: 0,
            error_message: 'Äriregistri koopia on aegunud või laadimata'
        };
    }

    const candidates = await findClosedCandidates(queryFn, todayStr);

    if (!dryRun && candidates.length > maxClose) {
        return {
            status: 'failed',
            reason: 'too_many_candidates',
            retryable: false,
            dry_run: false,
            registry_file_date: fileDate,
            candidates_total: candidates.length,
            closed: [],
            would_close: candidates,
            skipped_already: [],
            errors: [],
            totalClosed: 0,
            totalErrors: 0,
            error_message: 'Liiga palju kandidaate (' + candidates.length + ' > ' + maxClose + ')'
        };
    }

    if (dryRun) {
        return {
            status: 'success',
            reason: null,
            dry_run: true,
            registry_file_date: fileDate,
            candidates_total: candidates.length,
            closed: [],
            would_close: candidates,
            skipped_already: [],
            errors: [],
            totalClosed: 0,
            totalErrors: 0,
            error_message: null
        };
    }

    const closed = [];
    const skippedAlready = [];
    const errors = [];

    for (let i = 0; i < candidates.length; i++) {
        const c = candidates[i];
        try {
            const callRes = await queryFn(
                'SELECT libs.set_asutuse_kehtivus($1::integer, $2::integer, $3::date) AS res',
                [c.asutus_id, userId, c.kehtivus]
            );
            if (callRes && callRes.error_code) {
                throw new Error(callRes.error_message || ('error_code ' + callRes.error_code));
            }
            const raw = callRes && callRes.data && callRes.data[0] ? callRes.data[0].res : [];
            const arr = typeof raw === 'string' ? JSON.parse(raw) : (Array.isArray(raw) ? raw : []);
            if (arr.length === 0) {
                skippedAlready.push({
                    asutus_id: c.asutus_id,
                    regkood: c.regkood,
                    nimetus: c.nimetus,
                    aadress: c.aadress || null,
                    reason: c.reason,
                    old_kehtivus: c.old_kehtivus
                });
            } else {
                for (let j = 0; j < arr.length; j++) {
                    const rowRes = arr[j] || {};
                    closed.push({
                        asutus_id: rowRes.asutus_id !== undefined ? Number(rowRes.asutus_id) : c.asutus_id,
                        regkood: rowRes.regkood ? String(rowRes.regkood).trim() : c.regkood,
                        nimetus: rowRes.nimetus ? String(rowRes.nimetus).trim() : c.nimetus,
                        aadress: c.aadress || null,
                        reason: c.reason,
                        staatus: rowRes.staatus || null,
                        kehtivus: rowRes.kehtivus || c.kehtivus,
                        old_kehtivus: rowRes.old_kehtivus !== undefined ? rowRes.old_kehtivus : c.old_kehtivus
                    });
                }
            }
        } catch (err) {
            const msg = err && err.message ? err.message : String(err);
            if (msg.indexOf('pole õigused') !== -1) {
                errors.push({asutus_id: c.asutus_id, regkood: c.regkood, error: msg});
                return {
                    status: 'failed',
                    reason: 'no_rights',
                    retryable: false,
                    dry_run: false,
                    registry_file_date: fileDate,
                    candidates_total: candidates.length,
                    closed: closed,
                    would_close: [],
                    skipped_already: skippedAlready,
                    errors: errors,
                    totalClosed: closed.length,
                    totalErrors: errors.length,
                    error_message: msg
                };
            }
            errors.push({asutus_id: c.asutus_id, regkood: c.regkood, error: msg});
        }
    }

    return {
        status: 'success',
        reason: null,
        dry_run: false,
        registry_file_date: fileDate,
        candidates_total: candidates.length,
        closed: closed,
        would_close: [],
        skipped_already: skippedAlready,
        errors: errors,
        totalClosed: closed.length,
        totalErrors: errors.length,
        error_message: null
    };
}

async function tryAcquireLock(createClientFn) {
    const makeClient = createClientFn || createPgClient;
    const client = attachErrorHandler(makeClient());
    try {
        await client.connect();
        const res = await client.query('SELECT pg_try_advisory_lock($1) AS locked', [ADVISORY_LOCK_KEY]);
        const locked = res && res.rows && res.rows[0] ? Boolean(res.rows[0].locked) : false;
        if (!locked) {
            await client.end();
            return null;
        }
        return {client: client};
    } catch (err) {
        try {
            await client.end();
        } catch (e) {
            // ignore
        }
        throw err;
    }
}

async function releaseLock(handle) {
    if (!handle || !handle.client) return;
    try {
        await handle.client.query('SELECT pg_advisory_unlock($1)', [ADVISORY_LOCK_KEY]);
    } catch (e) {
        // ignore
    } finally {
        try {
            await handle.client.end();
        } catch (e) {
            // ignore
        }
    }
}

exports.FLOW_NAME = FLOW_NAME;
exports.DEFAULT_USER_ID = DEFAULT_USER_ID;
exports.DEFAULT_MAX_CLOSE = DEFAULT_MAX_CLOSE;
exports.MIN_REGISTRY_ROWS = MIN_REGISTRY_ROWS;
exports.ADVISORY_LOCK_KEY = ADVISORY_LOCK_KEY;
exports.config = config;
exports.createPgClient = createPgClient;
exports.toTallinnDateStr = toTallinnDateStr;
exports.readRegistryMeta = readRegistryMeta;
exports.isRegistryFresh = isRegistryFresh;
exports.findClosedCandidates = findClosedCandidates;
exports.runKehtivusCheck = runKehtivusCheck;
exports.tryAcquireLock = tryAcquireLock;
exports.releaseLock = releaseLock;
