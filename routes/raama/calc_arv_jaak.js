'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

// получить список работников
let sql = `SELECT docs.check_arv_jaak(a.parentid, u.id)
           from docs.arv a,
                ou.userid u
           where tasud is not null
             and a.tasud <= current_date
             and a.jaak > 0
             and a.liik = 1
             and u.rekvid = a.rekvid
             and coalesce(a.tahtaeg, current_date) <= current_date
             and u.kasutaja = 'vlad'
           order by a.tasud desc, a.kpv
           limit 5000;`;

let data = db.queryDb(sql, null, null, null, null, null, config);
