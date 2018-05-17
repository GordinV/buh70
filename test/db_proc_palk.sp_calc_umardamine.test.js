'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select * from palk.sp_calc_umardamine($1::integer, $2::json)`;

describe('palk.sp_calc_umardamine tests', () => {
    it (`called without or wrong user_id parameter`, async () => {
        let params = null;

        let returnValue = await db.queryDb(sql, [null,params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(0);
        expect (returnValue.error_code).toBe(5); //vale parametrid

    });

    it(` called without params`, async() => {
        let params = null;

        let returnValue = await db.queryDb(sql, [1,params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(0);
        expect (returnValue.error_code).toBe(6); //vale parametrid
    });

    it(` called with  params`, async() => {
        let params = {lepingid:4,libid:384};

        let returnValue = await db.queryDb(sql, [1, params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(1);
    });

});