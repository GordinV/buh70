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

    const doc = require('../rekl/luba'),
        docTypeId = 'LUBA'.toLowerCase(),
        modelForExport = 'rekl/luba';

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
        expect(_.find(modelElements.elements, {name: 'generateJournal'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name: 'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements, {name: 'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements, {name: 'alias'});
        expect(_.find(gridAlias.elements, {text: 'curReklLuba'})).toBeDefined();
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

    it('doc type library should contain LUBA doc.type', async () => {
        let sql = `select id from libs.library where kood = 'LUBA' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view rekl.dekl_jaak', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'dekl_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_luba', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_luba'`;
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

    it('should exists proc sp_salvesta_luba', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_luba'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


    it('should save data', async () => {
        let data = {
            id: 0, data: {
                number: '001',
                algkpv: '2018-06-17',
                loppkpv: '2018-06-17',
                asutusid: 1,
                alus: 'test',
                kord: 'KUU',
                gridData: [{
                    id: 0,
                    nomid: 2,
                    summa: 100,
                    maksumaar: 10,
                    kogus: 1,
                    soodus_tyyp: 0,
                    soodus: 0,
                    staatus: 1
                }]
            }
        };

        let sql = doc.saveDoc;
        let returnValue = await db.queryDb(sql, [data, 1, 1]);
        expect(returnValue).toBeDefined();
        console.log(returnValue);
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);
        expect(returnValue.result).toBe(1);
        globalDocId  = returnValue.data[0].id;
        expect(returnValue.result).toBeGreaterThan(0);
    });


    it('should exists proc rekl.sp_muuda_lubastaatus', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_muuda_lubastaatus'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should change luba status', async () => {
        let sql = doc.executeCommand.command;
        let params = {id: globalDocId, staatus: 2};
        let returnValue = await db.queryDb(sql, [1, params, 'rekl.sp_muuda_lubastaatus']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let error = returnValue.error_code;
        expect(error).toBeGreaterThan(0);
        expect(result).toBe(0);
        params = {id: globalDocId, staatus: 1};
        returnValue = await db.queryDb(sql, [1, params,'rekl.sp_muuda_lubastaatus']);
        result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


    it('should exists proc rekl.sp_recalc_rekl_jaak', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_recalc_rekl_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succesfully execute proc rekl.sp_recalc_rekl_jaak', async () => {
        let sql = doc.executeCommand.command;
        let params = {id: globalDocId};
        let returnValue = await db.queryDb(sql, [1, params, 'rekl.sp_recalc_rekl_jaak']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let error = returnValue.error_code;
        expect(result).toBe(1);
    });

    it('should exists proc rekl.sp_koosta_pikendus', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_koosta_pikendus'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succesfully execute proc rekl.sp_koosta_pikendus', async () => {
        let sql = doc.executeCommand.command;
        let params = {id: globalDocId, kpv: '2018-12-31'};
        let returnValue = await db.queryDb(sql, [1, params, 'rekl.sp_koosta_pikendus']);
        expect(returnValue).toBeDefined();
        console.log('rekl.sp_koosta_pikendus', globalDocId, returnValue);
        let result = returnValue.result;
        let error = returnValue.error_code;
        expect(result).toBeGreaterThan(1);
    });

    it('should exists proc rekl.sp_calc_dekl', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_calc_dekl'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succesfully execute proc rekl.sp_calc_dekl', async () => {
        let sql = `select rekl.sp_calc_dekl($1,$2) as result`;
        let returnValue = await db.queryDb(sql, [globalDocId,1]);
        expect(returnValue).toBeDefined();
        console.log('rekl.sp_calc_dekl', globalDocId, returnValue);
        let result = returnValue.result;
        let error = returnValue.error_code;
        expect(result).toBeGreaterThan(0);
    });


    it('should exists proc rekl.sp_luba_annuleri', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_luba_annuleri'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succesfully execute proc rekl.sp_luba_annuleri', async () => {
        let sql = doc.executeCommand.command;
        let params = {id: globalDocId};
        let returnValue = await db.queryDb(sql, [1, params, 'rekl.sp_luba_annuleri']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let error = returnValue.error_code;
        expect(result).toBe(1);
    });


    it('should exists proc sp_delete_luba', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_delete_luba'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should delete luba', async () => {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [1, globalDocId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let err = returnValue.error_code;
        expect(err).toBe(3); // ei saa

    });


});

