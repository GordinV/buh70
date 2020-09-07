'use strict';
const Doc = require('./../../classes/DocumentTemplate');

exports.post = async (req, res) => {
    const params = req.body;
    const docTypeId = params.parameter;
    const ids = params.data.docs; // параметр ids документа
    const teenusteTahtaeg = params.data.teenusteTahtaeg; // доп параметр дата
    const user = require('../../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    const taskName = 'muudaTeenusteTahtaeg';

    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);

    if (!ids || ids.length === 0) {

        return res.send({status: 200, result: null, error_message: `Valitud teenused ei leidnud`});
    }

    // ищем таску
    if (!doc.config[taskName]) {
        return res.send({status: 500, result: null, error_message: `Task ${taskName} ei leidnud`});
    }

    try {

        doc.setDocumentId(ids[0]);
        let data = doc.executeTask(taskName, [ids.join(','), user.userId, teenusteTahtaeg]);
    } catch (e) {
        console.log('catch', err);
        return res.send({status: 500, result: null, error_message: err});

    }


    //ответ

    res.send({
        status: 200, result: ids.length
    });
};
