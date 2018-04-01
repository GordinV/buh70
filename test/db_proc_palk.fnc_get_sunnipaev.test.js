'use strict';

const db = require('./../libs/db');
const async = require('async');

let sql = `select * from palk.fnc_get_sunnipaev ($1, $2)`; //$1  - user_id $2 - json params,

describe('palk.fnc_get_sunnipaev tests', () => {
    let userId = 1;
    let params = {
        isikukood: '37303023721'
    };

    it(` called sql`, async() => {
        let returnValue = await db.queryDb(sql, [userId,params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(45);
        expect(returnValue.error_message).toBeNull();
    });
});