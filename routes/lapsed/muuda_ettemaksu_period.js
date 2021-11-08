'use strict';
const Doc = require('./../../classes/DocumentTemplate');

exports.post = async (req, res) => {
    const params = req.body;
    const docTypeId = params.parameter;
    const ids = params.data.docs; // параметр ids документа
    const ettemaksuPeriod = params.data.ettemaksuPeriod || 1; // доп параметр дата
    const user =await require('../../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    const taskName = 'muudaEttemaksuPeriod';

    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);

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
            resolve(doc.executeTask(taskName, [id, user.userId, ettemaksuPeriod]));
        })
    });

    // решаем их
    let promiseResult = await Promise.all(promises).then((data) => {
        const replyWithDocs = data.filter(obj => {
            if(!obj.error_code && obj.result && obj.result > 0) {
                return obj;
            }
        });
        result = replyWithDocs.length;

    }).catch((err)=>{
        return res.send({status: 500, result: null, error_message: err});
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
