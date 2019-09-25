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


describe('dok. type SORDER tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../lapsed/sorder'),
        docTypeId = 'SORDER'.toLowerCase(),
        modelForExport = 'lapsed/sorder';

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;
    let xml;
    let sourceFile;

    it.skip(`${docTypeId} create XML model`, (done) => {
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

    it.skip(`${docTypeId} must have fields in js model`, () => {
        expect(doc.select).toBeDefined();
        expect(doc.returnData).toBeDefined();
        expect(doc.requiredFields).toBeDefined();
        expect(doc.saveDoc).toBeDefined();
        expect(doc.deleteDoc).toBeDefined();
        expect(doc.register).toBeDefined();
        expect(doc.endProcess).toBeDefined();
        expect(doc.grid).toBeDefined();
    });

    it.skip(`${docTypeId} must have fields in xml model`, () => {
        let xmlModel = convertXml.xml2js(xml, {ignoreComment: true, alwaysChildren: true});
        expect(xmlModel).toBeDefined();
        let modelElements = xmlModel.elements[0];
        expect(_.find(modelElements.elements, {name: 'select'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'saveDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'deleteDoc'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'register'})).toBeDefined();
        expect(_.find(modelElements.elements, {name: 'grid'})).toBeDefined();

        let grid = _.find(modelElements.elements, {name: 'grid'});
        expect(grid).toBeDefined();
        expect(_.find(grid.elements, {name: 'alias'})).toBeDefined();
        let gridAlias = _.find(grid.elements, {name: 'alias'});
        expect(_.find(gridAlias.elements, {text: 'curKorder'})).toBeDefined();

        let register = _.find(modelElements.elements, {name: 'register'});
        expect(register).toBeDefined();
        expect(_.find(register.elements, {name: 'alias'})).toBeDefined();
        let registerAlias = _.find(register.elements, {name: 'alias'});
        expect(registerAlias).toBeDefined();

    });

    it.skip('should have copy in buh62 folder', (done) => {
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

    it(`should exists procedure docs.sp_salvesta_korder`, async () => {
        let sql = `SELECT 1
                   FROM pg_proc
                   WHERE proname = 'sp_salvesta_korder'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it(`should exists procedure docs.sp_delete_korder`, async () => {
        let sql = `SELECT 1
                   FROM pg_proc
                   WHERE proname = 'sp_delete_korder'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('doc type library should contain SORDER doc.type', async () => {
        let sql = `SELECT id
                   FROM libs.library
                   WHERE kood = 'SORDER'
                     AND library = 'DOK'
                   LIMIT 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_lapse_korder', async () => {
        let sql = `SELECT 1
                   FROM pg_views
                   WHERE viewname = 'cur_lapse_korder'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should succefully execute sql new query', async () => {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0, 1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should save new row', async () => {
        const l_asutus_data = await db.queryDb(`SELECT asutusid, parentid, a.nimetus::TEXT AS vanem_nimi
                                              FROM lapsed.vanemad v
                                                       INNER JOIN libs.asutus a ON a.id = v.asutusid
                                              WHERE v.staatus <> 3
                                              LIMIT 1`, []);
        const l_nom_data = await db.queryDb(`SELECT nomid, nimetus::text 
                                                        FROM lapsed.lapse_kaart lk
                                                        INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                                                        WHERE lk.staatus <> 3 
                                                          AND parentid = ${l_asutus_data.data[0].parentid} LIMIT 1`, []);
        const l_aa_data = await db.queryDb(`SELECT id FROM ou.aa WHERE parentid = ${REKV_ID} AND kassa = 0 LIMIT 1`, []);

        let data = {
            id: 0,
            data: {
                id: 0,
                kpv: new Date(),
                number: `${Math.floor(Math.random() * 100)}`,
                kassa_id: l_aa_data.data[0].id,
                dokument: 'dokument test',
                asutusid: l_asutus_data.data[0].asutusid,
                nimi: l_asutus_data.data[0].vanem_nimi,
                aadress: 'aadress test',
                alus: 'alus test',
                summa: 100,
                tyyp: 1,
                selg: 'sorder test',
                lapsid: l_asutus_data.data[0].parentid,
                muud: 'test muud',
                gridData: [
                    {
                        id: 0,
                        nomid: l_nom_data.data[0].nomid,
                        nimetus: l_nom_data.data[0].nimetus,
                        summa: 100,
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

        console.log('globalDocId', globalDocId);

    });

    it('should select saved row', async () => {
        let sql = doc.select[0].sql;
        let returnValue = await db.queryDb(sql, [globalDocId, USER_ID]);
        expect(returnValue).toBeDefined();

        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should select grid query', async () => {
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

