'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type PV_KAART tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../libs/libraries/pv_kaart'),
        docTypeId = 'PV_KAART'.toLowerCase(),
        modelForExport = 'libs/libraries/pv_kaart';

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

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'selectAsLibs'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curPohivara'})).toBeDefined();
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

    it('doc type library should contain POHIVARA doc.type', async()=> {
        let sql = `select id from libs.library where kood = 'POHIVARA' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_pohivara', async()=> {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_pohivara'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_pv_oper', async()=> {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_pv_oper'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc sp_samm_kulum', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_samm_kulum'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists proc docs.gen_lausend_pv_oper', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'gen_lausend_pv_oper'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists proc sp_salvesta_pv_oper', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_pv_oper'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should select pv_kaart as new',async()=>{
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succesfully execute grid query', async()=>{
       let sql = doc.grid.sqlString + ' limit 100';
        let returnValue = await db.queryDb(sql, [1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it ('should successfully call docs.sp_samm_kulum', async()=>{
        let sql = `SELECT * FROM docs.sp_samm_kulum($1, $2)`;
        let params = {
            ids: [236182, 235982,236184],
            nomid: 76,
            kpv: "2018-08-31",
            doklausid: 60
        };

        let returnValue = await db.queryDb(sql, [1, params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

});

