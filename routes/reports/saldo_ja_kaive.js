'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = require('../../middleware/userData')(req, uuid); // данные пользователя
    let subTotals = ` sum(alg_saldo) over() as alg_saldo_total,
                sum(arvestatud) over() as arvestatud_total,
                sum(soodustus) over() as soodustus_total, 
                sum(laekumised) over() as laekumised_total,
                sum(tagastused) over() as tagastused_total,
                sum(jaak) as jaak_total `;

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
        const doc = new Doc('saldo_ja_kaive', null, user.userId, user.asutusId, 'lapsed');

        let gridParams;
        if (doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        console.log('reports subTotals', subTotals);
        const data = await doc.selectDocs('', sqlWhere, 10000, gridParams, subTotals);


        // get xml
        const csv = getCSV(data.data.map(row => {
            //поправить если структура меняется
            return {
                kulastatavus: row.kpv,
                yksus: row.yksus,
                lapse_nimi: row.lapse_nimi,
                number: row.number,
                alg_saldo: row.alg_saldo,
                arvestatud: row.arvestatud,
                soodustus: row.soodustus,
                laekumised: row.laekumised,
                tagastatud: row.tagastatud,
                jaak: row.jaak

            }
        }));
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
