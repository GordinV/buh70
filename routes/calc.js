'use strict';
const db = require('./../libs/db');
const pdf = require('html-pdf');
const util = require('util');

const Doc = require('./../classes/DocumentTemplate');

const UserConfig = {};

exports.arvestaTaabel = async (req, res) => {
    const params = req.body;
    const docTypeId = params.parameter;
    const ids = params.data; // параметр ids документа
    const user = require('../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    const taskName = 'arvestaTaabel';
    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);
    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    if (!ids || ids.length === 0) {
        return res.send({status: 200, result: null, error_message: `Valitud lapsed ei leidnud`});
    }

    // ищем таску
    if (!doc.config[taskName]) {
        return res.send({status: 500, result: null, error_message: `Task ${taskName} ei leidnud`});
    }

    // делаем массив промисов
    const promises = ids.map(id => {
        return new Promise(resolve => {
            doc.setDocumentId(id);
            resolve(doc.executeTask(taskName))
        })
    });

    // решаем их
    let promiseResult = await Promise.all(promises).then((data) => {
        result = data.length;
    });

    //ответ

    res.send({
        status: 200, result: result, data: {
            action: taskName,
            result: {
                error_code: 0,
                error_message: null,
            },
            data: result
        }
    });
};
