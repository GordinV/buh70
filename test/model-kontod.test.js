'use strict';

const moduleLocator = require('./../libs/moduleLocator.js')();

describe('dok. type konto tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../models/libs/libraries/kontod'),
        docTypeId = 'kontod',
        DocDataObject = require('../models/documents');

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;

    it.skip(`${docTypeId} select New`, (done) => {
        DocDataObject.selectDoc(docTypeId, [globalDocId, 1], (err, data) => {

            expect(err).toBeNull();
            expect(data).toBeDefined();
            docData['data'] = data.row;
            docData['data']['rekvid'] = 1;
            docData['data']['kood'] = Math.random().toString();
            docData['data']['nimetus'] = 'Test konto';
            docData['data']['tyyp'] = '2';
            docData['data']['library'] = 'KONTOD';
            docData['data']['muud'] = 'test 123';
            docData['data']['valid'] ='2017-12-31';
            docData['details'] = [];


            done();
        });
    });

    it.skip(`${docTypeId}  validation`, () => {
        const requiredFields = doc.requiredFields;
        const validator = require('../frontend/mixin/validateForm');

        let warning = validator(null, requiredFields, docData['data']);
        expect(warning).toBeNull();
    });

    it.skip(`${docTypeId} unit save test`, (done) => {
        DocDataObject.saveDoc(docTypeId.toUpperCase(), [docData, 1, 1], (err, data) => {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data['rows'].length).toBeGreaterThan(0);
            expect(data['rows'][0].id).toBeGreaterThan(0);
            globalDocId = data['rows'][0].id;
            done();
        });
    });

    it.skip(`${docTypeId} select`, (done) => {
        DocDataObject.selectDoc(docTypeId.toUpperCase(), [globalDocId, 1], (err, data) => {
            expect(err).toBeNull();
            expect(data.row.id).toBeDefined();
            expect(data.row.id).toBe(globalDocId);
            expect(data.row.tyyp).toBe(2);
            done();
        });
    });

    it.skip(`${docTypeId} test for select (grid)`, (done) => {
        let results = {},
            user = {
                asutusId: 1,
                userId: 1
            };
        // callback, results, sortBy, dynamicWhere, user
        DocDataObject['docsGrid'].requery(docTypeId.toUpperCase(), (err, data) => {
            expect(err).toBeNull();
            expect(data.length).toBeGreaterThan(0);
            done();
        }, results, null, null, user);
    });

    it.skip(`${docTypeId} test for deleteTask`, (done) => {
        let sql = doc.deleteDoc;
        expect(sql).toBeDefined();
//        expect.hasAssertions();
        DocDataObject.executeSqlQuery(sql, [1, globalDocId], (err, data) => {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.rows[0].error_code).toBeNull();
            expect(data.rows[0].result).toBe(1);
            done();
        });
    });
});



