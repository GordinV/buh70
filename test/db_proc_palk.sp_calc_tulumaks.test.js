'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `select * from palk.sp_calc_tulumaks(1, $1 :: JSON)`;

describe('palk.palk.sp_calc_tulumaks tests', () => {
    it(` should return 0 result`, async() => {
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

    it(` call with alus summa, should return result = 20`, async() => {
        let params = {
            lepingid: 4,
            kpv: new Date(),
            libid: 386,
            summa: 20,
            alus_summa:100
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(20);
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

    it(` call with mvt, should return result = 100`, async() => {
        let params = {
            alus_summa: 1000,
            is_percent: true,
            mvt: 500
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(100);
    });
    it(` call with mvt and tki and pm, should return result = 92.8`, async() => {
        let params = {
            alus_summa: 1000,
            is_percent: true,
            mvt: 500,
            kulud:36
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(92.8);
    });
});