'use strict';
const db = require('./../libs/db');
//const config = require('./../config/narvalv.json');
const config = require('./../config/default.json');
console.log('start executePgTask');

// Запускаем основную функцию
executeTask()
    .then((result) => {
        console.log('Finished teatis successfully:', result);
        process.exit(0); // Явно завершаем процесс
    })
    .catch((error) => {
        console.error('Error in teatis execution:', error);
        process.exit(1); // Завершаем с кодом ошибки
    });


/**
 * Выполняет запрос к БД
 */
async function executeTask() {
    // Используем параметры $1 вместо хардкода внутри строки
    // current_date оставляем на уровне БД, чтобы время бралось серверное
    const sql = `SELECT ou.execute_task(null::JSONB);`;

    try {
        console.log('start sql', sql);
        const data = await db.queryDb(sql, null, null, null, null, null, config);
        console.log('finished sql', data);

        return data;
    } catch (error) {
        // Пробрасываем ошибку наверх с контекстом
        console.error('error', error.message);
//        throw new Error(`DB Query failed: ${error.message}`);
    }
    console.log('finished executePgTask')
}
