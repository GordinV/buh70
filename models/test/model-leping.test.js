'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type leping tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../raamatupidamine/leping'),
        docTypeId = 'LEPING'.toLowerCase(),
        modelForExport = 'raamatupidamine/leping';

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
        expect(doc.grid).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curLepingud'})).toBeDefined();
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

    it('doc type library should contain LEPING doc.type', async () => {
        let sql = `select id from libs.library where kood = 'LEPING' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_lepingud', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_lepingud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view wizlepingud', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'wizlepingud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succesfully execute view wizlepingud', async () => {
        let sql = _.find(doc.print,{alias:'wizlepingud'}).sql + ' limit 100';

        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });


    it('should select new data', async()=> {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0,1]);
        expect(returnValue).toBeDefined();
        console.log(sql, returnValue);
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });


    it('should exists proc docs.sp_salvesta_leping', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_leping'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should save data', async () => {
        let sql = doc.saveDoc;
        let data = {
            id: 0, data: {
                number: '001',
                kpv: '2018-08-10',
                tahtaeg: '2018-08-10',
                asutusid: 1,
                selgitus: 'test',
                gridData: [{
                    id: 0,
                    nomid: 2,
                    summa: 100,
                    hind: 100,
                    kbm: 0,
                    kogus: 1,
                    soodus: 0,
                    muud: 'Test'
                }]
            }
        };
        let returnValue = await db.queryDb(sql, [data,1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
        globalDocId = returnValue.data[0].id;
        expect(globalDocId).toBeGreaterThan(0);
    });

    it('should succesfully execute view cur_lepingud', async () => {
        let sql = doc.grid.sqlString + ' limit 100';
        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should select data', async()=> {
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [globalDocId,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should select griddata', async()=> {
        let sql = _.find(doc.select, {alias: 'details'}).sql;
        let returnValue = await db.queryDb(sql, [globalDocId,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc docs.sp_delete_leping', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_delete_leping'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should delete data', async()=> {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql,[1,globalDocId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

});

