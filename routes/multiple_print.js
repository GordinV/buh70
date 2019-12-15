'use strict';
const db = require('./../libs/db');

exports.get = async (req, res) => {
    let ids = req.params.id || ''; // параметр id документа
    const docTypeId = req.params.documentType || ''; // параметр тип документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя
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

exports.teatis = async (req, res) => {
    let ids = req.params.id || ''; // параметр id документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя
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

