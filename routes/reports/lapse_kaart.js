'use strict';
const getCSV = require('./../lapsed/get_csv');

exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const kasKond = req.params.kond || false; // параметр kond
    const user =await require('../../middleware/userData')(req, uuid); // данные пользователя

    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }

    try {
        // создать объект
        const Doc = require('./../../classes/DocumentTemplate');
        const doc = new Doc('lapse_kaart', null, user.userId, user.asutusId, 'lapsed');
        const data = await doc.selectDocs('', sqlWhere, 100000);

        // get csv

        const csvData = data.data.map(row => {
            let yksus = get_yksus(row.yksus);
            return {
                isikukood: row.isikukood,
                yksus: row.yksuse_kood,
                all_yksus: yksus.all_yksus,
                kood: row.kood,
                hind: row.hind,
                kogus: row.kogus,
                tunnus: row.tunnus,
                alg_kpv: row.alg_kpv,
                lopp_kpv: row.lopp_kpv,
                kas_ettemaks: row.ettemaks ? 'yes' : null,
                ettemaksu_period: row.ettemaksu_period,
                kas_eraldi: row.kas_eraldi ? 'yes' : null,
                kas_inf3: row.inf3 ? 'yes' : null,
                soodustus: row.soodustuse_summa,
                soodustuse_alg: row.sooduse_alg,
                soodustuse_lopp: row.sooduse_lopp,
                kas_protsent: row.kas_protsent && row.kas_protsent == '%' ? 'yes' : null,
                nimi: row.nimi,
                viitenumber: row.viitenumber,
                asutus: row.asutus,
                vana_viitenumber: row.vana_viitenumber

            }
        });

        const header = [{
            isikukood: 'isikukood',
            yksus: 'yksus',
            all_yksus: 'all_yksus',
            kood: 'kood',
            hind: 'hind',
            kogus: 'kogus',
            tunnus: 'tunnus',
            alg_kpv: 'alg_kpv',
            lopp_kpv: 'lopp_kpv',
            kas_ettemaks: 'kas_ettemaks',
            ettemaksu_period: 'ettemaksu_period',
            kas_eraldi: 'kas_eraldi',
            kas_inf3: 'kas_inf3',
            soodustus: 'soodustus',
            soodustuse_alg: 'soodustuse_alg',
            soodustuse_lopp: 'soodustuse_lopp',
            kas_protsent: 'kas_protsent',
            nimi: 'nimi',
            viitenumber: 'viitenumber',
            asutus: 'asutus',
            vana_viitenumber: 'vana_viitenumber'
        }];

        const csv = getCSV(header.concat(csvData));

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

function get_yksus(yksus) {
    const tulemus = {
        yksus: '',
        all_yksus: ''
    };

    let found_brk = yksus.match(/[(]/);
    if (found_brk) {
        // найдена скоба с подучрежденим
        tulemus.yksus = yksus.slice(0, found_brk.index);
        tulemus.all_yksus = yksus.slice(found_brk.index).replace(/[^a-z,A-Z, 0-9,-,=]+/g, '');
    } else {
        //подучреждений нет
        tulemus.yksus = yksus;
    }
    return tulemus;
}
