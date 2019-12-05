const builder = require('xmlbuilder');
const l_now = require('./../../libs/getNow')();

/**
 *вернет массив сгруппированных по налогу сумм
 * @param data - детали счета с суммами
 */
const getVat = (data) => {
    const vatArray = [];
    const vatTotals = [];

    // делаем уникальный массив ставок налога
    data.forEach(rea => {
        let vat = (!rea.km || rea.km == '' || rea.km == '-') ? '0' : rea.km;
        vatArray.push(vat);
    });

    let unique = [...new Set(vatArray)];

// суммируем
    unique.forEach((vat) => {
        let summa = 0;
        let kbm = 0;
        data.forEach(rea => {
            let fixedVat = (!rea.km || rea.km == '' || rea.km == '-') ? '0' : rea.km;
            if (fixedVat === vat) {
                summa = summa + rea.summa;
                kbm = kbm + rea.kbm;
            }
        });

        // push
        vatTotals.push({VATRate: vat, VATSum: Number(kbm).toFixed(2)});
    });
    return vatTotals;
};

const get_earve = (arved, asutusConfig, isOmniva = true) => {
    let totalAmount = 0;
    const data = arved.map((arve, index) => {
        const row = arve[index].row[0];
        const details = arve[index].details;
        return Object.assign({}, row, {details: details})
    });

    data.forEach(arve => {
        totalAmount = totalAmount + Number(arve.summa);
    });

    const eArve = {
        Header: {
            Date: l_now,
            FileId: Date.now(),
            AppId: 'EARVE',
            Version: '1.1'
        },
        Invoice: data.map(arve => {
            // считаем налоги

            const qryeArvedVat = getVat(arve.details);

            // детали счета
            const qryeArvedDet = arve.details.map(rea => {
                return {
                    Description: `${rea.nimetus.trim()} ${rea.muud ? rea.muud.trim() : ''}`,
                    ItemDetailInfo: {
                        ItemUnit: rea.uhik.trim(),
                        ItemAmount: rea.kogus,
                        ItemPrice: Number(rea.hind).toFixed(2),
                    },
                    ItemSum: Number(rea.summa - rea.kbm).toFixed(2),
                    VAT: {
                        SumBeforeVAT: rea.summa - rea.kbm,
                        VATRate: (!rea.km || rea.km == '-' || rea.km == '') ? '0' : rea.km,
                        VATSum: Number(rea.kbm).toFixed(2),
                        Currency: 'EUR',
                    },
                    ItemTotal: Number(rea.summa).toFixed(2)
                }
            });

            return {
                '@invoiceId': arve.number,
                '@regNumber': arve.regkood.trim(),
                InvoiceParties: {
                    SellerParty: {
                        Name: asutusConfig.asutus.trim(),
                        RegNumber: asutusConfig.regkood.trim(),
                    },
                    BuyerParty: {
                        Name: arve.asutus,
                        RegNumber: arve.regkood.trim(),
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
                        ContactName: asutusConfig.userName
                    }
                },
                InvoiceSumGroup:
                    Object.assign({InvoiceSum: Number(arve.summa).toFixed(2)},
                        {VAT: qryeArvedVat["0"]},
                        {TotalSum: Number(arve.summa).toFixed(2)},
                        {Currency: 'EUR'}),
                InvoiceItem: {
                    InvoiceItemGroup: {
                        ItemEntry: qryeArvedDet
                    }
                },
                PaymentInfo: {
                    Currency: 'EUR',
                    PaymentRefId: arve.viitenr,
                    PaymentDescription: `Arve ${arve.number}`,
                    Payable: 'YES',
                    PayDueDate: arve.tahtaeg,
                    PaymentTotalSum: Number(arve.summa).toFixed(2),
                    PayerName: arve.asutus,
                    PaymentId: arve.number,
                    PayToAccount: arve.arve,
                    PayToName: asutusConfig.asutus
                }

            }
        }),
        Footer: {
            TotalNumberInvoices: data.length,
            TotalAmount: totalAmount.toFixed(2)
        }
    };


    const omnivaObj = {
        'soapenv:Envelope': {
            '@xmlns:soapenv': "http://schemas.xmlsoap.org/soap/envelope/",
            '@xmlns:erp': "http://e-arvetekeskus.eu/erp",
            'soapenv:Header': '',
            'soapenv:Body': {
                'erp:EInvoiceRequest': {
                    '@authPhrase': asutusConfig.secret,
                    E_Invoice: eArve
                }
            }
        }
    };


    const obj = isOmniva ? omnivaObj: {E_Invoice: eArve};

    return builder.create(obj, {encoding: 'utf-8'}).end({pretty: true});
};


module.exports = get_earve;


