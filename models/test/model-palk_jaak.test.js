'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type Palk_jaak tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../palk/palk_jaak'),
        docTypeId = 'PALK_JAAK'.toLowerCase(),
        modelForExport = 'palk/palk_jaak';

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
        expect(doc.grid).toBeDefined();
        expect(doc.executeCommand).toBeDefined();
    });

    it(`${docTypeId} must have fields in xml model`, () => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name: 'grid'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'executeCommand'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name: 'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements, {name: 'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements, {name: 'alias'});
        expect(_.find(gridAlias.elements, {text: 'curPalkJaak'})).toBeDefined();
        let executeCommand = _.find(modelElements.elements, {name: 'executeCommand'});
        expect(executeCommand).toBeDefined();
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


    it.skip('doc type library should contain PALK_JAAK doc.type', async () => {
        let sql = `select id from libs.library where kood = 'PALK_JAAK' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists view cur_palk_jaak', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_palk_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should succesfully execute view cur_palk_jaak', async () => {
        let sql = doc.grid.sqlString + ' limit 100';
        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });


    it.skip('should exists view print_palk_jaak', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'print_palk_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it.skip('should succesfully execute view palk.print_palk_jaak', async () => {
        let sql = doc.print[0].sql + ' limit 100';
        let returnValue = await db.queryDb(sql, [1,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it.skip('should exists proc sp_update_palk_jaak', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_update_palk_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should return 1 as result of  proc sp_update_palk_jaak', async () => {
        let sql = `SELECT palk.sp_update_palk_jaak(DATE(), 4)`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists record for current month', async () => {
        let sql = `select count(id) as count from palk.palk_jaak where kuu = month(DATE()) and aasta = year(date()) and lepingid = 4`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = Number(returnValue.data[0].count);
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists proc palk.sp_calc_palgajaak', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_calc_palgajaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });
    it.skip('should proc palk.sp_calc_palgajaak return 1 as result ', async () => {
        let params = {
            isikud: [56, 57],
            rekvid: 1
        };

        let sql = `SELECT palk.sp_calc_palgajaak(1,$1)::integer as result`;
        let returnValue = await db.queryDb(sql, [params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(1);
        result = returnValue.data[0].result;
        expect(result).toBe(1);

    });


});

