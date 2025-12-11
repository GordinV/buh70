'use strict';
const db = require('./../libs/db');
const config = require('./../config/narvalv.json');

let test_config = Object.assign({}, config);
test_config.pg.database = 'db_test';
test_config.pg.connection = test_config.pg.connection + '_test';

// получить список работников
let sql = `select ou.execute_task(null::JSONB);`;

let data = db.queryDb(sql, null, null, null, null, null, test_config);
