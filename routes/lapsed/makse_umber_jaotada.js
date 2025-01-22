'use strict';
const db = require('./../../libs/db');
const config = require('./../../config/narvalv.json');

// получить список не разобранных платежей
let sql = `with
               maksed as (
                             select
                                 id,
                                 rekvid,
                                 (
                                     select id from ou.userid u where u.rekvid = mk.rekvid and kasutaja = 'vlad' limit 1
                                 ) as user_id,
                                 jaak
                             from
                                 lapsed.cur_lapsed_mk mk
                             where
                                 jaak <> 0
                             order by id
               )
           select
               docs.makse_umber_jaotada(m.user_id::INTEGER, m.id::INTEGER, 0) as tulemused
           from
               maksed m`

let data = db.queryDb(sql, null, null, null, null, null, config);
