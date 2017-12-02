'use strict';

describe('model dok. type VORDER tests', function () {
    let globalDocId = 0; // для сохранения ид документа
    const doc = require('../models/raamatupidamine/vorder'),
        docTypeId = 'vorder',
        DocDataObject = require('../models/documents');

    let docData = doc.returnData;

    it('VORDER select New', (done) => {
        DocDataObject.selectDoc(docTypeId, [globalDocId, 1], (err, data)=> {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            docData['data'] = data.row;
            docData.details = [{id: 0, nomid: 1, summa: 10}];
            docData.bpm = null;
            docData['data']['rekvid'] = 1;
            docData['data']['lisa'] = 'test';
            docData['data']['summa'] = 10;
            docData['data']['doc_status'] = 0;
            docData['data']['nimi'] = 'nimi';
            docData['data']['asutusid'] = 1;
            done();
        })
    });

    it('VOrder validation',()=> {
        const requiredFields = doc.requiredFields;
        const validator = require('../frontend/mixin/validateForm');

        let data = docData['data'],
            warning = validator(null, requiredFields, docData['data']);
        expect(warning).toBeNull();

    });

    it('VORDER unit save test', (done) => {
        DocDataObject.saveDoc(docTypeId.toUpperCase(), [docData, 1, 1], (err, data) => {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data['rows'].length).toBeGreaterThan(0);
            expect(data['rows'][0].id).toBeGreaterThan(0);
            globalDocId = data['rows'][0].id;
            done();
        });
    });

    it('VORDER test for select (grid)', (done) => {
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

    it('VORDER test for select', (done) => {
        DocDataObject.selectDoc(docTypeId.toUpperCase(), [globalDocId, 1], (err, data)=> {
            expect(err).toBeNull();
            expect(data.row.id).toBeDefined();
            expect(data.row.id).toBe(globalDocId);
            done();
        });
    });

    it.skip(`${docTypeId} bpm test`, () => {
        let taskParams = {
            params: {
                tasks: [],
                docId: globalDocId,
            },
            userId: 1
        };

        let bpm = doc.bpm;

        bpm.forEach(step => {
            taskParams.params['tasks'] = [step.action];
            DocDataObject.executeTask(docTypeId, taskParams, (err, data) => {
                expect(err).toBeNull();
                expect(data).toBeDefined();
            });
        });
    })

    it('VORDER test for deleteTask', (done)=> {
        let sql = doc.deleteDoc;

        DocDataObject.executeSqlQuery(sql, [1, globalDocId], (err, data) => {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.rows[0].error_code).toBeNull();
            expect(data.rows[0].result).toBe(1);

            done();
        });

    })

});

