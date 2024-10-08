'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;

    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../../middleware/userData')(req, uuid); // данные пользователя

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

console.log('filter',filter);
    let filterData = JSON.parse(filter);

    filterData = filterData.filter(row => {
        if (row.value) {
            return row;
        }
    });



    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc('arved_koodi_jargi', null, user.userId, user.asutusId, 'lapsed');

        let gridParams;
        if (doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        const data = await doc.selectDocs('', sqlWhere, 1000000, gridParams);


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
                asutus: row.asutus,
                isikukood: row.isikukood,
                yksus: row.yksus,
                inf3: row.inf3
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
