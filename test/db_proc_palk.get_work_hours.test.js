'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `select palk.get_work_hours($1 :: JSONB)::numeric as summa`;
let tunnid = 0;

describe('palk.get_work_hours tests', () => {
    it(` should return result from toograafik`, async() => {
        let params = {
            lepingid: 4,
            kpv: new Date(),
            libid: 386
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBeGreaterThan(0);
    });

    it(` should return kuu result`, async() => {
        let params;

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        tunnid = Number(returnValue.data[0].summa);
        expect(tunnid).toBeGreaterThan(0);
    });

    it(` call with paev, should return result < tunnid`, async() => {
        let params = {
            lepingid: 4,
            kpv: new Date(),
            paev: 10
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBeLessThan(tunnid);
    });

    it(` call with lõpppaev, should return result < tunnid`, async() => {
        let params = {
            lopp: 20
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBeLessThan(tunnid);
    });

    it(` call with tööpaev, should return result = tunnid / 2`, async() => {
        let params = {
            kpv: new Date(),
            toopaev: 4
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(tunnid / 2);
    });
});