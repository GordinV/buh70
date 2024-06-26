'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');
const MODULE = 'lapsed';
const USER_ID = 70;
const REKV_ID = 63;


describe('dok. type SMK tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../raamatupidamine/smk'),
        docTypeId = 'SMK'.toLowerCase(),
        modelForExport = 'raamatupidamine/smk';

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;
    let xml;
    let sourceFile;

    it(`${docTypeId} create XML model`, (done)=> {
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

    it.skip (`${docTypeId} must have fields in js model`, ()=> {
        expect(doc.select).toBeDefined();
        expect(doc.returnData).toBeDefined();
        expect(doc.requiredFields).toBeDefined();
        expect(doc.saveDoc).toBeDefined();
        expect(doc.deleteDoc).toBeDefined();
        expect(doc.register).toBeDefined();
        expect(doc.endProcess).toBeDefined();
        expect(doc.grid).toBeDefined();
    });

    it.skip (`${docTypeId} must have fields in xml model`,() => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name:'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'deleteDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'register'})).toBeDefined();
        expect(_.find(modelElements.elements, {name:'grid'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name:'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements,{name:'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements,{name:'alias'});
        expect(_.find(gridAlias.elements,{text:'curMk'})).toBeDefined();

        let register = _.find(modelElements.elements, {name:'register'});
        expect(register).toBeDefined();
        expect(_.find(register.elements,{name:'alias'})).toBeDefined();
        let registerAlias = _.find(register.elements,{name:'alias'});
        expect(registerAlias).toBeDefined();

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

    it(`should exists procedure docs.sp_salvesta_mk`, async () => {
        let sql = `SELECT 1
                   FROM pg_proc
                   WHERE proname = 'sp_salvesta_mk'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it(`should exists procedure docs.sp_delete_mk`, async () => {
        let sql = `SELECT 1
                   FROM pg_proc
                   WHERE proname = 'sp_delete_mk'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('doc type library should contain MENU doc.type', async () => {
        let sql = `select id from libs.library where kood = 'SMK' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_lapsed_mk', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_lapsed_mk'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it.skip('should succefully execute sql new query', async()=> {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it.skip('should save new row',async()=>{
        let l_asutus_data = await db.queryDb(`select asutusid, parentid from lapsed.vanemad where staatus <> 3 limit 1`, []);
        let l_nom_data = await db.queryDb(`select id from lapsed.lapse_kaart where staatus <> 3 and parentid = ${l_asutus_data.data[0].parentid} limit 1`, []);
        let l_aa_data = await db.queryDb(`select id FROM ou.aa WHERE parentid = ${REKV_ID} AND kassa = 1 limit 1`, []);

        let data = {
            id: 0,
            data: {
                id: 0,
                kpv: new Date(),
                maksepaev: new Date(),
                number: `${Math.floor(Math.random() * 100)}`,
                aaid: l_aa_data.data[0].id,
                opt: 2,
                selg: 'test',
                lapsid: l_asutus_data.data[0].parentid,
                muud:'test muud',
                gridData:[
                    {
                        id:0,
                        nomid:l_nom_data.data[0].id,
                        asutusid: l_asutus_data.data[0].asutusid,
                        summa: 100,
                        aa: 'pank'
                    }
                ]
            }
        };

        let sql = doc.saveDoc;
        let returnValue = await db.queryDb(sql, [data, USER_ID, 63]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);
        expect(returnValue.result).toBe(1);
        globalDocId = returnValue.data[0].id;

        console.log('globalDocId',globalDocId);

    });

    it.skip('should select saved row', async()=>{
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [globalDocId,USER_ID]);
        expect(returnValue).toBeDefined();

        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should select grid query', async()=> {
        let sql = doc.grid.sqlString;
        let returnValue = await db.queryDb(sql, [REKV_ID, USER_ID]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let err = returnValue.error_code;
        expect(result).toBeGreaterThan(0);

    });

    it.skip('should delete mk', async () => {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [USER_ID, globalDocId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let err = returnValue.error_code;
        expect(result).toBe(1);

    });



});

