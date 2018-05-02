'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `select * from palk.sp_calc_sots(1, $1 :: JSON)`;

describe('palk.palk.sp_calc_sots tests', () => {
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
        let summa = Number(returnValue.summa);
        expect(summa).toBe(0);
    });

    it(` call with alus summa, should return result = 33`, async() => {
        let params = {
            lepingid: 4,
            kpv: new Date(),
            libid: 386,
            summa: 33,
            alus_summa:100
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(33);
    });

    it(` call with pk fixed summa, should return result = 100`, async() => {
        let params = {
            lepingid: 4,
            kpv: new Date(),
            libid: 386,
            summa: 100,
            alus_summa: 0,
            is_percent: false
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(100);
    });

    it(` call with min_sotsmaks, should return result = 470 * 0.33 = 155.10`, async() => {
        let params = {
            summa: 33,
            alus_summa: 100,
            is_percent: true,
            minsots: 1
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(155.1);
    });
});