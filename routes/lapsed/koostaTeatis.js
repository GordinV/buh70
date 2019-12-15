'use strict';
const Doc = require('./../../classes/DocumentTemplate');
const getNow = require('./../../libs/getNow');

exports.post = async (req, res) => {
    const params = req.body;
    const docTypeId = params.parameter;
    const arvestuseKpv = params.data.seisuga || getNow(); // доп параметр дата
    const user = require('../../middleware/userData')(req); // данные пользователя
    const module = req.body.module;
    const taskName = 'koostaTeatis';

    let result = 0;

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    const doc = new Doc(docTypeId, null, user.userId, user.asutusId, module);

    // ищем таску
    if (!doc.config[taskName]) {
        return res.send({status: 500, result: null, error_message: `Task ${taskName} ei leidnud`});
    }

    // делаем массив промисов
    const data = await new Promise(resolve => {
        resolve(doc.executeTask(taskName, [user.userId, arvestuseKpv]));
    });

    //ответ
    console.log('result',data);
    res.send({
        status: 200, result: data.result, data: {
            action: taskName,
            result: {
                error_code: 0,
                error_message: null,
            },
            data: data
        }
    });
};
