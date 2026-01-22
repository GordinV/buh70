'use strict';
const db = require('./../libs/db');
const config = require('./../config/narvalv.json');

// Запускаем основную функцию
main()
    .then((result) => {
        console.log('Finished teatis successfully:', result);
        process.exit(0); // Явно завершаем процесс
    })
    .catch((error) => {
        console.error('Error in teatis execution:', error);
        process.exit(1); // Завершаем с кодом ошибки
    });

/**
 * Основная функция для составления извещений
 */
async function main() {
    // Параметры для фильтрации (вынесены в переменные для удобства правки)
    const targetParentId = 119;

    return await ebatoenaolised(targetParentId);
}

/**
 * Выполняет запрос к БД
 */
async function executeTask() {
    // Используем параметры $1 вместо хардкода внутри строки
    // current_date оставляем на уровне БД, чтобы время бралось серверное
    const sql = `SELECT ou.execute_task(null::JSONB);`;

    try {
        const data = await db.queryDb(sql, null, null, null, null, null, config);

        return data;
    } catch (error) {
        // Пробрасываем ошибку наверх с контекстом
        throw new Error(`DB Query failed: ${error.message}`);
    }
}
