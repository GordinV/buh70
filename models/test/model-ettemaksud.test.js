'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');


describe('dok. type Luba tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../rekl/ettemaksud'),
        docTypeId = 'ETTEMAKSUD'.toLowerCase(),
        modelForExport = 'rekl/ettemaksud';

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;
    let xml;
    let sourceFile;

    it(`${docTypeId} create XML model`, (done) => {
        //create model
        modelCreator(modelForExport, (err, xmlFile) => {
            sourceFile = xmlFile;
            xml = fs.readFileSync(xmlFile, 'utf8');
            expect(err).toBeNull();
            expect(xmlFile).toBeDefined();
            expect(fs.existsSync(xmlFile)).toBeTruthy();
            done();
        })
    });

    it(`${docTypeId} must have fields in js model`, () => {
        expect(doc.select).toBeDefined();
        expect(doc.returnData).toBeDefined();
        expect(doc.requiredFields).toBeDefined();
        expect(doc.saveDoc).toBeDefined();
        expect(doc.deleteDoc).toBeDefined();
//        expect(doc.register).toBeDefined();
//        expect(doc.endProcess).toBeDefined();
        expect(doc.grid).toBeDefined();
        expect(doc.executeCommand).toBeDefined();
    });

    it(`${docTypeId} must have fields in xml model`, () => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name: 'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'deleteDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'grid'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name: 'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements, {name: 'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements, {name: 'alias'});
        expect(_.find(gridAlias.elements, {text: 'curEttemaksud'})).toBeDefined();
        let executeCommand = _.find(modelElements.elements, {name: 'executeCommand'});
        expect(executeCommand).toBeDefined();

    });

    it('should have copy in buh62 folder', (done) => {
        let targetFile = path.join('C:\\avpsoft\\buh62\\models\\', modelForExport + '.xml');
        let copyFile = path.join('C:\\avpsoft\\buh70\\models\\', modelForExport + '_copy.xml');
        expect(fs.existsSync(sourceFile)).toBeTruthy();
        fs.copyFileSync(sourceFile, copyFile);
        expect(fs.existsSync(copyFile)).toBeTruthy();

        fs.rename(copyFile, targetFile, (err) => {
            if (err) throw err;
            expect(fs.existsSync(targetFile)).toBeTruthy();
            done();
        });
    });

    it('doc type library should contain ETTEMAKSUD doc.type', async () => {
        let sql = `select id from libs.library where kood = 'ETTEMAKSUD' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('select as new query', async () => {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0, 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);

    });

    it('select as exists query', async () => {
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [1, 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);

    });

    it('should exists view rekl.cur_ettemaksud', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_ettemaksud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


    it('should execute grid sql string from model', async () => {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, [1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.error_code;
        expect(result).toBe(0);

    });

    it('should exists proc rekl.sp_salvesta_ettemaksud', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_ettemaksud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


    it('should save data', async () => {
        let data = {
            id: 0, data: {
                number: '001',
                kpv: '2018-06-26',
                asutusid: 1,
                selg: 'test',
                summa: 99
            }
        };

        let sql = doc.saveDoc;
        let returnValue = await db.queryDb(sql, [data, 1, 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);
        expect(returnValue.result).toBe(1);
        globalDocId = returnValue.data[0].id;
        expect(returnValue.result).toBeGreaterThan(0);
    });


    it('should return result from view rekl.cur_ettemaksud', async () => {
        let sql = `select * FROM cur_ettemaksud`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.error_code;
        expect(result).toBe(0);

    });

    it('should exists proc rekl.sp_delete_ettemaksud', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_delete_ettemaksud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should delete ettemaks', async () => {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [1, globalDocId]);
        expect(returnValue).toBeDefined();
        console.log('deleted',returnValue);
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });
});

