'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');


describe('dok. type Avans tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../raamatupidamine/avans'),
        docTypeId = 'AVANS'.toLowerCase(),
        modelForExport = 'raamatupidamine/avans';

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
        expect(doc.register).toBeDefined();
        expect(doc.endProcess).toBeDefined();
        expect(doc.generateJournal).toBeDefined();
        expect(doc.grid).toBeDefined();
        expect(doc.executeCommand).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'register'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'endProcess'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'grid'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'generateJournal'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'executeCommand'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curAvans'})).toBeDefined();

        let register = _.find(modelElements.elements, {name:'register'});
        expect(register).toBeDefined();
        expect(_.find(register.elements,{name:'alias'})).toBeDefined();
        let registerAlias = _.find(register.elements,{name:'alias'});
        expect(registerAlias).toBeDefined();
        let end = _.find(modelElements.elements, {name:'endProcess'});
        expect(end).toBeDefined();
        expect(_.find(end.elements,{name:'alias'})).toBeDefined();
        let endAlias = _.find(register.elements,{name:'alias'});
        expect(endAlias).toBeDefined();
        let generateJournal = _.find(modelElements.elements, {name:'generateJournal'});
        expect(generateJournal).toBeDefined();
        let executeCommand = _.find(modelElements.elements, {name:'executeCommand'});
        expect(executeCommand).toBeDefined();

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

    it('should exists view cur_avans_tasud', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_avans_tasud'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists procedure docs.get_avans_jaak', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'get_avans_jaak'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succesfully call procedure docs.get_avans_jaak', async () => {
        let sql = `SELECT docs.get_avans_jaak(parentid) as jaak FROM docs.avans1 limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

});

