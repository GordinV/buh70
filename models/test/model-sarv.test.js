'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type S-Arv tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../ladu/sarv'),
        docTypeId = 'SARV'.toLowerCase(),
        modelForExport = 'ladu/sarv';

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
        expect(doc.returnData).toBeDefined();
        expect(doc.requiredFields).toBeDefined();
        expect(doc.saveDoc).toBeDefined();
        expect(doc.deleteDoc).toBeDefined();
        expect(doc.register).toBeDefined();
        expect(doc.endProcess).toBeDefined();
        expect(doc.generateJournal).toBeDefined();
        expect(doc.grid).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'register'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'endProcess'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'grid'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curLaduArved'})).toBeDefined();

        let register = _.find(modelElements.elements, {name:'register'});
        expect(register).toBeDefined();
        expect(_.find(register.elements,{name:'alias'})).toBeDefined();
        let registerAlias = _.find(register.elements,{name:'alias'});
        expect(registerAlias).toBeDefined();
        let end = _.find(modelElements.elements, {name:'endProcess'});
        expect(end).toBeDefined();
        expect(_.find(end.elements,{name:'alias'})).toBeDefined();
        let endAlias = _.find(register.elements,{name:'alias'});
        expect(endAlias).toBeDefined();
        let generateJournal = _.find(modelElements.elements, {name:'generateJournal'});
        expect(generateJournal).toBeDefined();

    });

    it('should have copy in buh62 folder', (done) => {
        let targetFile =  path.join('C:\\avpsoft\\buh62\\models\\', modelForExport + '.xml');
        let copyFile =  path.join('C:\\avpsoft\\buh70\\models\\', modelForExport + '_copy.xml');
        expect(fs.existsSync(sourceFile)).toBeTruthy();
        fs.copyFileSync(sourceFile, copyFile);
        expect(fs.existsSync(copyFile)).toBeTruthy();

        fs.rename(copyFile, targetFile,(err) => {
            if (err) throw err;
            expect(fs.existsSync(targetFile)).toBeTruthy();
            done();
        });
    });

    it('doc type library should contain SARV doc.type', async()=> {
        let sql = `select id from libs.library where kood = 'SARV' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_teenused', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_teenused'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should successfully execute view cur_teenused', async() => {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure ladu.gen_lausend_sarv', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'gen_lausend_sarv'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure docs.create_new_mk', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'create_new_mk'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure docs.create_new_order', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'create_new_order'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure sp_tasu_arv', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_tasu_arv'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure docs.create_new_arve', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'create_new_arve'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure ladu.get_stock', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'get_stock'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });
    it('should succesfully call ladu.get_stock', async () => {
        let sql = `SELECT * FROM ladu.get_stock(current_date, 1, null, null)`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });
});

