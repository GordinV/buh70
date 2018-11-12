'use strict';

const db = require('./../libs/db');
const async = require('async');
let sql = `select * from docs.fnc_calc_viivised($1 :: json)`;

describe('docs.fnc_calc_viivise tests', () => {
    it(` should return result`, async() => {
        let params = {
            summa: 100,
            viivise_maar: 0.10,
            tahtaeg: '2018-10-31',
            kpv: '2018-11-10'};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let is_error = returnValue.error_code ? 1: 0;
       expect (returnValue.error_code).toBe(is_error);

    });
    it(`интресс должен быть 0 так как долга нет`, async() => {
        let params = {
            summa: 100,
            viivise_maar: 0.10,
            tahtaeg: '2018-11-30',
            kpv: '2018-11-10'};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(0);
    });

    it(`сумма счета 46.04, срок оплаты 31.10.2018 оплат нет`, async() => {
        let params = {
            summa: 46.04,
            viivise_maar: 0.10,
            tahtaeg: '2018-10-31',
            kpv: '2018-11-10'};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let intress = Number(returnValue.data[0].summa);
        expect(intress).toBe(0.46);
    });
    it(`Счет оплачен, но позже`, async() => {
        let params = {
            summa: 209.60,
            viivise_maar: 0.10,
            tahtaeg: '2014-11-30',
            kpv: '2018-11-10',
        tasud: [{kpv: '2014-12-04',summa:209.60}]
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(0.84);
    });
    it(`оплат нет, оплата равна null`, async() => {
        let params = {
            summa: 46.04,
            viivise_maar: 0.10,
            tahtaeg: '2018-10-31',
            tasud: null,
            kpv: '2018-11-10'};

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let intress = Number(returnValue.data[0].summa);
        expect(intress).toBe(0.46);
    });

    it(`Несколько платежей`, async() => {
        let params = {
            summa: 69.31,
            viivise_maar: 0.10,
            tahtaeg: '20180930',
            kpv: '20181101',
            tasud: [{kpv: '20180912',summa:56.95}, {kpv: '20181015',summa:12.36}]
        };

        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect (result).toBe(1);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBe(0.19);
    });
});