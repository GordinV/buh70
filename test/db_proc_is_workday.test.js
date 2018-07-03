'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `SELECT is_workday($1 :: date, $2::integer) as tulemus`;

describe('is_workday tests', () => {
    it('should exists function',async()=>{
        let l_sql = `select 1 FROM pg_proc WHERE proname = 'is_workday'`;
        let returnValue = await db.queryDb(l_sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it(` should return false for new year`, async() => {

        let returnValue = await db.queryDb(sql, ['2018-01-01', 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let tulemus = Boolean(returnValue.data[0].tulemus);
        expect(tulemus).toBeFalsy();
    });

    it(` should return true for 03.07.2018`, async() => {

        let returnValue = await db.queryDb(sql, ['2018-07-03', 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let tulemus = Boolean(returnValue.data[0].tulemus);
        expect(tulemus).toBeTruthy();
    });
});