'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

//    let data = db.queryDb(sql, null, null, null, null, null, config);

// Запускаем основную функцию
main()
    .then((result) => {
        console.log('Finished Saldoandmik successfully:', result);
        process.exit(0); // Явно завершаем процесс
    })
    .catch((error) => {
        console.error('Error in koosta_saldoandmik execution:', error);
        process.exit(1); // Завершаем с кодом ошибки
    });

/**
 * Основная функция для составления извещений
 */
async function main() {
    // Параметры для фильтрации (вынесены в переменные для удобства правки)
    return await koostaSaldoandmik();
}

/**
 * Выполняет запрос к БД
 */
async function koostaSaldoandmik() {
    const sql = `SELECT eelarve.sp_koosta_saldoandmik(2477, to_jsonb(qry.*)::JSON) AS tulemus
               FROM (
                        SELECT DISTINCT  (make_date(year(kpv), month(kpv), 1) + interval '1 month')::date - 1 as kpv,
                                         1 AS tyyp, 1 AS kond, 63 as rekvid
                        FROM docs.doc d
                                 INNER JOIN docs.journal j ON j.parentid = d.id
                        WHERE d.lastupdate >= current_date - INTERVAL '1 day'
                    ) qry`;


    try {
        console.log('start');
        return await db.queryDb(sql, null, null, null, null, null, config);
    } catch (error) {
        // Пробрасываем ошибку наверх с контекстом
        throw new Error(`DB Query failed: ${error.message}`);
    }
}