'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `select palk.sp_calc_kinni($1 :: JSONB)::integer as summa`;

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

});