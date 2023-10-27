'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../../middleware/userData')(req, uuid); // данные пользователя
    const DOC_TYPE_ID = 'pank_vv';

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc(DOC_TYPE_ID, null, user.userId, user.asutusId, 'lapsed');

        const data = await doc.selectDocs('', sqlWhere, 10000, [user.userId, user.asutusId]);

        // get xml
        let header;
        let csv = getCSV(data.data.map(row => {
            //поправить если структура меняется

            const obj = {
                maksja: row.maksja,
                maksja_ik: row.maksja_ik,
                viitenumber: row.viitenumber,
                iban: row.iban,
                pank: row.pank,
                maksepaev: row.kpv,
                summa: row.summa,
                selgitus:  row.selg,
                markused: row.markused,
                number: row.number,
                asutus: row.asutus

            };

            // will add header to file
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
}
;
