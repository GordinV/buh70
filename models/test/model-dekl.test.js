'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type Dekl tests', function () {
    let globalDocId = 0; // для сохранения ид документа
    let data = {
        id: 0, data: {
            number: 1,
            kpv: '2018-06-19',
            asutusid: 1,
            alus: 'test',
            lubaid: 294175,
            summa: 100,
            ettekirjutus:'test ette',
            tyyp:'DEKL',
            saadetud: '2018-06-19'
        }
    };

    const doc = require('../rekl/dekl'),
        docTypeId = 'DEKL'.toLowerCase(),
        modelForExport = 'rekl/dekl';

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
        expect(_.find(gridAlias.elements, {text: 'curReklDekl'})).toBeDefined();
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

    it('doc type library should contain DEKL doc.type', async () => {
        let sql = `select id from libs.library where kood = 'DEKL' and  library = 'DOK' limit 1`;
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

    it('select as new query', async () => {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0, 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);

    });

    it('should exists proc rekl.sp_salvesta_toiming', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_toiming'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


    it('should save data', async () => {

        let sql = doc.saveDoc;
        let returnValue = await db.queryDb(sql, [data, 1, 1]);
        expect(returnValue).toBeDefined();
        console.log(returnValue);
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);
        expect(returnValue.result).toBe(1);
        globalDocId  = returnValue.data[0].id;
        expect(returnValue.result).toBeGreaterThan(0);
        expect(globalDocId).toBeGreaterThan(0);
    });

    it('should select data ', async () => {
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [globalDocId, 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);
        expect(returnValue.data[0].id).toBe(globalDocId);

    });

    it('should exists view cur_toiming', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_toiming'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should select data as grid query', async () => {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });


    it('should exists proc sp_delete_toiming', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_delete_toiming'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists proc rekl.sp_calc_deklsumma', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_calc_deklsumma'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succesfully execute proc rekl.sp_calc_deklsumma', async () => {
        let sql = `select rekl.sp_calc_deklsumma($1, $2)::numeric as summa`;
        let returnValue = await db.queryDb(sql, [294175, '2018-06-30']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
        let summa = Number(returnValue.data[0].summa);
        expect(summa).toBeGreaterThan(0); //equal luba.summa
    });

    it('should exists proc rekl.get_deklstaatus', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'get_deklstaatus'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succesfully execute proc rekl.get_deklstaatus', async () => {
        let sql = `select rekl.get_deklstaatus($1, $2)::text as status`;
        let returnValue = await db.queryDb(sql, [globalDocId, '2018-06-30']);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc rekl.sp_saada_dekl', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_saada_dekl'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc rekl.gen_lausend_reklmaks', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'gen_lausend_reklmaks'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc rekl.sp_tasu_dekl', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_tasu_dekl'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc rekl.gen_lausend_rekltasu', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'gen_lausend_rekltasu'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc rekl.sp_recalc_rekl_jaak', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_recalc_rekl_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc rekl.sp_set_ettemaks_staatus', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_set_ettemaks_staatus'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succesfully execute proc rekl.sp_saada_dekl', async () => {
        let sql = `select * from rekl.sp_saada_dekl($1, $2)`;
        let params = {
            id: globalDocId,
            kpv:'2018-06-30'
        };
        let returnValue = await db.queryDb(sql, [1, params]);
        expect(returnValue).toBeDefined();
        console.log('rekl.sp_saada_dekl',returnValue);
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should delete toiming', async () => {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [1, globalDocId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


});

