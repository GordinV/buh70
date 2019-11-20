const builder = require('xmlbuilder');

const data = [{
    id: 1,
    aa: "EE122200221021743743",
    aadress: "Aadress",
    arvi: 0,
    asutus: "",
    asutusid: 29004,
    bpm: "",
    created: "",
    doc: "",
    doc_status: 0,
    doc_type_id: "",
    doklausid: 2029,
    dokprop: "",
    is_show_journa: 0,
    jaak: 0,
    journalid: 0,
    kbm: 24.7000,
    kbmkonto: "",
    kbmta: 123.5000,
    kmkr: "",
    konto: "",
    koostaja: "",
    kpv: "2019-09-26",
    lastupdat: "",
    laus_nr: 0,
    liik: 1,
    lisa: "lisa",
    muud: "muud",
    number: "163/9",
    objekt: "",
    objektid: 0,
    operid: 0,
    regkood: "1234567",
    rekvid: 64,
    status: "",
    summa: 148.2000,
    tahtaeg: "20191231",
    tasud: "        ",
    tasudok: "",
    userid: 70,
    viitenr: "0630000386",
    gridData: [
        {
            formula: "",
            hind: 0.3167,
            id: 1,
            kbm: 24.7000,
            kbmta: 123.5000,
            km: "20",
            kogus: 390,
            konto: "552690",
            kood: "",
            kood1: "",
            kood2: "",
            kood3: "",
            kood4: "",
            kood5: "",
            kuurs: 0,
            muud: "transporditeenused, Narva-Tartu-Narva, ?????????? ??????? , Hariduse 28-62, 25.09.2019",
            nimetus: "transporditeenused, Narva-Tartu-Narva, ?????????? ??????? , Hariduse 28-62, 25.09.2019",
            nomid: 17751,
            proj: "",
            soodus: 0,
            summa: 148.2000,
            tp: "800399",
            tunnus: "",
            uhik: "",
            userid: 0,
            valuuta: "",
            vastisik: ""
        },
        {
            formula: "",
            hind: 0.3167,
            id: 2,
            kbm: 24.7000,
            kbmta: 123.5000,
            km: "20",
            kogus: 390,
            konto: "552690",
            kood: "",
            kood1: "",
            kood2: "",
            kood3: "",
            kood4: "",
            kood5: "",
            kuurs: 0,
            muud: "transporditeenused, Narva-Tartu-Narva, ?????????? ??????? , Hariduse 28-62, 25.09.2019",
            nimetus: "transporditeenused, Narva-Tartu-Narva, ?????????? ??????? , Hariduse 28-62, 25.09.2019",
            nomid: 17751,
            proj: "",
            soodus: 0,
            summa: 148.2000,
            tp: "800399",
            tunnus: "",
            uhik: "",
            userid: 0,
            valuuta: "",
            vastisik: ""
        },
    ]
}];
const user = {
    userId: 70,
    userName: 'Vlad',
    userIndex: null,
    asutus: 'Rahandusaamet',
    regkood: '7654321',
    asutusId: 63
};

/**
 *вернет массив сгруппированных по налогу сумм
 * @param data - детали счета с суммами
 */
const getVat = (data) => {
    const vatArray = [];
    const vatTotals = [];

    // делаем уникальный массив ставок налога
    data.forEach(rea => {
        let vat = (rea.km || rea.km) === '-' ? '0' : rea.km;
        vatArray.push(vat);
    });

    let unique = [...new Set(vatArray)];

// суммируем
    unique.forEach((vat) => {
        let summa = 0;
        let kbm = 0;
        data.forEach(rea => {
            let fixedVat = (rea.km || rea.km) === '-' ? '0' : rea.km;
            if (fixedVat === vat) {
                summa = summa + rea.summa;
                kbm = kbm + rea.kbm;
            }
        });

        // push
        vatTotals.push({vatRate: vat, summa: summa, vatSum: kbm});
    });
    return vatTotals;
};

const get_earve = (data, user) => {
    let totalAmount = 0 ;
    data.forEach(arve => {
        totalAmount = totalAmount + arve.summa;
    });

    const obj = {
        E_Invoice: {
            Header: {
                date: data.kpv,
                FileId: data.id,
                AppId: 'EARVE',
                Version: '1.1'
            },
            Invoice: data.map(arve => {
                // считаем налоги
                const qryeArvedVat = getVat(arve.gridData);

                // детали счета
                const qryeArvedDet = arve.gridData.map(rea => {
                    return {
                        vatRate: (rea.km || rea.km === '-') ? '0' : rea.km,
                        vat_summa: rea.kbm.toFixed(2),
                        Description: `${rea.nimetus} ${rea.muud ? rea.muud : ''}`,
                        ItemUnit: rea.uhik,
                        ItemAmount: rea.kogus,
                        ItemPrice: rea.hind.toFixed(2),
                        ItemSum: (rea.summa - rea.kbm).toFixed(2),
                        vatSum: rea.kbm.toFixed(2),
                        ItemTotal: rea.summa.toFixed(2)
                    }
                });

                return {
                '@invoiceId': arve.number,
                '@regNumber': arve.regkood,
                InvoiceParties: {
                    SellerParty: {
                        name: user.asutus,
                        RegNumber: user.regkood,
                    },
                    BuyerParty: {
                        Name: arve.asutus,
                        RegNumber: arve.regkood,
                    }
                },
                InvoiceInformation: {
                    Type: {
                        '@type': "DEB"
                    },
                    ContractNumber: arve.lisa,
                    DocumentName: 'Arve',
                    InvoiceNumber: arve.number,
                    InvoiceContentText: arve.muud,
                    InvoiceDate: arve.kpv,
                    DueDate: arve.tahtaeg,
                    InvoiceDeliverer: {
                        ContactName: user.userName
                    }
                },
                InvoiceSumGroup:
                    Object.assign({InvoiceSum: arve.summa.toFixed(2)}, {qryeArvedVat}, {TotalSum: arve.summa.toFixed(2)}, {Currency: 'EUR'}),
                InvoiceItem: {
                    InvoiceItemGroup: {
                        itemEntry: qryeArvedDet
                    }
                },
                PaymentInfo: {
                    Currency: 'EUR',
                    PaymentRefId: arve.viitenr,
                    PaymentDescription: `Arve ${arve.number}`,
                    Payable: 'YES',
                    PayDueDate: arve.tahtaeg,
                    PaymentTotalSum: arve.summa.toFixed(2),
                    PayerName: arve.asutus,
                    PaymentId: arve.number,
                    PayToAccount: arve.arve,
                    PayToName: user.asutus
                }

            }}),
            Footer: {
                TotalNumberInvoices:data.length,
                TotalAmount: totalAmount.toFixed(2)
            }
        }
    };

    return builder.create(obj).end({pretty: true});
};


module.exports = get_earve;

let xml = get_earve(data, user);
console.log(xml);

/*
			IIF(a.liik = 0,Iif(!Isnull(qryRekv.muud),qryRekv.muud,qryRekv.nimetus), Alltrim(a.asutus) + ' ' + Alltrim(a.omvorm))  As muuja,;
			IIF(a.liik = 1 ,Iif(!Isnull(qryRekv.muud),qryRekv.muud,qryRekv.nimetus),Alltrim(a.asutus) + ' ' + Alltrim(a.omvorm)) As ostja,;
			IIF(a.liik = 0, qryRekv.regkood,Alltrim(a.regkood)) As muuja_regkood,;
			IIF(a.liik = 1, qryRekv.regkood,Alltrim(a.regkood)) As ostja_regkood,;
			IIF(a.liik = 1, qryRekv.aadress,asutus.aadress) As ostja_aadress,;
			IIF(a.liik = 1, qryRekv.email,Alltrim(asutus.email)) As ostja_email,;
			IIF(a.liik = 0, qryRekv.aadress, Alltrim(asutus.aadress)) As muuja_aadress,;
			IIF(a.liik = 0 , qryRekv.email , Alltrim(asutus.email)) As muuja_email,;
			IIF(a.liik = 0, qryRekv.tel, Alltrim(asutus.tel)) As muuja_tel,;


           '@xmlns': 'http://www.emta.ee/inf3',
            '@xmlns:xsi': "http://www.w3.org/2001/XMLSchema-instance",
            '@tyyp': "inf3",
            '@xsi:schemaLocation': "http://www.emta.ee/inf3 inf3.xsd",
            saatja_regkood: user.regkood,
            period: {
                aasta: aasta
            },

 */

/*
    const kirje = data.map(kiri => {
        return {
            koolitusmaksja_isikukood: kiri.maksja_isikukood,
            koolitatava_isikukood: kiri.lapse_isikukood,
            makstud_summa: kiri.summa,
            koolituse_liik: 3
        };

    });
*/

/*
    obj.deklaratsioon.inf3 = {kirje};
*/
