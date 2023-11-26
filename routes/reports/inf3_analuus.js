'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');

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
        const doc = new Doc('inf3_analuus', null, user.userId, user.asutusId, 'lapsed');

        const data = await doc.selectDocs('', sqlWhere, 500000);


        // get xml
        let header;
        let csv = getCSV(data.data.map(row => {
            //поправить если структура меняется
            const obj = {
                lapse_isikukood: row.lapse_isikukood,
                maksja_isikukood: row.maksja_isikukood,
                asutus: row.asutus,
                number: row.number,
                kpv: row.kpv,
                aasta: row.aasta,
                summa: row.summa,
                markused: row.markused

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
