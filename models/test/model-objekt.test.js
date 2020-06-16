'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type Objekt tests', function () {
    let globalDocId = 0; // для сохранения ид документа
    let dataObject = {}; // глобальный объект с данными документа

    const doc = require('../libs/libraries/objekt'),
        docTypeId = 'OBJEKT'.toLowerCase(),
        modelForExport = 'libs/libraries/objekt';

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

    it.skip (`${docTypeId} must have fields in js model`, ()=> {
//        expect(doc.selectAsLibs).toBeDefined();
//        expect(doc.select).toBeDefined();
//        expect(doc.returnData).toBeDefined();
//        expect(doc.requiredFields).toBeDefined();
//        expect(doc.saveDoc).toBeDefined();
//        expect(doc.deleteDoc).toBeDefined();
        expect(doc.grid).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
//        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
//        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
//        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curObjekt'})).toBeDefined();
//        expect(_.find(modelElements.elements, {name:'selectAsLibs'})).toBeDefined();
    });

    it('should have copy in buh62 folder', (done) => {
        let targetFile =  path.join('C:\\development\\buh62\\models\\', modelForExport + '.xml');
        let copyFile =  path.join('C:\\development\\buh70\\models\\', modelForExport + '_copy.xml');
        expect(fs.existsSync(sourceFile)).toBeTruthy();
        fs.copyFileSync(sourceFile, copyFile);
        expect(fs.existsSync(copyFile)).toBeTruthy();

        fs.rename(copyFile, targetFile,(err) => {
            if (err) throw err;
            expect(fs.existsSync(targetFile)).toBeTruthy();
            done();
        });
    });

    it('doc type library should contain OBJEKT doc.type', async () => {
        let sql = `select id from libs.library where kood = 'OBJEKT' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists view com_objekt', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'com_objekt'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_objekt', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_objekt'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should successfully call sql new query', async()=>{
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
        dataObject = returnValue.data[0];
    });

    it('should successfully save data', async()=>{
        let sql = doc.saveDoc;
        dataObject.kood = 'objtest';
        dataObject.nimetus = 'objNimetus';
        let params = {
            id: 0,
            data: {
                id: 0,
                kood: dataObject.kood,
                nimetus: dataObject.nimetus,
                asutusid: dataObject.asutusid,
                parentid: dataObject.parentid
            }
        };
        let returnValue = await db.queryDb(sql, [params, 1,1]);
        expect(returnValue).toBeDefined();
        console.log('save',params, returnValue);
        let result = returnValue.result;
        globalDocId = returnValue.data[0].id;
        expect(globalDocId).toBeGreaterThan(0);
    });

    it ('should select saved data',async()=> {
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [globalDocId,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it ('should succefully delete document',async()=> {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [1,globalDocId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });


});

