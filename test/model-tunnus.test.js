'use strict';

const moduleLocator = require('./../libs/moduleLocator.js')();

describe('dok. type TUNNUS tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../models/libs/libraries/tunnus'),
        docTypeId = 'TUNNUS'.toLowerCase(),
        DocDataObject = require('../models/documents');

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;

    it(`${docTypeId} select New`, (done) => {
        DocDataObject.selectDoc(docTypeId, [globalDocId, 1], (err, data) => {

            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.row['doc_type_id']).toBe('TUNNUS');
            docData['data'] = data.row;
            docData['data']['rekvid'] = 1;
            docData['data']['kood'] = Math.random().toString();
            docData['data']['nimetus'] = 'Test tunnus';
            docData['data']['library'] = 'TUNNUS';
            done();
        });
    });

    it(`${docTypeId}  validation`, () => {
        const requiredFields = doc.requiredFields;
        const validator = require('../frontend/mixin/validateForm');

        let warning = validator(null, requiredFields, docData['data']);
        expect(warning).toBeNull();
    });

    it(`${docTypeId} unit save test`, (done) => {
        console.log('save test start');
        DocDataObject.saveDoc(docTypeId.toUpperCase(), [docData, 1, 1], (err, data) => {
            console.log('saving:', err, data);
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data['rows'].length).toBeGreaterThan(0);
            expect(data['rows'][0].id).toBeGreaterThan(0);
            globalDocId = data['rows'][0].id;
            console.log('saved:', globalDocId);
            done();
        });
    });

    it(`${docTypeId} select`, (done) => {
        DocDataObject.selectDoc(docTypeId.toUpperCase(), [globalDocId, 1], (err, data) => {
            expect(err).toBeNull();
            expect(data.row.id).toBeDefined();
            expect(data.row.id).toBe(globalDocId);
            done();
        });
    });

    it(`${docTypeId} test for select (grid)`, (done) => {
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

    it(`${docTypeId} test for deleteTask`, (done) => {
        let sql = doc.deleteDoc;
        expect(sql).toBeDefined();
        DocDataObject.executeSqlQuery(sql, [1, globalDocId], (err, data) => {

            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.rows[0].error_code).toBeNull();
            expect(data.rows[0].result).toBe(1);
            done();
        });
    });
});



