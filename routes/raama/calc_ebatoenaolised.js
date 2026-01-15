'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

// получить список работников
let sql = `SELECT docs.ebatoenaolised(id, current_date) from ou.rekv where parentid = 119;`;

let data = db.queryDb(sql, null, null, null, null, null, config);
