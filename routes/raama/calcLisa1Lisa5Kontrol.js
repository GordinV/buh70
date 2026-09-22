'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const FLOW_NAME = 'eelarve.salvesta_lisa_1_5_kontrol';

/**
 * Express handler для роута POST /task/calcLisa1Lisa5/
 * Запускает расчет асинхронно в фоне и сразу возвращает ответ с log_id
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);
    const userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);

    let logId = null;

    try {
        // 1. Создаем запись в ou.logs о старте процесса
        const logResult = await createLog(rekvId, userId);
        if (logResult && logResult.data && logResult.data[0]) {
            logId = logResult.data[0].id;
        }

        if (!logId) {
            throw new Error('Лог-запись не создана (не удалось получить log_id)');
        }

        // 2. Запускаем фоновый расчет БЕЗ ожидания завершения
        runCalculationInBackground(logId, userId, rekvId);

        // 3. Сразу возвращаем успешный ответ клиенту с log_id для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'calcLisa1Lisa5',
                status: 'STARTED',
                log_id: logId
            },
            error_message: null
        });

    } catch (error) {
        console.error('Error starting calcLisa1Lisa5 task:', error);

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
            error_message: `Start calculation failed: ${error.message}`
        });
    }
};

/**
 * Фоновая асинхронная функция выполнения расчета и обновления статуса в ou.logs
 */
async function runCalculationInBackground(logId, userId, rekvId) {
    try {
        console.log(`[calcLisa1Lisa5] Background calculation started. log_id: ${logId}, userId: ${userId}, rekvId: ${rekvId}`);
        const calcResult = await executeLisaKontrol(userId, rekvId);
        console.log(`[calcLisa1Lisa5] Background calculation finished successfully. log_id: ${logId}`, calcResult);

        // Фиксируем успешное завершение
        await endLog(logId, 'success');
    } catch (error) {
        console.error(`[calcLisa1Lisa5] Background calculation failed. log_id: ${logId}`, error);

        // Фиксируем ошибку в ou.logs
        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[calcLisa1Lisa5] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

/**
 * Функция синхронного выполнения полного цикла расчета (для CLI и тестов)
 */
async function executeCalculation(userId = DEFAULT_USER_ID, rekvId = DEFAULT_REKV_ID) {
    let logId = null;
    try {
        const logData = await createLog(rekvId, userId);
        logId = logData.data[0].id;
        console.log('Created log id:', logId);

        const result = await executeLisaKontrol(userId, rekvId);
        console.log('Calculation result:', result);

        await endLog(logId, 'success');
        console.log('Finished log id:', logId);
        return result;
    } catch (error) {
        if (logId) {
            await endLog(logId, 'failed', error.message);
        }
        throw error;
    }
}

exports.executeCalculation = executeCalculation;

/**
 * Получение списка периодов и учреждений для контроля
 */
async function getRekvData(rekvId = DEFAULT_REKV_ID) {
    const sql = `select distinct
                     to_char((gomonth(make_date(aasta, kuu, 1), 1) - 1)::date, 'YYYY-MM-DD') as kpv,
                     rekvid
                 from
                     ou.aasta
                 where
                       kinni = 0
                   and gomonth(make_date(aasta, kuu, 1), 1) < gomonth(current_date, 1)
                   and rekvid in (
                                     SELECT
                                         rekv_id
                                     FROM
                                         get_asutuse_struktuur($1::integer) a
                                 )
                   and make_date(aasta, kuu, 1) > '2025-01-01'
                 order by
                     rekvid, kpv`;

    try {
        console.log('start getRekvData for rekvId:', rekvId);
        return await db.queryDb(sql, [rekvId], null, null, null, null, config);
    } catch (error) {
        throw new Error(`getRekvData DB Query failed: ${error.message}`);
    }
}

exports.getRekvData = getRekvData;

/**
 * Выполнение хранимой процедуры salvesta_lisa_1_5_kontrol для всех найденных записей
 */
async function executeLisaKontrol(userId = DEFAULT_USER_ID, rekvId = DEFAULT_REKV_ID) {
    const rekvDataResult = await getRekvData(rekvId);
    const rows = rekvDataResult && rekvDataResult.data ? rekvDataResult.data : [];

    if (!rows.length) {
        console.log('No records found for lisa1_lisa5 kontrol calculation');
        return { count: 0, result: [] };
    }

    const sqls = [];
    for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const sql = `call eelarve.salvesta_lisa_1_5_kontrol(${userId}, '${row.kpv}', ${row.rekvid});`;
        sqls.push(sql);
    }

    try {
        console.log(`Executing ${sqls.length} queries for lisa1_lisa5 kontrol`);
        const result = await db.executeQueries(sqls, null, null, config);
        return { count: sqls.length, result };
    } catch (error) {
        throw new Error(`executeLisaKontrol failed: ${error.message}`);
    }
}

exports.executeLisaKontrol = executeLisaKontrol;

/**
 * Логгирование старта задачи
 */
async function createLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow', $3::text, 'exec_start', (clock_timestamp())))
                 returning id;`;

    try {
        console.log('start create log for flow:', FLOW_NAME);
        let l_result = await db.queryDb(sql, [rekvId, userId, FLOW_NAME], null, null, null, null, config);
        console.log('finish create log', l_result);
        return l_result;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование окончания задачи (успех / ошибка)
 */
async function endLog(logId, status = 'success', errorMessage = null) {
    if (!logId) return;

    const sql = `update ou.logs
                 set propertis = propertis || jsonb_build_object('exec_end', (clock_timestamp()), 'status', $1::text, 'error', $2::text)
                 where id = $3;`;

    try {
        console.log('start endLog for id:', logId, 'status:', status);
        await db.queryDb(sql, [status, errorMessage, logId], null, null, null, null, config);
        console.log('finish endLog');
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

// Запуск при прямом вызове из командной строки (CLI)
if (require.main === module) {
    executeCalculation()
        .then((result) => {
            console.log('Finished Lisa1Lisa5 kontrol successfully:', result);
            process.exit(0);
        })
        .catch((error) => {
            console.error('Error in Lisa1Lisa5 kontrol execution:', error);
            process.exit(1);
        });
}
