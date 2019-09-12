'use strict';

const moduleLocator = require('../../libs/moduleLocator.js')();
const modelCreator = require('./../../libs/createXMLmodel');
const fs = require('fs');
const convertXml = require('xml-js');
const _ = require('lodash');
const path = require('path');
const db = require('./../../libs/db');
const REKV_ID = 63;
const USER_ID = 70;


describe('vanemad tests', function () {
    let globalDocId = 0; // для сохранения ид документа

    const doc = require('../lapsed/vanem'),
        docTypeId = 'VANEM'.toLowerCase(),
        modelForExport = 'lapsed/vanem';

    moduleLocator.register(docTypeId, doc);

    let docData = doc.returnData;
    let xml;
    let sourceFile;


    it (`${docTypeId} must have fields in js model`, ()=> {
        expect(doc.select).toBeDefined();
//        expect(doc.selectAsLibs).toBeDefined();
//        expect(doc.returnData).toBeDefined();
        expect(doc.requiredFields).toBeDefined();
        expect(doc.saveDoc).toBeDefined();
        expect(doc.deleteDoc).toBeDefined();
        expect(doc.grid).toBeDefined();
    });

    it('doc type library should contain MENU doc.type', async () => {
        let sql = `select id from libs.library where kood = 'VANEM' and  library = 'DOK' limit 1`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists view cur_vanemad', async () => {
        let sql = `select 1 FROM pg_views WHERE viewname = 'cur_vanemad'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should succefully execute sql new query', async()=> {
        let sql = doc.select[0].sqlAsNew;
        let returnValue = await db.queryDb(sql, [0,1]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);
    });

    it('should exists proc lapsed.sp_salvesta_vanem', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_salvesta_vanem'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should exists proc lapsed.sp_delete_vanem', async () => {
        let sql = `select 1 FROM pg_proc WHERE proname = 'sp_delete_vanem'`;
        let returnValue = await db.queryDb(sql, []);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(result).toBeGreaterThan(0);

    });

    it('should save new row',async()=>{
        // select last laps
        let laps = await db.queryDb('select id from lapsed.laps where staatus <> 3 order by id desc limit 1', []);
        let vanemId = await db.queryDb('select id from libs.asutus where staatus <> 3 and len(ltrim(rtrim(regkood))) = 11 order by id desc limit 1', []);

        let data = {
            id: 0,
            data: {
                id: 0,
                parentid: laps.data[0].id,
                asutusid: vanemId.data[0].id,
                arved : 'jah',
                suhtumine: 'isa',
                muud:'test muud vanem'
            }
        };

        let sql = doc.saveDoc;
        let returnValue = await db.queryDb(sql, [data, USER_ID, REKV_ID]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        expect(returnValue.error_code).toBe(0);
        expect(returnValue.result).toBe(1);
        globalDocId = returnValue.data[0].id;
        expect(returnValue.result).toBeGreaterThan(0);
    });

    it('should select saved row', async()=>{
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

    it('should delete vanem', async () => {
        let sql = doc.deleteDoc;
        let returnValue = await db.queryDb(sql, [USER_ID, globalDocId]);
        expect(returnValue).toBeDefined();
        let result = returnValue.result;
        let err = returnValue.error_code;
        expect(result).toBe(1);

    });


});

