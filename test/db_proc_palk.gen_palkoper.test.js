'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select * from palk.gen_palkoper($1::integer, $2::json)`;

describe('palk.gen_palkoper tests', () => {
    it (`called without or wriong user_id parameter`, async () => {
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
        let params = {leping_ids: [4]};

        let returnValue = await db.queryDb(sql, [1, params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(1);
    });

    it(` called with isik_ids  params`, async() => {
        let params = {isik_ids: [56]};

        let returnValue = await db.queryDb(sql, [1, params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(1);
    });

    it(` called with kas_kustuta  params`, async() => {
        let params = {kas_kustuta: true, isik_ids: [56]};

        let returnValue = await db.queryDb(sql, [1, params]); //$1 userId, $2 params::json
        expect(returnValue).toBeDefined();
        expect (returnValue.result).toBe(1);
    });

});