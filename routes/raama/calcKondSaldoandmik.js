'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const DEFAULT_KOND = 1;

/**
 * Express handler для роута POST /task/calcKondSaldoandmik/
 * Запускает расчет асинхронно в фоне и сразу возвращает ответ с log_id
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);
    const userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);
    const kond = params.kond !== undefined ? Number(params.kond) : DEFAULT_KOND;

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

        // 2. Запускаем фоновый расчет БЕЗ ожидания завершения (так как расчет может длиться часами)
        runCalculationInBackground(logId, userId, kond, rekvId);

        // 3. Сразу возвращаем успешный ответ клиенту с log_id для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'calcKondSaldoandmik',
                status: 'STARTED',
                log_id: logId
            },
            error_message: null
        });

    } catch (error) {
        console.error('Error starting calcKondSaldoandmik task:', error);

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
async function runCalculationInBackground(logId, userId, kond, rekvId) {
    try {
        console.log(`[calcKondSaldoandmik] Background calculation started. log_id: ${logId}, userId: ${userId}, rekvId: ${rekvId}, kond: ${kond}`);
        const calcResult = await koostaSaldoandmik(userId, kond, rekvId);
        console.log(`[calcKondSaldoandmik] Background calculation finished successfully. log_id: ${logId}`, calcResult);

        // Фиксируем успешное завершение
        await endLog(logId, 'success');
    } catch (error) {
        console.error(`[calcKondSaldoandmik] Background calculation failed. log_id: ${logId}`, error);

        // Фиксируем ошибку в ou.logs
        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[calcKondSaldoandmik] Failed to update error log for log_id: ${logId}`, logErr);
        }
    }
}

/**
 * Функция синхронного выполнения полного цикла расчета (для CLI)
 */
async function executeCalculation(userId = DEFAULT_USER_ID, rekvId = DEFAULT_REKV_ID, kond = DEFAULT_KOND) {
    let logId = null;
    try {
        const logData = await createLog(rekvId, userId);
        logId = logData.data[0].id;
        console.log('Created log id:', logId);

        const result = await koostaSaldoandmik(userId, kond, rekvId);
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
 * Выполняет запрос к БД для формирования сальдоандмика
 */
async function koostaSaldoandmik(userId = DEFAULT_USER_ID, kond = DEFAULT_KOND, rekvId = DEFAULT_REKV_ID) {
    const sql = `SELECT eelarve.sp_koosta_saldoandmik($1, to_jsonb(qry.*)::JSON) AS tulemus
                 FROM (
                          SELECT DISTINCT (make_date(year(kpv), month(kpv), 1) + interval '1 month')::date - 1 AS kpv,
                                          1 AS tyyp, $2::integer AS kond, $3::integer AS rekvid
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                          WHERE d.lastupdate >= current_date - INTERVAL '1 day'
                          and exists (select id from ou.userid where id = $1)

                      ) qry`;

    try {
        console.log('start koostaSaldoandmik with params:', { userId, kond, rekvId });
        return await db.queryDb(sql, [userId, kond, rekvId], null, null, null, null, config);
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

/**
 * Логгирование старта задачи
 */
async function createLog(rekvId = DEFAULT_REKV_ID, userId = DEFAULT_USER_ID) {
    const sql = `insert into ou.logs (rekvid, user_id, propertis)
                 values ($1, $2, jsonb_build_object('flow','eelarve.sp_koosta_saldoandmik', 'exec_start', (clock_timestamp())))
                 returning id;`;

    try {
        console.log('start create log');
        let l_result = await db.queryDb(sql, [rekvId, userId], null, null, null, null, config);
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
            console.log('Finished Saldoandmik successfully:', result);
            process.exit(0);
        })
        .catch((error) => {
            console.error('Error in koosta_saldoandmik execution:', error);
            process.exit(1);
        });
}
