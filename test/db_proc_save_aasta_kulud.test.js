'use strict';

const db = require('./../libs/db');
const async = require('async');

let sql = `select eelarve.sp_salvesta_aastakassakulud ($1, $2, $3 ) as id`; //$1 json params, $2 - user_id, $3 - rekvId
//let data = await db.executeQueries(sqls, [0, this.userId], Object.assign({}, this.config.returnData));

//eelarve.sp_salvesta_aastakassakulud ( JSON, INTEGER, INTEGER );
/*
 doc_summa    NUMERIC = doc_data ->> 'summa';
  doc_valuuta  TEXT = coalesce((doc_data ->> 'valuuta'), 'EUR');
  doc_kuurs    NUMERIC = coalesce((doc_data ->> 'kuurs') :: NUMERIC, 1);
  doc_tegev    TEXT = doc_data ->> 'tegev';
  doc_allikas  TEXT = doc_data ->> 'allikas';
  doc_artikkel TEXT = doc_data ->> 'artikkel';
  doc_kpv      DATE = doc_data ->> 'kpv';
  doc_aasta    INTEGER = coalesce((doc_data ->> 'aasta') :: INTEGER, date_part('year', doc_kpv));
  doc_kuu      INTEGER = coalesce((doc_data ->> 'kuu') :: INTEGER, date_part('month', doc_kpv));
  doc_rekvid   INTEGER = doc_data ->> 'rekvid';

 */
describe('eelarve.sp_salvesta_aastakassakulud tests', () => {
    let userId = 1;
    let rekvId = 1;
    let now = new Date();
    let params = {
        id: 0,
        data: {
            summa: Math.random() * 1000,
            valuuta: 'EUR',
            kuurs: 1,
            tegev: 'tegev',
            allikas: 'allikas',
            artikkel: 'artikkel',
            kpv: now,
            rekvid: rekvId
        }
    };

    it(` called sql`, async() => {
        let returnValue = await db.queryDb(sql, [params, userId, rekvId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
        expect(returnValue.error_message).toBeNull();
    });
});