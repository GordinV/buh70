'use strict';
const db = require('./../libs/db');
const getSepa = require('./lapsed/get_sepa_xml');

const Doc = require('./../classes/DocumentTemplate');

const UserConfig = {};

const getConfigData = async function (user) {
    const docConfig = new Doc('config', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const configData = await docConfig.select();
    UserConfig.email = {...configData.row[0]};

};

exports.get = async (req, res) => {
    let ids = req.params.id || ''; // параметр id документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../middleware/userData')(req, uuid); // данные пользователя

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    ids = ids.split(",").map(Number);

    // данные предприятия
    const rekvDoc = new Doc('REKV', user.asutusId, user.userId, user.asutusId, 'lapsed');
    const rekvData = await rekvDoc['select'](rekvDoc.config);

    // создать объект
    const eSepaDoc = new Doc('VMK', null, user.userId, user.asutusId, 'lapsed');

    // выборка данных
    // делаем массив промисов
    const dataPromises = ids.map(id => {
        return new Promise(resolve => {
            eSepaDoc.setDocumentId(id);
            resolve(eSepaDoc['select'](eSepaDoc.config));
        })
    });

    // решаем их
    const selectedDocs = [];
    let promiseSelectResult = await Promise.all(dataPromises).then((result) => {

        selectedDocs.push(result);
    }).catch((err) => {
        console.error('catched error->', err);
        return res.send({status: 500, result: null, error_message: err});
    });


    // готовим параметры
    const asutusConfig = {
        asutus: rekvData.row[0].muud ? rekvData.row[0].muud : rekvData.row[0].nimetus,
        regkood: rekvData.row[0].regkood,
        user: user.userName
    };


    try {
        // делаем XML
        const xml = getSepa(selectedDocs[0], asutusConfig);

        // register eksport event
        let sql = eSepaDoc.config.sepa[0].register;

        // делаем массив промисов
        const registerPromises = ids.map(id => {
            return new Promise(resolve => {
                let params = [id, user.userId];
                db.queryDb(sql, params);
            })
        });

        // решаем их
        let promiseRegisterResult = Promise.all(registerPromises);

        // возвращаем его
        if (xml) {
            res.attachment('sepa.xml');
            res.type('xml');
            res.send(xml);
        } else {
            res.status(500).send('Error in getting XML');
        }

    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }

};


exports.post = async (req, res) => {
    const params = req.body;
    const id = Number(params.docId || 0); // параметр id документа
    const ids = params.data || []; // параметр ids документов

    const user = require('../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    let result = 0;

    if (!user) {
        console.error('error 401, no user');
        return res.status(401).end();
    }

    if (!ids.length && id) {
        // передан ид документа
        ids.push(id);
    }

    if (!params.docTypeId) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Dokument tüüp puudub või vale`});
    }

    if (!ids || ids.length === 0) {
        // нет документов для отправки
        return res.send({status: 200, result: null, error_message: `Valitud lapsed ei leidnud`});
    }

    // данные предприятия
    const rekvDoc = new Doc('REKV', user.asutusId, user.userId, user.asutusId, module);
    const rekvData = await rekvDoc['select'](rekvDoc.config);

    // создать объект
    const earveDoc = new Doc(params.docTypeId, null, user.userId, user.asutusId, module);

    // выборка данных
    // делаем массив промисов
    const dataPromises = ids.map(id => {
        return new Promise(resolve => {
            earveDoc.setDocumentId(id);
            resolve(earveDoc['select'](earveDoc.config));
        })
    });

    // решаем их
    const selectedDocs = [];
    let promiseSelectResult = await Promise.all(dataPromises).then((result) => {

        //      selectedDocs.push({...result[0].row[0], details: result[0].details});
        selectedDocs.push(result);
    }).catch((err) => {
        console.error('catched error->', err);
        return res.send({status: 500, result: null, error_message: err});
    });

    // готовим параметры
    const asutusConfig = {
        url: rekvData.row[0].earved_omniva, //'https://finance.omniva.eu/finance/erp/',
        secret: rekvData.row[0].earved, //'106549:elbevswsackajyafdoupavfwewuiafbeeiqatgvyqcqdqxairz',
        asutus: rekvData.row[0].muud ? rekvData.row[0].muud : rekvData.row[0].nimetus,
        regkood: rekvData.row[0].regkood,
        user: user.userName

    };

    try {
        // делаем XML
        const xml = getEarve(selectedDocs[0], asutusConfig).replace('<?xml version="1.0" encoding="utf-8"?>', '');

        // отправляем в Омнива
        const sendResult = await sendToOmniva(xml, asutusConfig);
        if (sendResult === 200) {
            //success
            // register e-arve event
            let sql = earveDoc.config.earve[0].register;

            // делаем массив промисов
            const registerPromises = ids.map(id => {
                return new Promise(resolve => {
                    let params = [id, user.userId];
                    db.queryDb(sql, params);
                })
            });

            // решаем их
            let promiseRegisterResult = Promise.all(registerPromises);

            //ответ
            res.send({
                status: 200, result: ids.length, data: {
                    action: 'earve',
                    result: {
                        error_code: 0,
                        error_message: null,
                    },
                    data: []
                }
            });

        } else {
            res.send({
                status: 500,
                result: result,
                data: {
                    action: 'earve',
                    result: {
                        error_code: 1,
                        error_message: 'Õnnestu',
                    },
                    data: []
                }
            });

        }


    } catch (e) {
        console.error(e);
        res.status(500).end();

    }

};