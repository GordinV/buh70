'use strict';
const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type Kond Saldoandmik aruanne tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../aruanned/eelarve/kond_saldoandmik'),
        docTypeId = 'KONDSALDOANDMIK'.toLowerCase(),
        modelForExport = 'aruanned/eelarve/kond_saldoandmik';

    moduleLocator.register(docTypeId, doc);

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
        expect(doc.grid).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'grid'})).toBeDefined();
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

    it('doc type library should contain KONDSALDOANDMIK doc.type', async () => {
        let sql = `select id from libs.library where kood = 'KONDSALDOANDMIK' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should select data from grid query', async()=> {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, ['2018-01-01', 63]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let err = returnValue.error_code;
        expect(err).toBe(0);

    });

    it.skip('should exists procedure eelarve.sp_koosta_kassakulud',async()=> {
       let sql = `select * from pg_proc where proname = 'sp_koosta_kassakulud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it.skip('should exists procedure eelarve.sp_koosta_saldoandmik',async()=> {
        let sql = `select * from pg_proc where proname = 'sp_koosta_saldoandmik'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it.skip('should succefully execute eelarve.sp_koosta_saldoandmik', async()=> {
        let sql = doc.executeCommand.command;
        let params = {
            rekvid: 1,
            kpv: '2018-08-31'
        };
        let returnValue = await db.queryDb(sql, [1,params]);
        expect(returnValue).toBeDefined();
        console.log('execute',returnValue);
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists proc eelarve.saldoandmik_aruanne', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'saldoandmik_aruanne'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists proc eelarve.kond_saldoandmik_aruanne', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'kond_saldoandmik_aruanne'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists proc eelarve.koosta_kond_saldoandmik', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'koosta_kond_saldoandmik'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists proc eelarve.sp_koosta_kassakulud', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_koosta_kassakulud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists proc eelarve.sp_salvesta_aastakassakulud', async()=> {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_aastakassakulud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });


});

