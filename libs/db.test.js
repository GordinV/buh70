'use strict';

const db = require('./db');
const result = {
    error_code: 0,
    result: null,
    error_message: null,
    data: []
}

describe('db query tests', () => {

    it('should return data', async() => {
        expect.assertions(4);
        let sqlString = 'SELECT $1::text as message',
            params = ['Hello world!'];

        let data =  await db.queryDb(sqlString,params);
        expect(data).toBeDefined();
        expect(data).toHaveProperty('error_code', 0);
        expect(data).toHaveProperty('result');
        expect(data).toHaveProperty('data');
    });

    it('test of wrong query', async() => {
        expect.assertions(3);
        let sqlString = 'SELECT a ',
            params = [];

        let data =  await db.queryDb(sqlString,params);
        expect(data).toBeDefined();
        expect(data).toHaveProperty('error_code', 9);
        expect(data).toHaveProperty('error_message');
    });

    it ('test of multiple query', async() => {
        expect.assertions(5);
        let sqlString = [`SELECT 'a' `, `SELECT 'b' `],
            params = [];

        let data =  await db.executeQueries(sqlString,params);
        expect(data).toBeDefined();
        expect(data[0]).toHaveProperty('error_code', 0);
        expect(data[0]).toHaveProperty('result', 1);
        expect(data[0]).toHaveProperty('data');
        expect(data[0].data.length).toBeGreaterThan(0);

    });

    it ('test of multiple query with object as return template', async() => {
        expect.assertions(5);
        let sqlString = [{sql:`SELECT 'a' `, alias:'rowA'}, {sql:`SELECT 'b' `, alias:'rowB'}],
            params = [],
            returnData = {
                rowA:{},
                rowB:{}
            };

        let data =  await db.executeQueries(sqlString,params, returnData);
        expect(data).toBeDefined();
        expect(data).toHaveProperty('rowA');
        expect(data.rowA.length).toBeGreaterThan(0);
        expect(data).toHaveProperty('rowB');
        expect(data.rowB.length).toBeGreaterThan(0);

    });

    it ('should prepaire sql string with sort and where', async()=> {
        let sqlString = 'SELECT $1::text as message',
            params = ['Hello world!'];

        let data =  await db.queryDb(sqlString,params, [{column: "1", direction: 'asc'}], "where message ilike '%'");
        expect(data).toBeDefined();
        expect(data).toHaveProperty('error_code', 0);

    })


});