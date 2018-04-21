'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select palk.sp_calc_muuda($1 :: JSONB)::integer as summa`;

describe('palk.palk.sp_calc_kinni tests', () => {
    it(` should return result`, async() => {
        let params = {
            lepingid: 4,
            kpv: new Date(),
            libid: 386
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = returnValue.data[0].summa;
        expect(summa).toBe(0);
    });

    it(` call with alus summa and % = 3, should return result = 100 * 0.03`, async() => {
        let params = {
            alus_summa: 100,
            summa: 3
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(3);
    });

    it(` call with fixed alus summa, should return result = 100`, async() => {
        let params = {
            alus_summa: 0,
            is_percent: false,
            summa: 100
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(100);
    });

});