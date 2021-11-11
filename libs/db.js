const {Client} = require('pg');
const log = require('./log');

const db = {
    queryDb: async (sqlString, params, sortBy, sqlWhere, sqlLimit, subTotals, dbConfig) => {
        // если не задана конфигурация, используем дефолтный
        let config = !dbConfig ? require('../config/default') : dbConfig;

        let result = {
            error_code: 0,
            result: null,
            error_message: null,
            data: []
        }; // return data in this form

        let prepairedSqlString = sqlString;
        if (sortBy || sqlWhere || sqlLimit || subTotals) {
            prepairedSqlString = createSqlString(prepairedSqlString, sortBy, sqlWhere, sqlLimit, subTotals)
        }

        const client = new Client(config.pg.connection);
        await client.connect();

        try {
            const res = await client.query(prepairedSqlString, params);
            if (res.rowCount && res.rowCount === 1 && res.rows && res.rows.length === 1 && ('error_code' in res.rows[0])) {
                // executed procedure
                result = Object.assign(result, res.rows[0]);
            } else {
                // usual query
                result = Object.assign(result, {data: res.rows}, {result: res.rowCount});
            }

        } catch (e) {
            // logs
            let message = `tekkis viga ${e}, ${JSON.stringify(prepairedSqlString)}, ${params}`;
            log(message, 'error');

            result.error_code = 9;
            result.error_message = e.message;
        }

        await client.end();
        return result;
    },
    executeQueries: async (sqls, params, returnData, dbConfig) => {
        let config = !dbConfig ? require('../config/default') : dbConfig;

        const client = new Client(config.pg.connection);
        await client.connect();
        let result = [];
        let sqlString;

        try {
           await  Promise.all(sqls.map(async sql => {
                sqlString = typeof sql === 'string' ? sql : sql.sql;
                let data = await client.query(sqlString, params);
                // запишем итог в объект, который вернем как результат
                result.push({error_code: 0, result: data.rowCount, data: data.rows});
                //если задан шаблон и параметр отдан объектом, то вернем результат в заданой форме
                if (typeof sql === 'object' && returnData) {
                    // если есть декоратор (триггер) , то пропустим данные через него
                    if (sql.converter) {
                        returnData[sql.alias] = sql.converter(data.rows)
                    } else {
                        returnData[sql.alias] = data.rows;
                    }
                }

            }));
        } catch (e) {
            // logs
            let message = `tekkis viga ${e}, ${sqls}`;
            log(message, 'error');

            result.push({error_code: 9, result: null, data: [], error_message: e.message});
        }

        await client.end();
        return returnData ? returnData : result;
    },
};

/**
 * создаст запрос с доп. фильтром и сортировкой
 * @param sql
 * @param sortBy
 * @param sqlWhere
 * @returns {string}
 * @sqlLimit recors limit
 */
function createSqlString(sql, sortBy, sqlWhere, sqlLimit, sqlSubtotals) {
    let sortByColumn = '',
        sortByDirection = '',
        rowsLimit = '';
    totals = 'count(*) OVER() AS filter_total';

    if (sortBy.length) {
        // есть параметр для сортировки
        let column = sortBy[0].column;
        if (sortBy[0].type) {
            // задан тип, конвертируем
            switch (sortBy[0].type) {
                case 'date':
                    column = `format_date(${column}::text)`;
                    break;
                case 'number':
                    column = `(regexp_replace((${column})::text, '[^0-9,.,-]', ''))::NUMERIC`;
                    break;
                default:
                // code block
            }
        }
        sortByColumn = ' order by ' + ' ' + column;
        sortByDirection = sortBy[0].direction;
    }

    if (sqlLimit) {
        rowsLimit = ` LIMIT ${sqlLimit}`;
    }

    if (sqlSubtotals) {
        // есть доп. суммирование
        totals = `${totals}, ${sqlSubtotals}`
    }

    return `SELECT ${totals}, * FROM (${sql}) qry 
    ${sqlWhere}   ${sortByColumn}  ${sortByDirection} ${rowsLimit}`;
}


module.exports = db;