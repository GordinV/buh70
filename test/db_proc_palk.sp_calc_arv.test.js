'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select * from palk.sp_calc_arv(1, $1 :: json)`;

describe('palk.sp_calc_arv tests', () => {
    it(` should return result`, async() => {
        let params = {
            lepingid: 4,
            libid:  386,
            kpv: '2018-04-30'
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
//        let result = returnValue.result;
        expect (returnValue.error_code).toBe(null);

    });
    it(`alus_summa 100, should return 100`, async() => {
        let params = {
            alus_summa: 100
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        console.log(returnValue);
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        let sm = Number(returnValue.sm);
        let tki = Number(returnValue.tki);
        let tka = Number(returnValue.tka);
        let tm = Number(returnValue.tm);
        expect(summa).toBe(100);
        expect(sm).toBe(33);
        expect(tki).toBe(1.6);
        expect(tka).toBe(0.8);
        expect(tm).toBe(19.28);
    });
    it(`alus_summa 100, tululiik 13 should return tki = 0`, async() => {
        let params = {
            alus_summa: 100,
            tululiik:'13'
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let tki = Number(returnValue.tki);
        expect(tki).toBe(0);
    });
    it(`palk 1200, pk_summa = 100 (%), tunnid_kokku = 168 should return full arvestus va mvt`, async() => {
        let params = {
            palk: 1200,
            summa: 100,
            tunnid_kokku: 168,
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        let sm = Number(returnValue.sm);
        let tki = Number(returnValue.tki);
        let tka = Number(returnValue.tka);
        let pm = Number(returnValue.pm);
        let tm = Number(returnValue.tm);
        expect(summa).toBe(1200);
        expect(sm).toBe(396);
        expect(tki).toBe(19.2);
        expect(tka).toBe(9.6);
        expect(pm).toBe(24);
        expect(tm).toBe(231.36);
    });
    it(`palk 1200, pk_summa = 100 (%), tunnid_kokku = 168, without pm. should return full arvestus va mvt`, async() => {
        let params = {
            palk: 1200,
            summa: 100,
            tunnid_kokku: 168,
            pm_maksustav:0

    };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let pm = Number(returnValue.pm);
        expect(pm).toBe(0);
    });
    it(`palk 1200, is_percent = false should return palk = 1200`, async() => {
        let params = {
            palk: 1200,
            is_percent: false
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.summa);
        expect(summa).toBe(1200);
    });
    it(`without sm  should return sm = 0`, async() => {
        let params = {
            palk: 1200,
            is_percent: false,
            sm_maksustav: 0
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let sm = Number(returnValue.sm);
        expect(sm).toBe(0);
    });


});