'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select * from palk.gen_taabel1($1::integer, $2::json)`;

describe('palk.palk.gen_taabel1 tests', () => {
    it(` called without params`, async() => {
        let params = null;

        let returnValue = await db.queryDb(sql, [1,params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(0);
        expect (returnValue.error_code).toBe(6); //vale parametrid
    });

    it(` called with month and year,  and lepingid  params`, async() => {
        let params = '[' + JSON.stringify({lepingid: 4, kuu: 4, aasta: 2018}) + ']';

        let returnValue = await db.queryDb(sql, [1, params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBeGreaterThan(0);
    });
});