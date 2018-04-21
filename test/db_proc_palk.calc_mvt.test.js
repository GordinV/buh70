'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select palk.calc_mvt($1 :: numeric, $2::numeric)::numeric as summa`;

describe('palk.calc_mvt tests', () => {
    it(` tulu = 1200, mvt = 500 should return 500`, async() => {

        let returnValue = await db.queryDb(sql, [1200, 500]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(500);
    });
    it(` tulu = 1200, mvt = 0 should return 0`, async() => {

        let returnValue = await db.queryDb(sql, [1200,0]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(0);
    });
    it(` tulu = 2000, mvt = 500 should return 55.56`, async() => {

        let returnValue = await db.queryDb(sql, [2000,500]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(55.56);
    });
    it(` tulu = 200, mvt = 500 should return 200`, async() => {

        let returnValue = await db.queryDb(sql, [200,500]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(200);
    });

});