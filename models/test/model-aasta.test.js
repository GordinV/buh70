'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');
const config = require('./../../config/test');


describe('dok. type aasta tests', function () {
    let globalDocId = 0; // для сохранения ид документа
    let data = []; // результат выборки
    var dt = new Date();
    var month = dt.getMonth();
    var year = dt.getFullYear();
    var userId;
    var rekvId = 63; // Rahandusamet


    const doc = require('../ou/aasta'),
        docTypeId = 'AASTA'.toLowerCase(),
        modelForExport = 'ou/aasta';

    moduleLocator.register(docTypeId, doc);

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
        expect(doc.selectAsLibs).toBeDefined();
    });

    it(`${docTypeId} must have fields in xml model`, () => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name: 'selectAsLibs'})).toBeDefined();
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

    it('should have dok type AASTA', async () => {
        let sql = `SELECT 1
                   FROM libs.library
                   WHERE library = 'DOK'
                     AND kood = 'AASTA'`;
        let returnValue = await db.queryDb(sql, [], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('load lib', async () => {
// selectAsLibs
        let sql = doc.selectAsLibs;
        let returnValue = await db.queryDb(sql, [63], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let row = returnValue.data[0];
        expect(result).toBeGreaterThan(0);
        expect(row).toHaveProperty('palk_kinni', 0);
//        console.log('result', result, returnValue);
    });


    it('should exists proc ou.sp_muuda_aasta_status', async () => {

        let sql = `SELECT 1
                   FROM pg_proc
                   WHERE proname = 'sp_muuda_aasta_status'`;
        let returnValue = await db.queryDb(sql, [], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should return error due no userId supplied => proc ou.sp_muuda_aasta_status', async () => {
        userId = 0;
        let sql = `SELECT *
                   FROM ou.sp_muuda_aasta_status($1, $2)`;
        let params = {
            kuu: month,
            aasta: year,
            status: 0
        };
        let returnValue = await db.queryDb(sql, [userId, params], null, null, null, null, config);
        console.log('returnValue',returnValue);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBe(0);
        expect(returnValue.error_code).toBeGreaterThan(0);
    });


    it('should succesfully execute proc ou.sp_muuda_aasta_status', async () => {
        let getUserSql = `SELECT id FROM ou.userid WHERE rekvid = ${rekvId} and kasutaja = 'vlad' and status < 3 limit 1`;
        let returnValue = await db.queryDb(getUserSql, [], null, null, null, null, config);
        userId = returnValue.data[0].id;

        let sql = `SELECT *
                   FROM ou.sp_muuda_aasta_status($1, $2)`;
        let params = {
            kuu: month,
            aasta: year,
            status: 1 // closed
        };
        returnValue = await db.queryDb(sql, [userId, params], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should execute grid sql string', async () => {
        let sql = doc.grid.sqlString;
        let sqlWhere = `where kuu = ${month} and aasta = ${year}`;
        let returnValue = await db.queryDb(sql, [rekvId], [], sqlWhere, null, null, config); //rekvid
        expect(returnValue).toBeDefined();
        let is_error = returnValue.error_code;
        let result = returnValue.result;
        let row = returnValue.data[0];
        data =  returnValue.data;
        expect(is_error).toBe(0);
        expect(result).toBeGreaterThan(0);
        expect(row).toHaveProperty('palk_kinni', 'Jah');
        expect(row).toHaveProperty('kinni:', 'Jah');
    });


});

