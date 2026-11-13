'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');
const earved = require('./getEarvedFromFinBit');
const checkAsutus = require('./checkAsutusAvailability');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
// flow сохраняется прежним: docs.get_arve_kinnitaja (отчет sendFinBitReport) ищет лог импорта именно по нему
const FLOW_NAME = earved.FLOW_NAME; // 'docs.sp_loe_earved'

/**
 * Express handler для роута POST /task/importEarved/
 * Разбор и сохранение счетов, ранее выкачанных агентом getEarved (лог flow = getEarved).
 * Частичный импорт: счета, контр-агентов которых нет в libs.asutus (список в changes лога getEarved,
 * его заполняет агент check_asutus), пропускаются и попадают в result.skipped; остальные импортируются.
 * Работает асинхронно: создает лог docs.sp_loe_earved, запускает импорт в фоне, сразу возвращает log_id.
 *
 * Параметры: user_id, rekv_id, log_id (необязательный: id лога getEarved; если не указан - последний за 24 часа).
 *
 * Пример: curl.exe -X POST http://localhost:3000/task/importEarved/ -H "Content-Type: application/json" -d "{\"user_id\":11770,\"rekv_id\":63,\"log_id\":8546659}"
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);
    const sourceLogParam = params.log_id || params.logId || null;

    let logId = null;

    try {
        // 1. Создаем запись в ou.logs о старте процесса (flow = docs.sp_loe_earved)
        const logResult = await earved.createLog(rekvId, userId, FLOW_NAME);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }

        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        // 2. Фоновый импорт БЕЗ ожидания завершения
        runImportInBackground(logId, userId, sourceLogParam);

        // 3. Сразу возвращаем log_id для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'importEarved',
                status: 'STARTED',
                log_id: logId,
                result: {
                    doc_id: logId,
                    error_code: 0,
                    error_message: null,
                    tulemused: 'STARTED'
                }
            },
            error_message: null
        });
    } catch (error) {
        console.error('Error starting importEarved task:', error);

        if (logId) {
            try {
                await earved.endLog(logId, 'failed', error.message);
            } catch (logErr) {
                console.error('Failed to update log on startup error:', logErr);
            }
        }

        return res.status(500).send({
            status: 500,
            result: 0,
            log_id: logId,
            data: null,
            error_message: `Start import failed: ${error.message}`
        });
    }
};

/**
 * Фоновая функция: выполняет импорт и фиксирует результат в ou.logs
 */
async function runImportInBackground(logId, userId, sourceLogParam) {
    try {
        console.log(`[importEarved] Background import started. log_id: ${logId}, userId: ${userId}`);
        const importResult = await importEarved(userId, sourceLogParam);
        console.log(`[importEarved] Background import finished. log_id: ${logId}`, importResult);

        await earved.endLog(logId, 'success', null, importResult);
    } catch (error) {
        console.error(`[importEarved] Background import failed. log_id: ${logId}`, error);

        try {
            await earved.endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[importEarved] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

/**
 * Читает массив счетов (propertis.arved) и список отсутствующих контр-агентов (changes) из лога getEarved
 */
async function readSourceLog(sourceLogId) {
    const sql = `select propertis -> 'arved' as arved, changes
                 from ou.logs
                 where id = $1`;
    const r = await db.queryDb(sql, [sourceLogId], null, null, null, null, config);
    const row = r && Array.isArray(r.data) && r.data[0] ? r.data[0] : null;
    return {
        batches: row && Array.isArray(row.arved) ? row.arved : [],
        changes: row && Array.isArray(row.changes) ? row.changes : []
    };
}

/**
 * Делит счета каждого батча на импортируемые и пропущенные (контр-агента нет в libs.asutus).
 * @returns {{batches: Array, skipped: Array, totalFetched: number}}
 */
function splitByMissingAsutus(sourceBatches, missingSet) {
    const batches = [];
    const skipped = [];
    let totalFetched = 0;

    sourceBatches.forEach(function (b) {
        const invoices = Array.isArray(b.arved) ? b.arved : [];
        const importable = [];

        invoices.forEach(function (inv) {
            totalFetched++;
            const data = inv && inv.data ? inv.data : (inv || {});
            const regkood = data.asutusid !== undefined && data.asutusid !== null ? String(data.asutusid).trim() : '';
            if (regkood !== '' && missingSet[regkood]) {
                skipped.push({
                    number: data.number !== undefined && data.number !== null ? String(data.number).trim() : '',
                    asutusid: regkood,
                    rekvId: b.rekvId
                });
            } else {
                importable.push(inv);
            }
        });

        if (importable.length > 0) {
            batches.push({rekvId: b.rekvId, userId: b.userId, json: importable});
        }
    });

    return {batches: batches, skipped: skipped, totalFetched: totalFetched};
}

/**
 * Частичный импорт счетов из лога getEarved
 * @returns {Promise<Object>} результат в формате loeEarved + totalSkipped, skipped, missing, source_log_id
 */
async function importEarved(userId, sourceLogParam) {
    const sourceLogId = await checkAsutus.findSourceLogId(sourceLogParam);

    if (!sourceLogId) {
        // штатная ситуация: за период не было получения счетов из FinBit
        return {
            error_code: 0,
            result: 0,
            totalFetched: 0,
            totalImported: 0,
            totalSkipped: 0,
            skipped: [],
            missing: [],
            invoiceNumbers: [],
            batches: [],
            source_log_id: null,
            error_message: 'Arveid ei leitud (getEarved logi puudub)'
        };
    }

    const source = await readSourceLog(sourceLogId);

    // рег.коды контр-агентов, которых нет в базе (заполняет check_asutus -> libs.check_asutus_availibility)
    const missingSet = {};
    const missing = [];
    source.changes.forEach(function (c) {
        const regkood = c && c.puuduvad_asutused ? String(c.puuduvad_asutused).trim() : '';
        if (regkood !== '' && !missingSet[regkood]) {
            missingSet[regkood] = true;
            missing.push(regkood);
        }
    });

    const split = splitByMissingAsutus(source.batches, missingSet);

    let base;
    if (split.batches.length > 0) {
        base = await earved.loeEarved(userId, split.batches);
    } else {
        base = {
            error_code: 0,
            result: 0,
            totalFetched: split.totalFetched,
            totalImported: 0,
            invoiceNumbers: [],
            error_message: `Imporditud 0 arvet (leitud: ${split.totalFetched})`,
            batches: [],
            data: []
        };
    }

    const skippedNote = split.skipped.length > 0
        ? ` Vahele jäetud ${split.skipped.length} arvet (puuduvad asutused: ${missing.join(', ')}).`
        : '';

    return Object.assign({}, base, {
        // totalFetched - все счета из лога getEarved (включая пропущенные)
        totalFetched: split.totalFetched,
        totalSkipped: split.skipped.length,
        skipped: split.skipped,
        missing: missing,
        source_log_id: sourceLogId,
        error_message: `${base.error_message || ''}${skippedNote}`.trim()
    });
}

exports.importEarved = importEarved;
exports.splitByMissingAsutus = splitByMissingAsutus;
exports.readSourceLog = readSourceLog;
exports.runImportInBackground = runImportInBackground;
exports.FLOW_NAME = FLOW_NAME;
