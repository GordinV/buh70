'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');


async function get_rekv_data() {
// получить параметры
    let sql = `select distinct
                   gomonth(make_date(aasta, kuu, 1), 1) - 1 as kpv,
                   rekvid
               from
                   ou.aasta
               where
                     kinni = 0
                 and gomonth(make_date(aasta, kuu, 1), 1) < gomonth(current_date, 1)
                 and rekvid in (
                                   SELECT
                                       rekv_id
                                   FROM
                                       get_asutuse_struktuur(63) a

                               )
                 and make_date(aasta, kuu, 1) > '2025-01-01'
               order by
                   rekvid, kpv`;

    let data = await db.queryDb(sql, null, null, null, null, null, config);
    return data;

}

let promise = new Promise((resolve, reject) => {

// получить список работников
    let sql = `select distinct
                   to_char((gomonth(make_date(aasta, kuu, 1), 1) - 1)::date, 'YYYY-MM-DD') as kpv,
                   rekvid
               from
                   ou.aasta
               where
                     kinni = 0
                 and gomonth(make_date(aasta, kuu, 1), 1) < gomonth(current_date, 1)
                 and rekvid in (
                                   SELECT
                                       rekv_id
                                   FROM
                                       get_asutuse_struktuur(63) a

                               )
                 and make_date(aasta, kuu, 1) > '2025-01-01'
               order by
                   rekvid, kpv`;

    let data = db.queryDb(sql, null, null, null, null, null, config);
    resolve(data);
}).then((data) => {
    console.log(data);
    var sqls = [];
    for (let i = 0; i < data.data.length; i++) {
        let row = data.data[i];
        let sql = `call eelarve.salvesta_lisa_1_5_kontrol(2477, '${row.kpv}',${row.rekvid})`;
        sqls.push(sql);
    }
    let result = db.executeQueries(sqls, null, null, config);
})

