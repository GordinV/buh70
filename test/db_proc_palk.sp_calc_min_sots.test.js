'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select * from palk.sp_calc_min_sots($1::integer, $2::json)`;

describe('palk.sp_calc_min_sots tests', () => {
    it (`called without or wrong user_id parameter`, async () => {
        let params = null;

        let returnValue = await db.queryDb(sql, [null,params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(0);
        expect (returnValue.error_code).toBe(5); //vale parametrid

    });

    it(` called without params`, async() => {
        let params = null;

        let returnValue = await db.queryDb(sql, [1,params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(0);
        expect (returnValue.error_code).toBe(6); //vale parametrid
    });

    it(` called with lepingid  params`, async() => {
        let l_kpv = new Date(2018,5,31);
        let params = {lepingid: 4, kpv: l_kpv};

        let returnValue = await db.queryDb(sql, [1, params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();

        console.log(returnValue);
        let summa = Number(returnValue.summa),
            alus = Number(returnValue.alus);

        expect (returnValue.result).toBe(1);
        expect (summa).toBe(141.9);
        expect (alus).toBe(430);
    });


});