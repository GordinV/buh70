'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../../middleware/userData')(req, uuid); // данные пользователя
    const DOC_TYPE_ID = 'kuu_taabel';

    let filterData = [];

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    if (filter.length > 0) {
        filterData = JSON.parse(filter);


        filterData = filterData.filter(row => {
            if (row.value) {
                return row;
            }
        });
    }

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc(DOC_TYPE_ID, null, user.userId, user.asutusId, 'lapsed');

        let gridParams;
        if (doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        const data = await doc.selectDocs('', sqlWhere, 10000, gridParams);

        // get xml
        let header;
        let csv = getCSV(data.data.map(row => {
            //поправить если структура меняется
            const obj = {
                yksus: row.yksus,
                teenus: row.teenus,
                kuu: row.kuu,
                aasta: row.aasta,
                paev_01: row.day_1,
                paev_02: row.day_2,
                paev_03: row.day_3,
                paev_04: row.day_4,
                paev_05: row.day_5,
                paev_06: row.day_6,
                paev_07: row.day_7,
                paev_08: row.day_8,
                paev_09: row.day_9,
                paev_10: row.day_10,
                paev_11: row.day_11,
                paev_12: row.day_12,
                paev_13: row.day_13,
                paev_14: row.day_14,
                paev_15: row.day_15,
                paev_16: row.day_16,
                paev_17: row.day_17,
                paev_18: row.day_18,
                paev_19: row.day_19,
                paev_20: row.day_20,
                paev_21: row.day_21,
                paev_22: row.day_22,
                paev_23: row.day_23,
                paev_24: row.day_24,
                paev_25: row.day_25,
                paev_26: row.day_26,
                paev_27: row.day_27,
                paev_28: row.day_28,
                paev_29: row.day_29,
                paev_30: row.day_30,
                paev_31: row.day_31,
                kokku: row.kogus

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
