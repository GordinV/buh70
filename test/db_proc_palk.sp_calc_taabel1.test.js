'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `select palk.sp_calc_taabel1($1 :: JSONB)::integer as tunnid`;

describe('palk.sp_calc_taabel1 tests', () => {
    it(` called without params`, async() => {
        let params = {};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let tunnid = returnValue.data[0].tunnid;
        expect(tunnid).toBe(0);
    });

    it(` called with month and year,  and lepingid  params`, async() => {
        let params = {lepingid: 4, kuu: 4, aasta: 2018};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let tunnid = returnValue.data[0].tunnid;
        expect(tunnid).toBeGreaterThan(0);
    });
});