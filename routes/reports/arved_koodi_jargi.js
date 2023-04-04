'use strict';
const getCSV = require('./../lapsed/get_csv');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../../middleware/userData')(req, uuid); // данные пользователя

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc('arved_koodi_jargi', null, user.userId, user.asutusId, 'lapsed');
        const data = await doc.selectDocs('', sqlWhere, 10000);


        // get xml
        let header;
        let csv = getCSV(data.data.map(row => {
            const obj = {
                kpv: row.kpv,
                aasta: row.aasta,
                kuu: row.kuu,
                number: row.number,
                kood: row.kood,
                hind: row.hind,
                kogus: row.kogus,
                summa: row.summa,
                asutus: row.asutus
            };

            if (!header) {
                header = Object.keys(obj).join(';') + '\n';
            }

            return obj;
        }));

        csv = header + csv;

        if (csv) {
            res.attachment('report.csv');
            res.type('csv');
            res.send(csv);
        } else {
            res.status(500).send('Error in getting CSV');
        }
    } catch (error) {
        console.error('error:', error); // @todo Обработка ошибок
        res.send({status: 500, result: 'Error'});

    }
};
