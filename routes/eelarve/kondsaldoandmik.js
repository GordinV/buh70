'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

// получить список работников
    let sql = `SELECT eelarve.sp_koosta_saldoandmik(2477, to_jsonb(qry.*)::JSON) AS tulemus
               FROM (
                        SELECT DISTINCT  (make_date(year(kpv), month(kpv), 1) + interval '1 month')::date - 1 as kpv,
                                         1 AS tyyp, 1 AS kond, 63 as rekvid
                        FROM docs.doc d
                                 INNER JOIN docs.journal j ON j.parentid = d.id
                        WHERE d.lastupdate >= current_date - INTERVAL '1 day'
                    ) qry`;

    let data = db.queryDb(sql, null, null, null, null, null, config);
