'use strict';
const builder = require('xmlbuilder');
const getCSV = require('./../lapsed/get_csv');

const getParameterFromFilter = require('./../../libs/getParameterFromFilter');
const crypto = require("crypto");
const db = require("../../libs/db");
const config = require("../../config/narvalv.json");
const DocContext = require("../../frontend/doc-context");
const Doc = require("../../classes/DocumentTemplate");
const {asutusId} = require("../../test/fixture/userData");
const _ = require('lodash');


exports.get = async (req, res) => {
    let hash = (req.params.hash || ''); // параметр rekvid
    let fileType = req.query.fileType || 'csv';
    let kpv1 = req.query.kpv1;
    let kpv2 = req.query.kpv2;
    let kond = req.query.kond;
    const sqlWhere = req.params.params || '';// параметр sqlWhere документа
    const filter = req.params.filter || [];// массив фильтров документов;
    const uuid = req.params.uuid || ''; // параметр uuid пользователя
//    const user =await require('../../middleware/userData')(req, uuid); // данные пользователя

    let rekvId = await getRekvIdFromHash(hash);

    console.log('start rekvId', rekvId)

    const user = {
        userId: 5231, // palk
        asutusId: rekvId
    };
    if (!user) {
        console.error('error 401 newAPI');
        return res.status(401).end();
    }
//    const data = [{id: 1, nimetus: 'try 1', rekvId: user.asutusId, test: 'true', kpv: kpv, 'fileType': fileType}];

    const Doc = require('./../../classes/DocumentTemplate');
    const doc = new Doc('tsd_lisa1', null, user.userId, user.asutusId, 'palk');
    let gridParams = [kpv1, kpv2, user.asutusId, kond];

    const data = await doc.selectDocs('', '', 100000, gridParams);

    console.log('fileType', fileType)

    if (data && !data.data.length) {
        return res.status(500).send('Puuduvad andmed, võib olla aasta ei ole märgistatud');
    }


    var outputFile;
    if (fileType === 'csv') {
        // csv
        let header;
        outputFile = getCSV(data.data.map(row => {
                //поправить если структура меняется
                //поправить если структура меняется
                const obj = {
                    108: row.aasta,
                    109: row.kuu,
                    laadimisViis: 'L',
                    vorm: 'TSD',
                    1000: row.isikukood,
                    1010: row.nimi,
                    1020: row.tululiik,
                    1030: row.summa,
//                    v1040: row.v1040,
//                    1050: row.v1050 ? row.v1050 : '',
                    1060: (row.sm_arv * row.summa) || 0,
//                    1070: row.v1070,
//                    1080: row.v1080,
//                    1090: row.v1090,
                    1100: row.tululiik == '24' ? null : row.sm,
                    1110: row.tululiik == '24' ? null : row.pm,
                    1120: row.v1120,
                    1130: row.tululiik == '24' ? null : row.tki,
                    1140: row.tululiik == '24' ? null : row.tka,
                    1150: row.tuli_kood,
                    1160: row.tulubaas,
                    1170: row.tululiik == '24' ? null : vm.tm,
//                    1160_610: row.v1160_610,
//                    1160_640: row.v1160_640,
//                    1160_650: row.v1160_650
                };

                // will add header to file
                if (!header) {
                    header = Object.keys(obj).join(';') + '\n';
                }
                console.log('row', obj);
                return obj;
            }
        ));
        outputFile = header + outputFile;
        res.attachment('report.csv');
        res.type('csv');
    } else {
        // get xml
        const tsd = data.data[0];

        const obj = {
            tsd_vorm: {
                c108_Aasta: tsd.aasta,
                c109_Kuu: tsd.kuu,
                c110_Tm: tsd.tm_kokku,
                c115_Sm: tsd.sm_kokku,
                c116_Tk: tsd.tki_kokku,
                c117_Kp: tsd.pm_kokku,
                c118_KohustKokku: Number(tsd.tm_kokku) + Number(tsd.sm_kokku) + Number(tsd.tki_kokku) + Number(tsd.pm_kokku),
                laadimisViis: 'L',
                regKood: tsd.regkood,
                vorm: 'TSD',
                tsd_L1_0: null,
            },

        };
        const isikud = _.uniqWith(data.data.map(({isikukood, isik, v1040}) => ({isikukood, isik, v1040})), _.isEqual);

        // список работников уникальный
        const lisa1a = isikud.map(kiri => {
            const lisa1a_kiri = {
                c1000_Kood: kiri.isikukood,
                c1010_Nimi: kiri.isik
            };
            // выплаты по работнику
            const vmListData = data.data.filter(vm => {
                return vm.isikukood === kiri.isikukood && vm.tululiik;
            });

            // проверим на наличие 10 вида дохода
            let tuluLiigid = ['10','17','33'];

            let tl = vmListData.filter(tulu_liik => tuluLiigid.indexOf(tulu_liik.tululiik) !== -1);
            if (tl.length === 0) {
                // делаем пустую строку
                vmListData.splice(0,0,{tululiik: '10',summa:0, v1040: kiri.v1040, sm:0, pm:0, tki:0, tka: 0, tm:0, v1120: 0, tulubaas: 0})
            }

            // собираем строку
            lisa1a_kiri.vmList = {
                tsd_L1_A_Vm: vmListData.map((vm, idx) => {
                    return {
                        c1020_ValiKood: vm.tululiik,
                        c1030_Summa: vm.summa,
                        c1040_OtMaar: Number(vm.tululiik) < 13 ? vm.v1040 : null,
                        c1060_Smvm: (vm.sm_arv * vm.summa) || 0,
                        c1070_TvpVah: 0,
                        c1080_KuumVah: 0,
                        c1090_KuumSuur: (vm.arv_min_sots  ? vm.min_sots_alus : 0),
                        c1100_Sm: vm.tululiik == '24' ? null :vm.v1100,
                        c1110_Kp: vm.tululiik == '24' ? null : vm.pm,
                        c1130_Tk: vm.tululiik == '24' ? null : vm.tki,
                        c1140_Ttk: vm.tululiik == '24' ? null : vm.tka,
                        c1170_Tm: vm.tululiik == '24' ? null : vm.tm,
                        c1120_Tkvm: vm.v1120,
                        mvtList: vm.tulubaas == 0 ? null : {
                            tsd_L1_A_Mvt: {
                                c1150_TuliKood: vm.tuli_kood,
                                c1160_Summa: vm.tulubaas
                            }
                        }
                    }
                })
            };

            return lisa1a_kiri;
        });

        obj.tsd_vorm.tsd_L1_0 = {
            aIsikList: {
                tsd_L1_A_Isik: lisa1a
            }
        };

//        cons mvtList;

        /*
                const kirje = data.map(kiri => {
                    return {
                        koolitusmaksja_isikukood: kiri.maksja_isikukood,
                        koolitatava_isikukood: kiri.lapse_isikukood,
                        makstud_summa: kiri.summa,
                        koolituse_liik: kiri.liik
                    };
        */
        console.log('obj', obj)

        outputFile = builder.create(obj).end({pretty: true});
        res.attachment('report.xml');
        res.type('xml');
    }

    if (outputFile) {
        res.send(outputFile);
    } else {
        res.status(500).send('Error in getting file');
    }
};


async function generateHash() {
    const rekvHash = {};
    let rekvIds = await getRekvIds();
    rekvIds.forEach(rekv => {
        let hashParool = crypto.createHmac('sha1', '').update(rekv.id.toString()).digest('hex');
        rekvHash[hashParool] = rekv.id;
    });
    return rekvHash;
}

async function getRekvIds() {
    let aHash = [];
    let sql = 'select id from ou.rekv where parentid < 999';

    let rekvIds = await db.queryDb(sql, null, null, null, null, null, config);

    return rekvIds.data;
}

async function getRekvIdFromHash(hash) {
    if (!DocContext.rekvHash) {
        DocContext.rekvHash = await generateHash();
    }
    console.log('DocContext.rekvHash', DocContext.rekvHash)
    return DocContext.rekvHash[hash];
}