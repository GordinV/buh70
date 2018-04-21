'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select palk.fnc_calc_mvt($1 :: jsonb)::numeric as summa`;

describe('palk.fnc_calc_mvt tests', () => {
    it(` tulu = 1000 should return MVT = 0`, async () => {
        let params = {summa: 1000};
        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(0);
    });

    it(` tulu = 1000, mvt_kokku = 500 should return MVT = 500`, async () => {
        let params = {summa: 1000, mvt_kokku: 500};
        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(500);
    });

    it(` tulu = 1000, mvt_kokku = 500, kasutatud MVT = 300 should return MVT = 200`, async () => {
        let params = {
            summa: 1000,
            mvt_kokku: 500,
            kokku_kasutatud_mvt: 300
        };
        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(200);
    });
    it(`tulu < 500 and maksud, should return tulu - maksud`, async () => {
        let params = {
            summa: 200,
            mvt_kokku: 500,
            tki: 3.2,
            pm:4
        };
        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(192.8);
    });


});