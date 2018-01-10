const {Client} = require('pg'),
    config = require('../config/config');

const db = {
    queryDb: async (sqlString, params, sortBy, sqlWhere) => {

        let result = {
            error_code: 0,
            result: null,
            error_message: null,
            data: []
        }; // return data in this form

        let prepairedSqlString = sqlString;
        if (sortBy || sqlWhere) {
            prepairedSqlString = createSqlString(prepairedSqlString, sortBy, sqlWhere)
        }

        const client = new Client(config.pg.connection);
        await client.connect();
        try {
            const res = await client.query(prepairedSqlString, params);
            if (res.rowCount && res.rowCount === 1 && 'error_code' in res.rows[0]) {
                // executed procedure
                result = Object.assign(result, res.rows[0]);
            } else {
                // usual query
                result.data = res.rows;
                result.result = res.rowCount;
            }
        } catch (e) {
            console.error('tekkis viga', e);
            result.error_code = 9;
            result.error_message = e.message;
        }
        await client.end();
        return result;
    },
    executeQueries: async (sqls, params, returnData) => {
        const client = new Client(config.pg.connection);
        await client.connect();
        let result = [];
        try {
            await Promise.all(sqls.map(async sql => {
                let sqlString = typeof sql === 'string' ? sql : sql.sql;
                let data = await client.query(sqlString, params);
                // запишем итог в объект, который вернем как результат
                result.push({error_code: 0, result: data.rowCount, data: data.rows});

                //если задан шаблон и параметр отдан объектом, то вернем результат в заданой форме
                if (typeof sql === 'object' && returnData) {
                    returnData[sql.alias] = data.rows;
                }
            }));
        } catch (e) {
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
 */
function createSqlString(sql, sortBy, sqlWhere) {
    let sortByColumn = '',
        sortByDirection = '';

    if (sortBy.length) {
        // есть параметр для сортировки
        sortByColumn = ' order by ' +  ' ' + sortBy[0].column;
        sortByDirection = sortBy[0].direction;
    }

    return `select * from (${sql}) qry 
    ${sqlWhere}   ${sortByColumn}  ${sortByDirection} `;
}


module.exports = db;