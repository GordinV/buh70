'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../../middleware/userData')(req, uuid); // данные пользователя

    let filterData = JSON.parse(filter);

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    filterData = filterData.filter(row => {
        if (row.value) {
            return row;
        }
    });


    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc('kaive_aruanne', null, user.userId, user.asutusId, 'lapsed');

        let gridParams;
        if (doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        const data = await doc.selectDocs('', sqlWhere, 100000, gridParams);


        // get xml
        let header;
        let csv = getCSV(data.data.map(row => {
            //поправить если структура меняется
            const obj = {
                lapse_nimi: row.lapse_nimi,
                lapse_isikukood: row.lapse_isikukood,
                viitenumber: row.viitenumber,
                alg_saldo: (row.alg_saldo),
                arvestatud: (row.arvestatud),
                soodustus: (row.soodustus),
                umberarvestus: (row.umberarvestus),
                arv_kokku: (Number(row.arvestatud) + Number(row.soodustus) + Number(row.umberarvestus)).toFixed(2),
                laekumised: (row.laekumised),
                tagastatud: (row.tagastused),
                ulekanned: (row.ulekanned),
                mahakantud: row.mahakantud,
                jaak: row.jaak,
                jaak_inf3: row.jaak_inf3,
                paevad: row.paevad,
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
