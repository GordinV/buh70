'use strict';
const db = require('./../../libs/db');

let promise = new Promise((resolve, reject) => {

// получить список работников
    let sql = `SELECT *
               FROM lapsed.check_cache_for_saldo_ja_kaive()`;

    let data = db.queryDb(sql, null, null, null, null, null);
    resolve(data);
});


