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
        const result = await readLog(userId, taskName);
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
async function readLog(userId, taskName) {
    const sql = `select
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
                   and (propertis ->> 'exec_start')::date = current_date
                 order by
                     id desc
                 limit 1`;

    try {
        console.log('start readLog');
        let l_result = await db.queryDb(sql, [userId, taskName], null, null, null, null, config);
        console.log('finish read log', l_result);
        return l_result;

    } catch (error) {
        // Пробрасываем ошибку наверх с контекстом
        throw new Error(`DB Query failed: ${error.message}`);
    }
}
