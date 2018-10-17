'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `SELECT palk.get_days_of_month_in_period($1::integer, $2::integer, $3::date, $4::date) as tulemus`; //$1 - kuu, $2 - aasta, $3 - kpv1, $4 - kpv2

describe('get_days_of_month_in_period', () => {
    it('should exists function',async()=>{
        let l_sql = `select 1 FROM pg_proc WHERE proname = 'get_days_of_month_in_period'`;
        let returnValue = await db.queryDb(l_sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it(` should return 31 for jan.2018`, async() => {

        let returnValue = await db.queryDb(sql, [1, 2018,'2018-01-01', '2018-01-31']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        expect (returnValue.data[0].tulemus).toBe(31);
    });

    it(` should return 0 for jan. 2018, because of period is in veb. 2018`, async() => {

        let returnValue = await db.queryDb(sql, [2, 2018,'2018-01-01', '2018-01-31']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        expect (returnValue.data[0].tulemus).toBe(0);
    });
});