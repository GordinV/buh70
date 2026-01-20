/*
'use strict';

let data =  koostaTeatis();
console.log('finished teatis', data);


async function koostaTeatis() {
    const db = require('./../../libs/db');
//const config = require('./../../config/narvalv.json');
    const config = require('./../../config/default.json');


// получить список работников
    let sql = `select
                   docs.koosta_teatis(u.id, current_date)
               from
                   ou.userid u
               where
                     u.kasutaja = 'vlad'
                 and u.rekvid in (
                                     select
                                         id
                                     from
                                         ou.rekv
                                     where
                                         parentid = 119
                                 )
    ;`;
    console.log('Start teatis', sql);

    let data = await db.queryDb(sql, null, null, null, null, null, config);
    return data;

}
*/

'use strict';

const db = require('./../../libs/db');
// const config = require('./../../config/narvalv.json');
const config = require('./../../config/default.json');

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
    const targetUser = 'vlad';
    const targetParentId = 119;

    return await koostaTeatis(targetUser, targetParentId);
}

/**
 * Выполняет запрос к БД
 * @param {string} userName - Имя пользователя (kasutaja)
 * @param {number} parentId - ID родительского учреждения
 */
async function koostaTeatis(userName, parentId) {
    // Используем параметры $1, $2 вместо хардкода внутри строки
    // current_date оставляем на уровне БД, чтобы время бралось серверное
    const sql = `
        SELECT docs.koosta_teatis(u.id, current_date) as result
        FROM ou.userid u
        WHERE u.kasutaja = $1
          AND u.rekvid IN (
              SELECT id
              FROM ou.rekv
              WHERE parentid = $2
          )
    `;

    // Параметры запроса
    const queryParams = [userName, parentId];

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