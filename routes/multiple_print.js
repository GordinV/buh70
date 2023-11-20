'use strict';
const db = require('./../libs/db');

exports.get = async (req, res) => {
    let ids = req.params.id || ''; // параметр id документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../middleware/userData')(req, uuid); // данные пользователя
    const rows = [];


    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).redirect('/login');
    }

    ids = ids.split(",").map(Number);
    // создать объект
    const Doc = require('./../classes/DocumentTemplate');

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, 'lapsed');

    // ищем шаблон
    const template = doc.config.print.find(templ => templ.params === 'id').view;

    const promises = ids.map(id => {
        return new Promise(resolve => {
            doc.setDocumentId(id);
            resolve(doc['select']())
        })
    });

    let promiseResult = await Promise.all(promises).then((data) => {
        data.forEach(result => {
            rows.push({...result.row[0], details: result.details});
        })

    });

    if (!rows || rows.length === 0) {
        res.send({status: 200, result: 'Arved ei leidnum'});
    } else {
        try {
            res.render('arve_kaartid', {title: 'Arved', data: rows, user: user});

        } catch (e) {
            console.error(e);
            res.send({status: 500, result: 'Error'});

        }

    }

};

exports.arve = async (req, res) => {
    let ids = req.params.id || ''; // параметр id документа
    const docTypeId = 'ARV'; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../middleware/userData')(req, uuid); // данные пользователя
    let rows = [];

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).redirect('/login');
    }

    ids = ids.split(",").map(Number);
    // создать объект
    const Doc = require('./../classes/DocumentTemplate');

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, 'lapsed');

    // ищем шаблон
    const template = doc.config.print.find(templ => templ.params === 'id').view;


    try {
        let doc_data = await doc.executeTask('multiple_print_doc', [ids.join(','), user.userId]);

        rows = doc_data.data;

        if (!rows || rows.length === 0) {
            res.send({status: 200, result: 'Arved ei leidnum'});
        } else {
            // register e-arve event
            let sql = doc.config.multiple_print[0].register;
            if (sql) {
                let tulem  = await db.queryDb(sql, [ids.join(','),user.userId]);
            }

            res.render('arve_kaartid', {title: 'Arved', data: rows, user: user});
        }

    } catch (e) {
        console.error('error', e);
        res.send({status: 500, result: 'Error'});
    }

};


exports.teatis = async (req, res) => {
    let ids = req.params.id || ''; // параметр id документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../middleware/userData')(req, uuid); // данные пользователя
    const rows = [];


    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).redirect('/login');
    }

    ids = ids.split(",").map(Number);
    // создать объект
    const Doc = require('./../classes/DocumentTemplate');

    const doc = new Doc('teatis', null, user.userId, user.asutusId, 'lapsed');

    // ищем шаблон
    const template = doc.config.print.find(templ => templ.params === 'id');

    let doc_data = await doc.executeTask('multiple_print_doc', [ids.join(','), user.userId]);

    if (!doc_data.data || doc_data.data.length === 0) {
        res.send({status: 200, result: 'Teatised ei leidnum'});
    } else {
        // register e-arve event
        let sql = doc.config.print[0].register;
        if (sql) {
            let tulem  = await db.queryDb(sql, [ids.join(','),user.userId]);
        }

        res.render('teatis_kaartid', {title: 'Teatised', data: doc_data.data, user: user});
    }

};

