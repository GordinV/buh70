'use strict';
const db = require('./../../libs/db');
//const config = require('./../../config/narvalv.json');
const config = require('./../../config/default.json');

// получить список работников
//let sql = `SELECT docs.ebatoenaolised(id, current_date) from ou.rekv where parentid = 119;`;

//let data = db.queryDb(sql, null, null, null, null, null, config);

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
 * @param {integer} rekvId - ID родительского учреждения
 */
async function ebatoenaolised(rekvId) {
    // Используем параметры $1 вместо хардкода внутри строки
    // current_date оставляем на уровне БД, чтобы время бралось серверное
    const sql = `SELECT
                     docs.ebatoenaolised(id, current_date)
                 from
                     ou.rekv
                 where
                     parentid = $1;`;

    // Параметры запроса
    const queryParams = [rekvId];

    try {
        // Передаем параметры в queryDb (предполагая, что 2-й аргумент это params)
        // Если сигнатура queryDb(sql, params, ...), то так:
        const data = await db.queryDb(sql, queryParams, null, null, null, null, config);

        return data;
    } catch (error) {
        // Пробрасываем ошибку наверх с контекстом
        throw new Error(`DB Query failed: ${error.message}`);
    }
}