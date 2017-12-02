'use strict';

describe('dok. type asutus tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../models/libs/libraries/asutused'),
        docTypeId = 'asutused',
        DocDataObject = require('../models/documents');

    let docData = doc.returnData;

    it(`${docTypeId} select New`, (done) => {
        DocDataObject.selectDoc(docTypeId, [globalDocId, 1], (err, data) => {
            console.log('select New', err, data);

            expect(err).toBeNull();
            expect(data).toBeDefined();
            docData['data'] = data.row;
            docData['data']['rekvid'] = 1;
            docData['data']['regkood'] = '123456789';
            docData['data']['nimetus'] = 'Test asutus';
            docData['data']['omvorm'] = 'FIE';
            docData['data']['email'] = 'vladislav.gordin@gmail.com';
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
        DocDataObject.saveDoc(docTypeId.toUpperCase(), [docData, 1, 1], (err, data) => {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data['rows'].length).toBeGreaterThan(0);
            expect(data['rows'][0].id).toBeGreaterThan(0);
            globalDocId = data['rows'][0].id;
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
//        expect.hasAssertions();
        DocDataObject.executeSqlQuery(sql, [1, globalDocId], (err, data) => {
            console.log('received globalDocId, data',globalDocId,  data);

            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.rows[0].error_code).toBeNull();
            expect(data.rows[0].result).toBe(1);
            done();
        });
    });
});
