'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type Userid tests', function () {
    let globalDocId = 0; // для сохранения ид документа
    let params = {
        id: 0, data: {
            kasutaja:'test_2',
            ametnik: 'Test ',
            is_kasutaja: true
        }
    };

    const doc = require('../ou/userid'),
        docTypeId = 'USERID'.toLowerCase(),
        modelForExport = 'ou/userid';

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
//        expect(doc.selectAsLibs).toBeDefined();
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
  //      expect(_.find(modelElements.elements, {name:'selectAsLibs'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curUserid'})).toBeDefined();
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

    it('doc type library should contain USERID doc.type', async()=> {
        let sql = `select id from libs.library where kood = 'USERID' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succefully execute new sql request', async()=> {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists ou.sp_salvesta_userid', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_userid'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succefully execute ou.sp_salvesta_userid', async()=> {
        let sql = doc.saveDoc;
        let returnValue = await db.queryDb(sql, [params, 1,1]);
        expect(returnValue).toBeDefined();
        globalDocId  = returnValue.data[0].id;
        expect(globalDocId).toBeGreaterThan(0);
        // should be system role
        sql = ` SELECT 1
        FROM pg_roles
        WHERE rolname = '${params.data.kasutaja}'`;

        returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        expect(returnValue.result).toBe(1);
    });

    it ('should select data', async() => {
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [globalDocId,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it ('should select grid data', async() => {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists ou.sp_delete_userid', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_delete_userid'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succefully execute ou.sp_delete_userid', async()=> {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [1,globalDocId]);
        expect(returnValue).toBeDefined();
        expect(returnValue.result).toBe(1);
        // should not be system role
        sql = ` SELECT 1
        FROM pg_roles
        WHERE rolname = '${params.data.kasutaja}'`;

        returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        expect(returnValue.error_code).toBe(0);
    });

});

