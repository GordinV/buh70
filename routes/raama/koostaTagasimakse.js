'use strict';
const getNow = require('./../../libs/getNow');
const Doc = require('./../../classes/DocumentTemplate');

exports.post = async (req, res) => {
    const params = req.body;
    const taskName = 'koostaTagasimakse';
    const docTypeId = params.parameter ? params.parameter : params.data.docTypeId;
    let ids = params.data && params.data.docs ? params.data.docs : []; // параметр ids документа
    const execDate = params.data && params.data.seisuga ? params.data.seisuga : getNow(); // доп параметр дата
    const user = require('./../../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    let tulemused;

    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);

    if (!ids || ids.length === 0) {
        return res.send({status: 200, result: null, error_message: `Valitud dokument ei leidnud`});
    }

    // ищем таску
    if (!taskName || !doc.config[taskName]) {
        return res.send({status: 500, result: null, error_message: `Task ${taskName ? taskName : ''} ei leidnud`});
    }

    let lastDocId = 1;
    try {

        doc.setDocumentId(ids[0]);
        tulemused = await doc.executeTask(taskName, [ids.join(','), user.userId, execDate]);
    } catch (e) {
        console.error('catch', err);
        return res.send({status: 500, result: null, error_message: err.error});

    }

    //ответ

    res.send({
        status: 200, result: 1, data: {
            action: taskName,
            result: {
                doc_id: lastDocId,
                error_code: 0,
                error_message: null,
                tulemused: tulemused
            },
            data: result
        }
    });
};
