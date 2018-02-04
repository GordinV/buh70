'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');

describe('dok. type LADU-JAAK tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../libs/libraries/ladu_jaak'),
        docTypeId = 'LADU_JAAK'.toLowerCase(),
        modelForExport = 'libs/libraries/ladu_jaak';

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
        expect(doc.selectAsLibs).toBeDefined();
        expect(doc.grid).toBeDefined();
        expect(doc.executeSql).toBeDefined();
        expect(doc.executeCommand).toBeDefined();
    });

    it (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'selectAsLibs'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'executeSql'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'executeCommand'})).toBeDefined();
        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curLaduJaak'})).toBeDefined();

        let analuus = _.find(modelElements.elements, {name:'executeSql'});
        expect(analuus).toBeDefined();
        expect(_.find(analuus.elements,{name:'alias'})).toBeDefined();
        let analuusAlias = _.find(analuus.elements,{name:'alias'});
        expect(_.find(analuusAlias.elements,{text:'Analuus'})).toBeDefined();

        let recalc = _.find(modelElements.elements, {name:'executeCommand'});
        expect(recalc).toBeDefined();
        expect(_.find(recalc.elements,{name:'alias'})).toBeDefined();
        let recalcAlias = _.find(recalc.elements,{name:'alias'});
        expect(_.find(recalcAlias.elements,{text:'recalcLaduJaak'})).toBeDefined();

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
    })

});

