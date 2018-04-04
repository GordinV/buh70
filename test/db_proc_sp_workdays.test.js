'use strict';

const db = require('./../libs/db');
const async = require('async');
let tulemus;
let sql = `SELECT sp_workdays($1 :: JSONB)::integer as days`;

describe('sp_workdays tests', () => {
    it(` called without params`, async() => {
        let params = {};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let days = returnValue.data[0].days;
        expect(days).toBeLessThan(23);
    });

    it(` called with lepingid (should be checked toograf) params`, async() => {
        let params = {lepingid: 2};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let days = returnValue.data[0].days;
        expect(days).toBeLessThan(23);
    });

    it(` called with month and year and lepingid (should be checked toograf) params`, async() => {
        let params = {lepingid: 2, kuu: 4, aasta: 2018};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let days = returnValue.data[0].days;
        expect(days).toBeLessThan(23);
        tulemus = days;
    });

    it(` called with month and year, day start and day finished and lepingid (should be checked toograf) params`, async() => {
        let params = {lepingid: 2, kuu: 4, aasta: 2018, paev: 3, lopp: 20};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let days = returnValue.data[0].days;
        expect(days).toBeLessThan(tulemus);
    });
});