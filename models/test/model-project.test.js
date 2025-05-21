'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const doc = require("../libs/libraries/project");


describe('dok. type PROJECT tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../libs/libraries/project'),
        docTypeId = 'PROJECT'.toLowerCase(),
        modelForExport = 'libs/libraries/project',
        DocDataObject = require('../documents');

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;

    let xml;
    let sourceFile;

    it (`${docTypeId} create XML model`, (done)=> {
        //create model
        modelCreator(modelForExport,(err, xmlFile) => {
            sourceFile = xmlFile;
            xml = fs.readFileSync(xmlFile   , 'utf8');
            expect(err).toBeNull();
            expect(xmlFile).toBeDefined();
            expect(fs.existsSync(xmlFile)).toBeTruthy();
            done();
        })
    });

    it (`${docTypeId} must have fields in js model`, ()=> {
        expect(doc.select).toBeDefined();
        expect(doc.selectAsLibs).toBeDefined();
        expect(doc.returnData).toBeDefined();
        expect(doc.requiredFields).toBeDefined();
        expect(doc.saveDoc).toBeDefined();
        expect(doc.deleteDoc).toBeDefined();
        expect(doc.grid).toBeDefined();
    });

    it('should have copy in buh62 folder', (done) => {
        let targetFile = path.join('C:\\development\\buh62\\models\\', modelForExport + '.xml');
        let copyFile = path.join('C:\\development\\buh70\\models\\', modelForExport + '_copy.xml');
        expect(fs.existsSync(sourceFile)).toBeTruthy();
        fs.copyFileSync(sourceFile, copyFile);
        expect(fs.existsSync(copyFile)).toBeTruthy();

        fs.rename(copyFile, targetFile, (err) => {
            if (err) throw err;
            expect(fs.existsSync(targetFile)).toBeTruthy();
            done();
        });
    });


    it.skip(`${docTypeId} select New`, (done) => {
        DocDataObject.selectDoc(docTypeId, [globalDocId, 1], (err, data) => {

            expect(err).toBeNull();
            expect(data).toBeDefined();
            expect(data.row['doc_type_id']).toBe('PROJECT');
            docData['data'] = data.row;
            docData['data']['rekvid'] = 1;
            docData['data']['kood'] = Math.random().toString();
            docData['data']['nimetus'] = 'Test project';
            docData['data']['library'] = 'PROJ';
            done();
        });
    });

    it.skip(`${docTypeId}  validation`, () => {
        const requiredFields = doc.requiredFields;
        const validator = require('../../frontend/mixin/validateForm');

        let warning = validator(null, requiredFields, docData['data']);
        expect(warning).toBeNull();
    });

    it.skip(`${docTypeId} unit save test`, (done) => {
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

    it.skip(`${docTypeId} test for deleteTask`, (done) => {
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



