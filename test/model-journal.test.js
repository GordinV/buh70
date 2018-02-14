'use strict';

describe('dok. type JOURNAL tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../models/raamatupidamine/journal'),
        docTypeId = 'journal',
        DocDataObject = require('../models/documents');

    let docData = doc.returnData;

    it.skip(`${docTypeId} select New`, (done) => {
        DocDataObject.selectDoc(docTypeId, [globalDocId, 1], (err, data) => {
            expect(err).toBeNull();
            expect(data).toBeDefined();
            docData['data'] = data.row;
            docData.details = [{id: 0, deebet:'100', kreedit:'221', summa: 10}];
            docData.bpm = null;
            docData['data']['rekvid'] = 1;
            docData['data']['summa'] = 10;
            docData['data']['doc_status'] = 0;
            docData['data']['selg'] = 'journal test';
            docData['data']['asutusid'] = 1;
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
            console.log('step', step.action);
            taskParams.params['tasks'] = [step.action];
            DocDataObject.executeTask(docTypeId, taskParams, (err, data) => {
                expect(err).toBeNull();
                expect(data).toBeDefined();
            });
        });
    });

    it.skip(`${docTypeId} test for deleteTask`, (done) => {
        let sql = doc.deleteDoc;

        expect(sql).toBeDefined();
//        expect.hasAssertions();
        DocDataObject.executeSqlQuery(sql, [1, globalDocId], (err, data) => {
            console.log('received data', data);
            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.rows[0].result).toBe(1);
            done();
        });
        done();
    });

    it.skip(`${docTypeId} test for deleteTask Promise`, done => {
        let sql = doc.deleteDoc;

        expect(sql).toBeDefined();
        expect.hasAssertions();
        DocDataObject.executeSqlQueryPromise(sql, [1, globalDocId]).then(data => {
            expect(data).toBeDefined();
            expect(data[0].error_code).toBeNull();
            expect(data[0].result).toBe(1);
            done();
        });
        done();
    });


    /*


     it('ARV executeAutomateTask', function (done) {
     // созданим для теста новый док
     let promise = Promise.resolve(),
     DocDataObject = require('../models/documents'),
     taskParams = {
     params: {
     tasks: ['start'],
     docId: globalDocId,
     },
     userId: 1
     };


     promise.then(() =>
     saveArv().then((result) => {
     globalDocId = result;
     return result;
     })
     .then((newDocId) => {
     console.log('After saving got new doc id:', newDocId);
     return DocDataObject.executeAutomateTask('arv', taskParams)
     })
     .then((result) => {
     console.log('got result:', result);
     done();
     })
     ), ((err) => {
     throw new Error('Ошибка ARV executeAutomateTask');
     })

     })

     it('Dokprop test (ARV) select', function (done) {
     let DocDataObject = require('../models/documents'),
     promise = Promise.resolve();

     promise
     .then(
     DocDataObject.selectDocPromise('dokProps', ['ARV', 1])
     .then(
     done()
     )
     ).catch((err) => {
     throw new Error('Error in  selectDocPromise')
     })

     });
     */
});
