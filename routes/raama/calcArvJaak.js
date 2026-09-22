'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

const DEFAULT_USER_ID = 2477;
const DEFAULT_REKV_ID = 63;
const FLOW_NAME = 'docs.check_arv_jaak';

/**
 * Express handler для роута POST /task/calcArvJaak/
 * Запускает расчет асинхронно в фоне и сразу возвращает ответ с log_id
 * Пример вызова: curl.exe -X POST http://localhost:3000/task/calcArvJaak/ -d '{"user_id": 2477, "rekv_id": 63}'
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);

    const userId = Number(params.user_id || params.userid_id || params.userId || DEFAULT_USER_ID);
    const rekvId = Number(params.rekv_id || params.rekvid || params.rekvId || DEFAULT_REKV_ID);

    let logId = null;
    console.log('calcArvJaak start')

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
        runCalculationInBackground(logId, userId);

        // 3. Сразу возвращаем успешный ответ клиенту с log_id для отслеживания
        return res.status(200).send({
            status: 200,
            result: 1,
            log_id: logId,
            data: {
                action: 'calcArvJaak',
                status: 'STARTED',
                log_id: logId
            },
            error_message: null
        });

    } catch (error) {
        console.error('Error starting calcArvJaak task:', error);

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
async function runCalculationInBackground(logId, userId) {
    try {
        console.log(`[calcArvJaak] Background calculation started. log_id: ${logId}, userId: ${userId}`);
        const calcResult = await checkArvJaak(userId);
        console.log(`[calcArvJaak] Background calculation finished successfully. log_id: ${logId}`, calcResult);

        // Фиксируем успешное завершение
        await endLog(logId, 'success');
    } catch (error) {
        console.error(`[calcArvJaak] Background calculation failed. log_id: ${logId}`, error);

        // Фиксируем ошибку в ou.logs
        try {
            await endLog(logId, 'failed', error.message);
        } catch (logErr) {
            console.error(`[calcArvJaak] Failed to update error log for log_id: ${logId}`, logErr);
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

        const result = await checkArvJaak(userId);
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
 * Выполняет запрос к БД для пересчета остатков счетов
 */
async function checkArvJaak(userId = DEFAULT_USER_ID) {
    const sql = `SELECT
                     docs.check_arv_jaak(a.parentid, u.id)
                 from
                     docs.arv                 a
                         inner join ou.userid u on u.rekvid = a.rekvid
                         inner join ou.rekv   r on r.id = a.rekvid
                 where
                       tasud is not null
                   and a.tasud <= current_date
                   and a.jaak > 0
                   and a.liik = 1
                   and coalesce(a.tahtaeg, current_date) <= current_date
                   and u.kasutaja = 'vlad'
                   and u.status < 3
                   and r.parentid < 999
                 and exists (select id from ou.userid where id = $1)
                 order by
                     a.tasud desc, a.kpv
                 limit 5000`;

    try {
        console.log('start calc arv jaak for userId:', userId);
        let l_result = await db.queryDb(sql, [userId], null, null, null, null, config);
        console.log('finish calc arv jaak', l_result);
        return l_result;
    } catch (error) {
        throw new Error(`DB Query failed: ${error.message}`);
    }
}

exports.checkArvJaak = checkArvJaak;

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
        console.log('finish create log', FLOW_NAME, l_result);
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
            console.log('Finished calcArvJaak successfully:', result);
            process.exit(0);
        })
        .catch((error) => {
            console.error('Error in calcArvJaak execution:', error);
            process.exit(1);
        });
}
