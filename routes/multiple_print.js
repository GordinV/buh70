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

    console.log('start multiple');
//    res.setTimeout(4000000);

    try {
        let doc_data = await doc.executeTask('multiple_print_doc', [ids.join(','), user.userId]);
//        var doc_details = await doc.executeTask('multiple_print_details', [ids.join(','), user.userId]);

/*
        doc_data.data.forEach(result => {
            rows.push({...result});
        });
*/
        rows = doc_data.data;
        console.log('lopp multiple',doc_data.data,rows);

        if (!rows || rows.length === 0) {
            res.send({status: 200, result: 'Arved ei leidnum'});
        } else {
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

    const promises = ids.map(id => {
        return new Promise(resolve => {
            doc.setDocumentId(id);
            resolve(doc['select']())
        })
    });

    let promiseResult = await Promise.all(promises).then((data) => {
        data.forEach(result => {
            rows.push({...result.row[0]});
        })

    });

    // register print event
    if (template) {

        const registerPromises = ids.map(id => {
            return new Promise(resolve => {
                let sql = template.register,
                    params = [id, user.userId];

                if (sql) {
                    resolve(db.queryDb(sql, params));
                }
            })
        });

        Promise.all(registerPromises);
    }

    if (!rows || rows.length === 0) {
        res.send({status: 200, result: 'Teatised ei leidnum'});
    } else {
        try {
            res.render('teatis_kaartid', {title: 'Teatised', data: rows, user: user});

        } catch (e) {
            console.error(e);
            res.send({status: 500, result: 'Error'});

        }

    }

};

