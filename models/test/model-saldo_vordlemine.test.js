'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');

describe('dok. type saldoVõrdlemine tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../aruanned/eelarve/saldo_vordlemine'),
        docTypeId = 'SALDO_VORDLEMINE'.toLowerCase(),
        modelForExport = 'aruanned/eelarve/saldo_vordlemine';

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
        expect(doc.grid).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'grid'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'saldo_vordlemine'})).toBeDefined();
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

    it('doc type library should contain SALDO_VORDLEMINE doc.type', async () => {
        let sql = `select id from libs.library where kood = 'SALDO_VORDLEMINE' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        console.log('returnValue',returnValue);
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should select data from grid query', async()=> {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, ['2018-12-31',1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let err = returnValue.error_code;
        expect(result).toBeGreaterThan(0);

    });


});

