'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');
const Moment = require('moment');
exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user = await require('../../middleware/userData')(req, uuid); // данные пользователя

    let filterData = filter && filter.length ? JSON.parse(filter) : [];

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
        const doc = new Doc('lapse_taabel', null, user.userId, user.asutusId, 'lapsed');

        let gridParams;
        if (doc.config.grid.params && typeof doc.config.grid.params !== 'string') {
            gridParams = getParameterFromFilter(user.asutusId, user.userId, doc.config.grid.params, filterData);
        }

        const data = await doc.selectDocs('', sqlWhere, 10000, gridParams);


// Кроме этого, как и отчет по сальдо-обороту, необходим экспорт в CSV файл полями:
//        DateNach	GodNach	MesNach	NrSch	KodNach	Stoim	Kolich	Nach	Info	SrokOpl	VhSaldo
//        05.05.2022	2022	4	906509	3	0,56	13	7,28		19.05.2022	0

        // get xml
        let header;

        let csvData = [];

// поправка 28.06
        /*
                В случае наличия скидки (25% или 100%) платы за место и учебные надо поступать так:
                    1. Вычисляется пропорция посещений. Например 4 дня посещений из 21-го (4/21=0.19047619)
                2. Вычисляется количество (часть от единицы)
                Пропорция посещений * скидку и результат округлить до 4 знаков после запятой
                0.19047619*0,25=0.0476190475 - округл = 0.0476 - это попадает в поле "Kolich"
                3. Вычисляется сумма начисления в счет.
                    Полная стоимость услуги (со знаком минус, т.к. скидка) * вычисленное количество и результат округлить до 2 знаков после запятой
                -20.44 (плата за место) * 0.0476 = -0.972944 - округл = -0.97 - это попадает в поле "Nach"
        */


        data.data.forEach(row => {
            let kasSoodustus = false;

            let arvKpv = Moment(row.aasta.toString() + '-' + row.kuu.toString() + '-' + '05', "YYYY-MM-DD").add(1, 'month').format("DD.MM.YYYY");
            let tahtaeg = Moment(row.aasta.toString() + '-' + row.kuu.toString() + '-' + '19', "YYYY-MM-DD").add(1, 'month').format("DD.MM.YYYY");

            if (row.kood == '322040-033') {
                // У нее размерность ВСЕГДА штуки (т.е.  разовая, от посещаемости не зависит), т.е. всегда кол-во = 1 и кол-во дней не указывается
                row.kogus = 1;
                row.muud = null;
            }

            let kulastused = 1;
            let soodustus = 0;
            let soodustuseKogus = 0;
            let soodustuseSumma = 0;

            if (Number(row.soodustus) > 0) {
                // расчет суммы льготы
                soodustus = ((Number(row.soodustus) / (Number(row.hind) * Number(row.kogus))) * 100).toFixed(0);

//                if (soodustus == 25 || soodustus == 100 || soodustus == 26) {
                kulastused = Number(row.kulastused) === 0  ? 1 : (row.kovid) / row.too_paevad;

                soodustuseKogus = ((soodustus / 100) * kulastused).toFixed(4);
                soodustuseSumma = (soodustuseKogus * row.hind * -1).toFixed(2);

                row.kogus = row.kogus ? row.kogus : soodustuseKogus;
                row.summa = (Number(row.hind) * Number(row.kogus)).toFixed(2);
//                }

                //Вычисляется количество (часть от единицы)
                // Пропорция посещений * скидку и результат округлить до 4 знаков после запятой
                // 0.19047619*0,25=0.0476190475 - округл = 0.0476 - это попадает в поле "Kolich"

            }

            //поправить если структура меняется
            const obj = {
                DateNach: arvKpv,
                GodNach: row.aasta,
                MesNach: row.kuu,
                NrSch: row.viitenr ? row.viitenr.substring(0, row.viitenr.length - 1) : '',
                KodNach: getCode(row.kood, kasSoodustus),
                Stoim: Number(row.hind).toFixed(2),
                Kolich: (Number(row.kogus)).toFixed(4),
                Nach: (Number(row.summa)).toFixed(2),
                Info: row.muud && row.muud !== '0' ? row.muud.replace('päeva', 'pv') : '',
                SrokOpl: tahtaeg,
                VhSaldo: false
            };

            if (Number(row.soodustus) > 0 && Number(row.hind) > 0) {

                // меняем сумму на полную
//                obj.Nach = (Number(row.kogus)  * Number(row.hind)).toFixed(2);
                kasSoodustus = true;

                // Вычисляется пропорция посещений. Например 4 дня посещений из 21-го (4/21=0.19047619)
                // 2. Вычисляется количество (часть от единицы)
                // Пропорция посещений * скидку и результат округлить до 4 знаков после запятой
                // 0.19047619*0,25=0.0476190475 - округл = 0.0476 - это попадает в поле "Kolich"
//                    let parandatudSoodustus = Number(row.soodustus) * (soodustus / 100)  * kulastused;
//                    let parandatudHind = parandatudSoodustus * Number(row.hind);
//                    row.kogus = ((soodustus / 100)  * kulastused).toFixed(4);

                // 3. Вычисляется сумма начисления в счет.
                // Полная стоимость услуги (со знаком минус, т.к. скидка) * вычисленное количество и результат округлить до 2 знаков после запятой
                // -20.44 (плата за место) * 0.0476 = -0.972944 - округл = -0.97 - это попадает в поле "Nach"

                kulastused = Number(row.kulastused) === 0 ? 1 : (row.kovid) / row.too_paevad;

                soodustuseKogus = ((soodustus / 100) * kulastused).toFixed(4);
                soodustuseSumma = (soodustuseKogus * row.hind * -1).toFixed(2);
            }


            // will add header to file
            if (!header) {
                header = Object.keys(obj).join(';') + '\n';
            }

            csvData.push(obj);

            if (kasSoodustus) {
                if (Number(row.summa) == 0) {
                    // старая схема
                    row.kogus = (Number(row.soodustus) / Number(row.hind));
                }

                // делаем доп. вставку в массив
                const obj = {
                    DateNach: arvKpv,
                    GodNach: row.aasta,
                    MesNach: row.kuu,
                    NrSch: row.viitenr ? row.viitenr.substring(0, row.viitenr.length - 1) : '',
                    KodNach: getCode(row.kood, kasSoodustus),
                    Stoim: -1 * Number(row.hind).toFixed(2),
                    Kolich: soodustuseKogus,
                    Nach: soodustuseSumma,
                    Info: row.muud && row.muud !== '0' ? row.muud.replace('päeva', 'pv') : '',
                    SrokOpl: tahtaeg,
                    VhSaldo: false
                };
                // вставка доп. строки (льготы)
                csvData.push(obj);
            }

        });

        let csv = getCSV(csvData);
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

function getCode(newCode, isBonus) {
    let oldCode = '';
    switch (newCode) {
        case '322020-014':
            oldCode = '14';
            if (isBonus) {
                oldCode = '34';
            }
            break;
        case '322020-015':
            oldCode = '15';
            if (isBonus) {
                oldCode = '35';
            }
            break;
        case '322020-061':
            oldCode = '61';
            break;
        case '322030-016':
            oldCode = '16';
            if (isBonus) {
                oldCode = '36';
            }
            break;
        case '322030-017':
            oldCode = '17';
            if (isBonus) {
                oldCode = '37';
            }
            break;
        case '322030-066':
            oldCode = '66';
            break;
        case '322040-003':
            oldCode = '3';
            break;
        case '322040-004':
            oldCode = '4';
            break;
        case '322040-005':
            oldCode = '5';
            break;
        case '322040-006':
            oldCode = '6';
            break;
        case '322040-007':
            oldCode = '7';
            break;
        case '322040-008':
            oldCode = '8';
            break;
        case '322040-009':
            oldCode = '9';
            break;
        case '322040-010':
            oldCode = '10';
            break;
        case '322040-033':
            oldCode = '33';
            break;
        case '322090-003':
            oldCode = '3';
            break;
        case '322090-053':
            oldCode = '53';
            break;
        case '322040-053':
            oldCode = '53';
            break;
        case '322040-054':
            oldCode = '54';
            break;
        case '322040-055':
            oldCode = '55';
            break;
        case '322040-056':
            oldCode = '56';
            break;
        case '322040-057':
            oldCode = '57';
            break;
        case '322040-058':
            oldCode = '58';
            break;
        case '322040-059':
            oldCode = '59';
            break;
        case '322040-060':
            oldCode = '60';
            break;
        case '322020-084':
            oldCode = '84';
            break;
        case '322030-085':
            oldCode = '85';
            break;
        default:
            oldCode = '';
    }
    return oldCode;
}
