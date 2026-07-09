
/**
* Выполняет запрос к БД, передавая doc_id в формате JSON.
* @param {number | null} doc_id - ID документа для передачи в задачу.
*/
async function executeTask(doc_id) {
    const db = require("../../libs/db");
    const config = require("../../config/default.json");

    // 1. Определяем SQL-запрос с плейсхолдером $1.
    const sql = `SELECT ou.execute_task($1::JSONB);`;

    // 2. Формируем параметр. Если doc_id не предоставлен (null или undefined),
    // передаем null в базу данных. В противном случае создаем JSON-объект.
    const jsonParameter = doc_id ? JSON.stringify({doc_id: doc_id}) : null;

    const updateSql = `UPDATE ou.task
                       SET
                           status = 1
                       WHERE
                           id = $1;`;
    const selectSql = `SELECT ou.execute_task($1::JSONB);`;

    try {
        // 1. Обновляем статус задачи
        if (doc_id) {
            db.queryDb(updateSql, [doc_id], null, null, null, null, config);
        }

        // 2. Выполняем основную задачу
        db.queryDb(selectSql, [jsonParameter], null, null, null, null, config);

        return data;
    } catch (error) {
        console.error('error', error.message);
        // Пробрасываем ошибку, чтобы вызывающий код мог ее обработать.
        throw error;
    }
}


exports.post = async (req, res) => {
    const doc_id = req.params.doc_id || '';

    // запустим процесс задач
    executeTask(doc_id);

    res.send({
        status: 200, result: 1, data: {
            action: 'Task execute',
            result: {
                doc_id: doc_id,
                error_code: 0,
                error_message: null,
                tulemused: 'Täitmisel'
            },
            data: null
        }
    });
}