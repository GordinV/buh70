'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/default.json');
const config = require('./../../config/narvalv.json');

/**
 * Основная функция для получения статуса логов
 * пример вызова curl.exe -X POST http://localhost:3000/task/read_log/2477/eelarve.sp_koosta_saldoandmik
 */
exports.main = async (req, res) => {
    const params = Object.assign({}, req.query, req.body, req.params);
    const userId = params.user_id || params.userid_id || params.userId;
    const taskName = params.task_name || params.taskName;

    if (!userId) {
        return res.status(400).send({
            error_message: 'Viga: puudub user_id',
            result: 0,
            data: null
        });
    }

    if (!taskName) {
        return res.status(400).send({
            error_message: 'Viga: puudub task_name',
            result: 0,
            data: null
        });
    }

    try {
        const result = await readLog(userId, taskName, {
            logId: params.log_id || params.logId,
            limit: params.limit,
            hours: params.hours
        });
        return res.status(200).send(result);
    } catch (error) {
        console.error('readLog error:', error);

        return res.status(500).send({
            error_message: `Viga: ${error.message}`,
            result: 0,
            data: null
        });
    }
};

/**
 * чтение лог файла, на предмет наличия вызова пересчета на сегодняшний день
 * @returns {Promise<{error_code: number, result: null, error_message: null, data: []}>}
 */
async function readLog(userId, taskName, options = {}) {
    // Необязательные параметры (по умолчанию поведение прежнее: одна последняя запись)
    const logId = Number.isInteger(Number(options.logId)) && Number(options.logId) > 0 ? Number(options.logId) : null;
    const limit = Math.min(Math.max(parseInt(options.limit, 10) || 1, 1), 50);
    const hours = Math.min(Math.max(parseInt(options.hours, 10) || 48, 1), 720);

    // Фильтр по current_date убран: запуск, начатый до полуночи (например, 23:57), на следующий день
    // выпадал из выборки и оркестратор считал задачу не стартовавшей (NO_START_DATE).
    // Используем скользящее окно по exec_start (timestamptz учитывает смещение +03:00 в строке).
    // Если задан log_id — ищем конкретную запись независимо от окна.
    const params = [userId, taskName];
    let extraFilter;
    if (logId) {
        params.push(logId);
        extraFilter = `and l.id = $3`;
    } else {
        params.push(hours);
        extraFilter = `and (propertis ->> 'exec_start')::timestamptz >= now() - ($3::integer * interval '1 hour')`;
    }
    params.push(limit);

    const sql = `select
                     l.id                       as id,
                     propertis ->> 'flow'       as flow,
                     propertis ->> 'status'     as status,
                     propertis ->> 'exec_start' as exec_start,
                     propertis ->> 'exec_end'   as exec_end,
                     propertis -> 'result'      as result,
                     propertis ->> 'response'   as response,
                     propertis ->> 'error'      as error
                 from
                     ou.logs l
                 where
                       l.user_id = $1
                   and propertis ->> 'flow' is not null
                   and propertis ->> 'flow' = $2
                   ${extraFilter}
                 order by
                     l.id desc
                 limit $4`;

    try {
        console.log('start readLog');
        let l_result = await db.queryDb(sql, params, null, null, null, null, config);
        console.log('finish read log', l_result);
        return l_result;

    } catch (error) {
        // Пробрасываем ошибку наверх с контекстом
        throw new Error(`DB Query failed: ${error.message}`);
    }
}
