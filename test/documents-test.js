'use strict';
require('babel-polyfill');
const _ = require('lodash');

describe('SQL functions tests', function () {
    const Doc = require('../models/documents');
    const pg = require('pg');

    it('connectDb check connection to PostgreSQL', (done) => {
        let db = Doc.connectDb();
        let isInstanceOf = db instanceof pg.Client;

        // disconnect
        db.end((err) => {
            if (err) throw err;
        });

        if (isInstanceOf) {
            done()
        }
    });

    it('executeSqlQueryPromise  will execute sql query and retirn it', (done) => {
        let sql = 'select 1 as num',
            params,
            returnData = {
                data: []
            };

        Doc.executeSqlQueryPromise(sql, params)
            .then((data) => {
                if (data) {
                    done()
                }
                ((err) => {
                    console.error('viga:', err);
                    throw new Error('Error in  DocDataObject.executeSqlQueryPromise');
                });

            });
    });

    it ('executeSqlQuery',(done)=> {
        // sqlString, sqlParams, callback
        let sql = 'select 1 as num',
            params,
            returnData = {
                data: []
            };

        Doc.executeSqlQuery(sql, params, (err, data)=> {
            if (err) {
                console.error('viga:', err);
                throw new Error('Error in  Doc.executeSqlQuery');
            }

            if (data.rows && data.rows.length > 0) {
                done();
            } else {
                throw new Error('Result is empty, should be 1 row');
            }

        });

    }) ;

    it ('executeSqlQueries', (done)=> {
        //function (sqls, params, returnData, callback)
        // sqls массив запрсов, структура [{sql:'', sqlAsNew:'', alias: 'row', multiple:true || false}]
        let sqls = [{sql: 'select 1 as num', alias: 'row1', multiple: false},
                {sql: 'select 2 as num', alias: 'row2', multiple: true}
            ],
            params,
            returnData = {
                row1: {},
                row2: []
            };

        Doc.executeSqlQueries(sqls, params, returnData, (err, data) => {
            if (err) {
                console.error('viga:', err);
                throw new Error('Error in  Doc.executeSqlQueries');
            }
            let returnedNum = data.row1.num;
            if (data && data.row1.num == 1 && data.row2.length === 1 && data.row2[0].num == 2) {
                // проверим содержимое результата
                    done();
            } else {
                throw new Error('Result is empty, or contain wrong data');
            }

        })
    });

    it ('selectDoc',(done) => {
        //docTypeId, params, callback
        let params =  [1, 195];


        Doc.selectDoc('ARV', params, (err, data)=> {
            if (err) {
                console.error('viga:', err);
                throw new Error('Error in Doc.selectDoc');
            }

            console.log('data', data);
            if (data ) {
                // проверим содержимое результата
                let Model = require('../models/raamatupidamine/arv'),
                    returnData  = Model.returnData;

                 if ( _.isEqual( _.keys(returnData), _.keys(data))) {
                     done();
                 }
            } else {
                throw new Error('Result is empty, or contain wrong data');
            }

        });
    });

/*
    it('executeSqlQueriesPromise, will execute multiply queries', (done) => {
        // sqls массив запрсов, структура [{sql:'', sqlAsNew:'', alias: 'row', multiple:true || false}]
        let sqls = [{sql: 'select 1 as num', alias: 'row1', multiple: false},
                {sql: 'select 2 as num', alias: 'row2', multiple: true}
            ],
            params,
            returnData = {
                row1: {},
                row2: []
            }

        Doc.executeSqlQueriesPromise(sqls, params, returnData)
            .then((data) => {
                console.log('data', data);
                if (data) done();
            })
            ((err) => {
                console.error('viga:', err);
                throw new Error('Error in  DocDataObject.executeSqlQueryPromise');
            });

    })
*/

})
