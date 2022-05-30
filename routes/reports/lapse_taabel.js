'use strict';
const getCSV = require('./../lapsed/get_csv');
const getParameterFromFilter = require('./../../libs/getParameterFromFilter');
const Moment = require('moment');
exports.get = async (req, res) => {
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
    const user =await require('../../middleware/userData')(req, uuid); // данные пользователя

    let filterData = filter && filter.length ? JSON.parse(filter): [];

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

        data.data.forEach(row => {
            let kasSoodustus = false;

            let arvKpv = Moment(row.aasta.toString() + '-' + row.kuu.toString() + '-' + '05', "YYYY-MM-DD").add(1, 'month') .format("DD.MM.YYYY");
            let tahtaeg = Moment(row.aasta.toString() + '-' + row.kuu.toString() + '-' + '19', "YYYY-MM-DD").add(1, 'month') .format("DD.MM.YYYY");

            if (row.kood == '322040-033') {
                // У нее размерность ВСЕГДА штуки (т.е.  разовая, от посещаемости не зависит), т.е. всегда кол-во = 1 и кол-во дней не указывается
                row.kogus = 1;
                row.muud = null;
            }


            //поправить если структура меняется
            const obj =  {
                DateNach: arvKpv,
                GodNach: row.aasta,
                MesNach: row.kuu,
                NrSch: row.viitenumber ? row.viitenumber.substring(0,row.viitenumber.length - 1): '',
                KodNach: getCode(row.kood, kasSoodustus),
                Stoim: row.hind,
                Kolich: row.kogus,
                Nach: row.summa,
                Info:  row.muud ? row.muud.replace('päeva', 'pv'): '' ,
                SrokOpl: tahtaeg,
                VhSaldo: false
            };

            if (Number(row.soodustus) > 0 && Number(row.hind) > 0 ) {
// меняем сумму на полную
                obj.Nach = Number(row.kogus) * Number(row.hind);
                kasSoodustus = true;
            }


            // will add header to file
            if (!header) {
                header = Object.keys(obj).join(';') + '\n';
            }

            csvData.push(obj);

            if (kasSoodustus) {

                row.kogus = Number(row.soodustus) /  Number(row.hind);

            // делаем доп. вставку в массив
                const obj =  {
                    DateNach: arvKpv,
                    GodNach: row.aasta,
                    MesNach: row.kuu,
                    NrSch: row.viitenumber ? row.viitenumber.substring(0,row.viitenumber.length - 1): '',
                    KodNach: getCode(row.kood, kasSoodustus),
                    Stoim: -1 * Number(row.hind),
                    Kolich: row.kogus,
                    Nach: -1 * Number(row.soodustus),
                    Info:  row.muud ? row.muud.replace('päeva', 'pv'): '' ,
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
        default:
            oldCode = '';
    }
    return oldCode;
}
