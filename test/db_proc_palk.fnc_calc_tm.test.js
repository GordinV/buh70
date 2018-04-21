'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select palk.fnc_calc_tm($1 ::NUMERIC, $2::NUMERIC, $3::NUMERIC, $4::NUMERIC,
                                            $5::TEXT)::numeric as summa`;

describe('palk.fnc_calc_tm tests', () => {
    it(` tulu = 1000, mvt = 500 should return TM = 100`, async () => {
        let returnValue = await db.queryDb(sql, [1000, 500, 0, 0, '10']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(100);
    });

    it(` tulu = 1000, mvt = 0 should return TM = 200`, async () => {
        let returnValue = await db.queryDb(sql, [1000, 0, 0, 0, '10']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(200);
    });

    it(` tulu = 1000, mvt = 0, tki = 1000 * 0.016, tm = 1000 * 0.02, should return TM = 192.8`, async () => {
        let returnValue = await db.queryDb(sql, [1000, 0, 16, 20, '10']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(192.80);
    });

    it(` tulu = 200, mvt = 500, tki = 200 * 0.016, tm = 200 * 0.02, should return TM = 0`, async () => {
        let returnValue = await db.queryDb(sql, [200, 500, 3.2, 4, '10']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(0);
    });

});