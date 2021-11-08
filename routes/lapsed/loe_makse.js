'use strict';
const Doc = require('./../../classes/DocumentTemplate');

exports.post = async (req, res) => {
    const params = req.body;
    const docTypeId = 'PANK_VV';
    const makse_id = params.data.makse_id; // параметр ids документа
    const user = await require('../../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    const taskName = 'loeMakse';

    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);

    if (!makse_id) {
        return res.send({status: 200, result: null, error_message: `Valitud makse ei leidnud`});
    }

    // ищем таску
    if (!doc.config[taskName]) {
        return res.send({status: 500, result: null, error_message: `Task ${taskName} ei leidnud`});
    }

    result = await doc.executeTask(taskName, [makse_id, user.userId]);
    console.log('result', result);
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
