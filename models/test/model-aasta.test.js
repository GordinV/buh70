'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type aasta tests', function () {
    let globalDocId = 0; // для сохранения ид документа

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

    it.skip(`${docTypeId} must have fields in xml model`, () => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name: 'selectAsLibs'})).toBeDefined();
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

    it('should have dok type AASTA', async () => {
        let sql = `select 1 FROM libs.library WHERE library = 'DOK' and kood = 'AASTA'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should execute sql string', async () => {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, [1]); //rekvid
        expect(returnValue).toBeDefined();
        console.log(returnValue);
        let result = returnValue.error_code;
        expect(result).toBe(0);
    });

    it('should exists proc ou.sp_muuda_aasta_status', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_muuda_aasta_status'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succesfully execute proc ou.sp_muuda_aasta_status', async () => {
        let sql = `select * from ou.sp_muuda_aasta_status($1, $2)`;
        let params = {
            id: 0,
            kuu: 7,
            aasta: 2018,
            status: 0
        };
        let returnValue = await db.queryDb(sql, [1, params]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });


});

