'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `select palk.get_puudumine($1 :: JSONB)::integer as days`;

describe('palk.get_puudumine tests', () => {
    it(` called without params`, async() => {
        let params = {};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let days = returnValue.data[0].days;
        expect(days).toBe(0);
    });

    it(` called with month and year, day start and day finished and lepingid (should be checked toograf) params`, async() => {
        let params = {lepingid: 4, kuu: 4, aasta: 2018, paev: 3, lopp: 20, pohjus: 'PUHKUS'};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let days = returnValue.data[0].days;
        expect(days).toBeGreaterThan(0);
        expect(days).toBeLessThan(31);
    });
});