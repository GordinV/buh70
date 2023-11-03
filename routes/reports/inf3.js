'use strict';
const getINF3 = require('./../lapsed/get_INF3_xml');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user =await require('../../middleware/userData')(req, uuid); // данные пользователя

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc('inf3', null, user.userId, user.asutusId, 'lapsed');
        const data =  await doc.selectDocs('', sqlWhere, 100000);

        // get xml
        const xml = await getINF3(data.data, user);
        if (xml) {
            res.attachment('inf3.xml');
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
