'use strict';
const getNow = require('./../libs/getNow');
const Doc = require('./../classes/DocumentTemplate');

exports.post = async (req, res) => {
    const params = req.body;
    const taskName = req.params.taskName;
    const docTypeId = params.parameter ? params.parameter : params.data.docTypeId;
    let ids = params.data && params.data.docs ? params.data.docs : []; // параметр ids документа
    const execDate = params.data && params.data.seisuga ? params.data.seisuga : getNow(); // доп параметр дата
    const user = require('../middleware/userData')(req); // данные пользователя
    const module = req.body.module;

    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);

    if (!ids || ids.length === 0) {
        console.error('Valitud dokument ei leidnud', ids);
        return res.send({status: 200, result: null, error_message: `Valitud dokument ei leidnud`});
    }

    // ищем таску
    if (!taskName || !doc.config[taskName]) {
        console.error ('task ei leidnud',taskName);
        return res.send({status: 500, result: null, error_message: `Task ${taskName ? taskName : ''} ei leidnud`});
    }

    // делаем массив промисов
    const promises = ids.map(id => {
        return new Promise(resolve => {
            doc.setDocumentId(id);

            resolve(doc.executeTask(taskName, [id, user.userId, execDate]));
        })
    });

    // решаем их
    let lastDocId = 0;
    let promiseResult = await Promise.all(promises).then((data, err) => {
        if (err) {
            console.error('Promis error', err);
            return res.send({status: 500, result: null, error_message: err});
        }

        const replyWithDocs = data.filter(obj => {
            if (obj.error_code) {
                return res.send({status: 500, result: null, error_message: err});
            }
            return obj;
        });

        result = replyWithDocs.length;
        if (result) {
            lastDocId = replyWithDocs[result - 1].result
        }


    }).catch((err) => {
        console.error('catch', err);
        return res.send({status: 500, result: null, error_message: err.error});
    });

    //ответ
    res.send({
        status: 200, result: result, data: {
            action: taskName,
            result: {
                doc_id: lastDocId,
                error_code: 0,
                error_message: null,
            },
            data: result
        }
    });


};
