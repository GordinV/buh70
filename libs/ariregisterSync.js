'use strict';
/**
 * Потоковая синхронизация открытых данных Äriregister (RIK) в локальную таблицу libs.ariregister.
 * Код совместим с Node < 14 (без ?? и ?.).
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const https = require('https');
const {URL} = require('url');
const yauzl = require('yauzl');
const parse = require('csv-parse');
const {Client} = require('pg');
const db = require('./db');
const config = require('./inforegisterConfig');

const DEFAULT_URL = 'https://avaandmed.ariregister.rik.ee/sites/default/files/avaandmed/ettevotja_rekvisiidid__lihtandmed.csv.zip';
const FLOW_NAME = 'ariregisterSync';
const CONFIG_REKV_ID = 3;
const REG_CODE_RE = /^\d{8}$/;
const MIN_ZIP_BYTES = 1024 * 1024;
const MIN_ROWS_FLOOR = 300000;
const BATCH_SIZE = 1000;
const DOWNLOAD_TIMEOUT_MS = 120000;
const MAX_REDIRECTS = 5;
const ADVISORY_LOCK_KEY = 707001;
// Cloudflare перед avaandmed.ariregister.rik.ee возвращает 403 клиентам Node 10/11 при дефолтном наборе ECDH-кривых
const TLS_ECDH_CURVES = 'X25519:prime256v1:secp384r1';

function defaultQueryFn(sqlString, params) {
    return db.queryDb(sqlString, params, null, null, null, null, config);
}

function attachErrorHandler(client) {
    if (client && typeof client.on === 'function') {
        client.on('error', function (e) {
            console.error('[ariregisterSync] pg client error:', e && e.message);
        });
    }
    return client;
}

/**
 * Создаёт pg.Client с тем же config (config/narvalv.json; ssl в narvalv.json не задан).
 * При наличии config.pg.ssl повторяет логику libs/db.js.
 */
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

function trimOrNull(val) {
    if (val === null || val === undefined) return null;
    const s = String(val).trim();
    return s === '' ? null : s;
}

function parseEsmakanneDate(val) {
    const s = trimOrNull(val);
    if (!s) return null;
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
    const m = /^(\d{2})\.(\d{2})\.(\d{4})$/.exec(s);
    if (m) return m[3] + '-' + m[2] + '-' + m[1];
    return null;
}

function parseLastModifiedDate(headerVal) {
    if (headerVal) {
        const d = new Date(headerVal);
        if (!isNaN(d.getTime())) {
            return d.toISOString().slice(0, 10);
        }
    }
    return new Date().toISOString().slice(0, 10);
}

function parseCsvRow(row) {
    if (!row || typeof row !== 'object') return null;
    const regkood = trimOrNull(row.ariregistri_kood);
    const nimi = trimOrNull(row.nimi);
    if (!regkood || !REG_CODE_RE.test(regkood) || !nimi) {
        return null;
    }

    return {
        regkood: regkood,
        nimi: nimi,
        oiguslik_vorm: trimOrNull(row.ettevotja_oiguslik_vorm),
        oigusliku_vormi_alaliik: trimOrNull(row.ettevotja_oigusliku_vormi_alaliik),
        kmkr_nr: trimOrNull(row.kmkr_nr),
        staatus: trimOrNull(row.ettevotja_staatus),
        staatus_tekst: trimOrNull(row.ettevotja_staatus_tekstina),
        esmakande_kpv: parseEsmakanneDate(row.ettevotja_esmakande_kpv),
        aadress: trimOrNull(row.ettevotja_aadress),
        asukoht: trimOrNull(row.asukoht_ettevotja_aadressis),
        ehak_kood: trimOrNull(row.asukoha_ehak_kood),
        ehak_tekst: trimOrNull(row.asukoha_ehak_tekstina),
        indeks: trimOrNull(row.indeks_ettevotja_aadressis),
        ads_adr_id: trimOrNull(row.ads_adr_id),
        ads_ads_oid: trimOrNull(row.ads_ads_oid),
        taisaadress: trimOrNull(row.ads_normaliseeritud_taisaadress),
        link: trimOrNull(row.teabesysteemi_link),
        file_date: null
    };
}

function computeMinRows(currentCount, minRowsFloor) {
    const floor = minRowsFloor !== undefined ? minRowsFloor : MIN_ROWS_FLOOR;
    const active = Number(currentCount) || 0;
    return Math.max(floor, Math.floor(active * 0.9));
}

async function getAriregisterUrl(configRekvId, queryFn) {
    const q = queryFn || defaultQueryFn;
    const rekvId = configRekvId || CONFIG_REKV_ID;
    try {
        const res = await q(
            "select properties ->> 'ARIREGISTER_URL' as url from ou.config where rekvid = $1 limit 1",
            [rekvId]
        );
        const url = res && res.data && res.data[0] ? trimOrNull(res.data[0].url) : null;
        return url || DEFAULT_URL;
    } catch (err) {
        console.error('[ariregisterSync] Failed to read ARIREGISTER_URL from ou.config:', err.message);
        return DEFAULT_URL;
    }
}

function downloadZip(url, destPath, options) {
    const opts = options || {};
    const timeoutMs = opts.timeoutMs || DOWNLOAD_TIMEOUT_MS;
    const minZipBytes = opts.minZipBytes !== undefined ? opts.minZipBytes : MIN_ZIP_BYTES;
    const maxRedirects = opts.maxRedirects !== undefined ? opts.maxRedirects : MAX_REDIRECTS;

    function requestOnce(currentUrl, redirectsLeft) {
        return new Promise(function (resolve, reject) {
            let parsedUrl;
            try {
                parsedUrl = new URL(currentUrl);
            } catch (err) {
                return reject(new Error('Invalid URL: ' + currentUrl));
            }

            const transport = parsedUrl.protocol === 'http:' ? http : https;
            let settled = false;
            let fileStream = null;

            function fail(err) {
                if (settled) return;
                settled = true;
                if (fileStream) {
                    try {
                        fileStream.destroy();
                    } catch (e) {
                        // ignore
                    }
                }
                reject(err);
            }

            const reqOptions = {
                timeout: timeoutMs,
                headers: {
                    'User-Agent': 'buh70-ariregister-sync/1.0',
                    'Accept': '*/*'
                }
            };
            if (parsedUrl.protocol === 'https:') {
                reqOptions.ecdhCurve = TLS_ECDH_CURVES;
            }

            const req = transport.get(parsedUrl, reqOptions, function (res) {
                const status = res.statusCode || 0;

                if ([301, 302, 303, 307, 308].indexOf(status) !== -1 && res.headers && res.headers.location) {
                    res.resume();
                    if (redirectsLeft <= 0) {
                        return fail(new Error('Too many redirects downloading Äriregister ZIP'));
                    }
                    const nextUrl = new URL(res.headers.location, currentUrl).toString();
                    settled = true;
                    return requestOnce(nextUrl, redirectsLeft - 1).then(resolve, reject);
                }

                if (status !== 200) {
                    res.resume();
                    return fail(new Error('HTTP ' + status + ' downloading Äriregister ZIP'));
                }

                const fileDate = parseLastModifiedDate(res.headers ? res.headers['last-modified'] : null);
                fileStream = fs.createWriteStream(destPath);

                fileStream.on('error', function (err) {
                    res.destroy();
                    fail(err);
                });

                res.on('error', fail);

                fileStream.on('finish', function () {
                    fileStream.close(function () {
                        if (settled) return;
                        try {
                            const stat = fs.statSync(destPath);
                            if (stat.size < minZipBytes) {
                                return fail(new Error('Downloaded ZIP too small: ' + stat.size + ' bytes (min ' + minZipBytes + ')'));
                            }
                            settled = true;
                            resolve({filePath: destPath, size: stat.size, fileDate: fileDate});
                        } catch (err) {
                            fail(err);
                        }
                    });
                });

                res.pipe(fileStream);
            });

            req.on('timeout', function () {
                req.destroy(new Error('Timeout downloading Äriregister ZIP'));
            });

            req.on('error', fail);
        });
    }

    return requestOnce(url, maxRedirects);
}

function openCsvStreamFromZip(zipPath) {
    return new Promise(function (resolve, reject) {
        yauzl.open(zipPath, {lazyEntries: true}, function (err, zipfile) {
            if (err) return reject(err);

            let opened = false;

            zipfile.on('error', function (zErr) {
                if (!opened) reject(zErr);
            });

            zipfile.on('entry', function (entry) {
                if (/\/$/.test(entry.fileName)) {
                    zipfile.readEntry();
                    return;
                }
                if (!/\.csv$/i.test(entry.fileName)) {
                    zipfile.readEntry();
                    return;
                }
                opened = true;
                zipfile.openReadStream(entry, function (sErr, readStream) {
                    if (sErr) {
                        try {
                            zipfile.close();
                        } catch (e) {
                            // ignore
                        }
                        return reject(sErr);
                    }
                    resolve({stream: readStream, zipfile: zipfile, fileName: entry.fileName});
                });
            });

            zipfile.on('end', function () {
                if (!opened) {
                    try {
                        zipfile.close();
                    } catch (e) {
                        // ignore
                    }
                    reject(new Error('No CSV entry found in Äriregister ZIP'));
                }
            });

            zipfile.readEntry();
        });
    });
}

function buildStageInsertSqlAndValues(rows) {
    const colsPerRow = 18;
    const placeholders = [];
    const values = [];

    for (let i = 0; i < rows.length; i++) {
        const r = rows[i];
        const base = i * colsPerRow;
        placeholders.push(
            '($' + (base + 1) + ',$' + (base + 2) + ',$' + (base + 3) + ',$' + (base + 4) +
            ',$' + (base + 5) + ',$' + (base + 6) + ',$' + (base + 7) + ',$' + (base + 8) +
            ',$' + (base + 9) + ',$' + (base + 10) + ',$' + (base + 11) + ',$' + (base + 12) +
            ',$' + (base + 13) + ',$' + (base + 14) + ',$' + (base + 15) + ',$' + (base + 16) +
            ',$' + (base + 17) + ',$' + (base + 18) + ')'
        );
        values.push(
            r.regkood,
            r.nimi,
            r.oiguslik_vorm,
            r.oigusliku_vormi_alaliik,
            r.kmkr_nr,
            r.staatus,
            r.staatus_tekst,
            r.esmakande_kpv,
            r.aadress,
            r.asukoht,
            r.ehak_kood,
            r.ehak_tekst,
            r.indeks,
            r.ads_adr_id,
            r.ads_ads_oid,
            r.taisaadress,
            r.link,
            r.file_date
        );
    }

    const sql =
        'INSERT INTO libs.ariregister_stage (' +
        'regkood, nimi, oiguslik_vorm, oigusliku_vormi_alaliik, kmkr_nr, ' +
        'staatus, staatus_tekst, esmakande_kpv, aadress, asukoht, ' +
        'ehak_kood, ehak_tekst, indeks, ads_adr_id, ads_ads_oid, ' +
        'taisaadress, link, file_date' +
        ') VALUES ' + placeholders.join(',');

    return {sql: sql, values: values};
}

async function insertStageBatch(rows, insertFn, batchNumber) {
    if (!rows || !rows.length) return;
    const built = buildStageInsertSqlAndValues(rows);
    const batchLabel = batchNumber || 1;
    try {
        const res = await insertFn(built.sql, built.values);
        if (res && res.error_code) {
            throw new Error(res.error_message || 'error_code ' + res.error_code);
        }
    } catch (err) {
        throw new Error('Stage insert failed at batch ' + batchLabel + ': ' + err.message);
    }
}

function processCsvStream(csvStream, options) {
    const batchSize = options.batchSize || BATCH_SIZE;
    const dryRun = Boolean(options.dryRun);
    const fileDate = options.fileDate;
    const insertFn = options.insertFn;

    return new Promise(function (resolve, reject) {
        let rowsRead = 0;
        let skipped = 0;
        let batch = [];
        let batchNum = 0;
        let settled = false;
        let flushing = false;
        let ended = false;

        const parser = parse({
            delimiter: ';',
            bom: true,
            columns: true,
            relax_column_count: true
        });

        function fail(err) {
            if (settled) return;
            settled = true;
            try {
                csvStream.unpipe(parser);
            } catch (e) {
                // ignore
            }
            try {
                parser.destroy();
            } catch (e) {
                // ignore
            }
            reject(err);
        }

        async function flushBatch() {
            if (!batch.length || dryRun) {
                batch = [];
                return;
            }
            const toInsert = batch;
            batch = [];
            batchNum += 1;
            await insertStageBatch(toInsert, insertFn, batchNum);
        }

        async function finishIfDone() {
            if (settled || !ended || flushing) return;
            flushing = true;
            try {
                await flushBatch();
                settled = true;
                resolve({rowsRead: rowsRead, skipped: skipped});
            } catch (err) {
                fail(err);
            }
        }

        parser.on('data', function (record) {
            rowsRead += 1;
            const parsed = parseCsvRow(record);
            if (!parsed) {
                skipped += 1;
                return;
            }
            parsed.file_date = fileDate;
            batch.push(parsed);

            if (batch.length >= batchSize && !flushing) {
                if (dryRun) {
                    batch = [];
                    return;
                }
                flushing = true;
                parser.pause();
                flushBatch()
                    .then(function () {
                        flushing = false;
                        parser.resume();
                        if (ended) {
                            finishIfDone();
                        }
                    })
                    .catch(fail);
            }
        });

        parser.on('end', function () {
            ended = true;
            finishIfDone();
        });

        parser.on('error', fail);
        csvStream.on('error', fail);

        csvStream.pipe(parser);
    });
}

async function syncAriregister(options) {
    const opts = options || {};
    const startedAt = Date.now();
    const dryRun = Boolean(opts.dryRun);
    const queryFn = opts.queryFn || defaultQueryFn;
    const createClientFn = opts.createClient || createPgClient;
    const downloadFn = opts.downloadFn || downloadZip;
    const openCsvFn = opts.openCsvStreamFn || openCsvStreamFromZip;
    const batchSize = opts.batchSize || BATCH_SIZE;

    const url = opts.url || await getAriregisterUrl(opts.configRekvId, queryFn);
    const tmpZipPath = path.join(
        os.tmpdir(),
        'ariregister_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8) + '.zip'
    );

    let zipfile = null;
    let stageClient = null;

    try {
        const dl = await downloadFn(url, tmpZipPath, {
            timeoutMs: opts.timeoutMs,
            minZipBytes: opts.minZipBytes
        });
        const fileDate = (dl && dl.fileDate) || new Date().toISOString().slice(0, 10);
        const zipFilePath = (dl && dl.filePath) || tmpZipPath;

        let insertFn = queryFn;
        if (!dryRun && !opts.queryFn) {
            stageClient = attachErrorHandler(createClientFn());
            await stageClient.connect();
            insertFn = function (sql, params) {
                return stageClient.query(sql, params);
            };
        }

        if (!dryRun) {
            const delRes = await queryFn('DELETE FROM libs.ariregister_stage', []);
            if (delRes && delRes.error_code) {
                throw new Error(delRes.error_message || 'Failed to clear libs.ariregister_stage');
            }
        }

        const opened = await openCsvFn(zipFilePath);
        zipfile = opened.zipfile || null;

        const stats = await processCsvStream(opened.stream, {
            batchSize: batchSize,
            dryRun: dryRun,
            fileDate: fileDate,
            insertFn: insertFn
        });

        if (stageClient) {
            await stageClient.end();
            stageClient = null;
        }

        let applied = {inserted: 0, updated: 0, deleted: 0, total: 0, file_date: fileDate};

        if (!dryRun) {
            const cntRes = await queryFn(
                'SELECT count(*)::int AS cnt FROM libs.ariregister WHERE deleted_at IS NULL',
                []
            );
            if (cntRes && cntRes.error_code) {
                throw new Error(cntRes.error_message || 'Failed to read current libs.ariregister count');
            }
            const currentCount = cntRes && cntRes.data && cntRes.data[0] ? Number(cntRes.data[0].cnt) : 0;
            const minRows = computeMinRows(currentCount, opts.minRowsFloor);

            const applyRes = await queryFn(
                'SELECT libs.sp_ariregister_apply($1::date, $2::integer) AS result',
                [fileDate, minRows]
            );
            if (applyRes && applyRes.error_code) {
                throw new Error(applyRes.error_message || 'libs.sp_ariregister_apply failed');
            }
            const rawResult = applyRes && applyRes.data && applyRes.data[0] ? applyRes.data[0].result : null;
            if (rawResult) {
                applied = typeof rawResult === 'string' ? JSON.parse(rawResult) : rawResult;
            }
        }

        return {
            file_date: applied.file_date || fileDate,
            rows_read: stats.rowsRead,
            skipped: stats.skipped,
            inserted: Number(applied.inserted) || 0,
            updated: Number(applied.updated) || 0,
            deleted: Number(applied.deleted) || 0,
            total: Number(applied.total) || 0,
            dry_run: dryRun,
            duration_ms: Date.now() - startedAt
        };
    } finally {
        if (stageClient) {
            try {
                await stageClient.end();
            } catch (e) {
                // ignore
            }
        }
        if (zipfile && typeof zipfile.close === 'function') {
            try {
                zipfile.close();
            } catch (e) {
                // ignore
            }
        }
        try {
            if (fs.existsSync(tmpZipPath)) {
                fs.unlinkSync(tmpZipPath);
            }
        } catch (e) {
            // ignore
        }
    }
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

exports.DEFAULT_URL = DEFAULT_URL;
exports.FLOW_NAME = FLOW_NAME;
exports.CONFIG_REKV_ID = CONFIG_REKV_ID;
exports.REG_CODE_RE = REG_CODE_RE;
exports.MIN_ZIP_BYTES = MIN_ZIP_BYTES;
exports.MIN_ROWS_FLOOR = MIN_ROWS_FLOOR;
exports.BATCH_SIZE = BATCH_SIZE;
exports.ADVISORY_LOCK_KEY = ADVISORY_LOCK_KEY;
exports.TLS_ECDH_CURVES = TLS_ECDH_CURVES;
exports.config = config;
exports.createPgClient = createPgClient;
exports.parseEsmakanneDate = parseEsmakanneDate;
exports.parseLastModifiedDate = parseLastModifiedDate;
exports.parseCsvRow = parseCsvRow;
exports.computeMinRows = computeMinRows;
exports.getAriregisterUrl = getAriregisterUrl;
exports.downloadZip = downloadZip;
exports.openCsvStreamFromZip = openCsvStreamFromZip;
exports.insertStageBatch = insertStageBatch;
exports.processCsvStream = processCsvStream;
exports.syncAriregister = syncAriregister;
exports.tryAcquireLock = tryAcquireLock;
exports.releaseLock = releaseLock;
