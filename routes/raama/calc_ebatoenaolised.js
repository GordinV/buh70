'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

// получить список работников
let sql = `SELECT docs.ebatoenaolised(null, current_date);`;

let data = db.queryDb(sql, null, null, null, null, null, config);
