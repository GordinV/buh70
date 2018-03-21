'use strict';

const db = require('./../libs/db');
const async = require('async');

let sql = `select * from eelarve.sp_koosta_kassakulud ($1, $2 )`; //$1   user_id       INTEGER,  $2 - params        JSON

//eelarve.sp_koosta_kassakulud(user_id INTEGER, params JSON );;
/*
 l_rekv_id INTEGER = params ->> 'rekvid';
  l_kpv     DATE = params ->> 'kpv';
  l_tyyp    INTEGER = params ->> 'type';
 */
describe('eelarve.sp_koosta_kassakulud tests', () => {
    let userId = 1;
    let rekvId = 1;
    let now = new Date();
    let params = {
            kpv: now,
            rekvid: rekvId
    };

    it(` called sql`, async() => {
        let returnValue = await db.queryDb(sql, [userId, params]);
        expect(returnValue).toBeDefined();
        console.log('returnValue',returnValue);
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
        expect(returnValue.error_message).toBeNull();
    });
});