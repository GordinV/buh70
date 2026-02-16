'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');
const config = require('./../../config/test');

describe('dok. type Palk_Kaart tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../palk/palk_kaart'),
        docTypeId = 'PALK_KAART'.toLowerCase(),
        modelForExport = 'palk/palk_kaart';

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
//        expect(doc.executeCommand).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'selectAsLibs'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'grid'})).toBeDefined();
//        expect(_.find(modelElements.elements, {name:'executeCommand'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curPalkKaart'})).toBeDefined();
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

    it.skip('doc type library should contain PALK_KAART doc.type', async()=> {
        let sql = `select id from libs.library where kood = 'PALK_KAART' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, [], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should exists view com_palk_kaart', async()=> {
        let sql = `select 1 FROM pg_views WHERE viewname = 'com_palk_kaart'`;
        let returnValue = await db.queryDb(sql, [], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });
    it.skip('should exists view cur_palk_kaart', async()=> {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_palk_kaart'`;
        let returnValue = await db.queryDb(sql, [], null, null, null, null, config);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('call import from tmpl procedure, shoul not return error_code', async () => {
        let sql = `WITH qry AS (SELECT pk.id
                                 FROM palk.palk_kaart pk
                                 LIMIT 1)
                    SELECT *
                    FROM palk.change_kaart_status(
                        ((SELECT id
                          FROM qry)),
                        1)`;

        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.error_code;
        expect(result).toBe(0);

    })


});

