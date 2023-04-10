const builder = require('xmlbuilder');
const getNow = require('./../../libs/getNow');
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

/**
 * расчитает дату платежа исходя из даты
 * @param kpv
 * @returns {date}
 */
const getPayDueDate = (kpv) => {
    let l_kpv = new Date(kpv);
    let l_pay_dt = new Date(l_kpv.getFullYear(), l_kpv.getMonth(), 20);
    let l_balance_dt = new Date(l_kpv.getFullYear(), l_kpv.getMonth(), 1);

    // Не так.Если счет выставлен с 10-го числа этого месяца по 9-е число следующего месяца, то ставим 20 число следующего
    if (l_kpv.getDate() > 10) {
        l_pay_dt = new Date(l_pay_dt.setMonth(l_pay_dt.getMonth() + 1));
    }
    return l_pay_dt.toISOString().substring(0, 10);
};


const get_earve = (arved, asutusConfig, isOmniva = true) => {
    let totalAmount = 0;

    const data = [];

    arved.forEach((arve, index) => {
        //  подготовим данные
        data.push(Object.assign({}, arve, {details: arve.details}));
    });

    data.forEach(arve => {
        if (Number(arve.tasumisele) > 0 ) {
            totalAmount = totalAmount + Number(arve.tasumisele);
        }
    });

    let Header = {
        Test: 'NO',
        Date: getNow(),
        FileId: Date.now(),
        AppId: 'EARVE',
        Version: '1.11'
    };

    if (asutusConfig.ReceiverId) {
        Header = Object.assign(Header, {
            SenderId: asutusConfig.SenderId,
            ReceiverId: asutusConfig.ReceiverId
        });
    }

    const eArve = {
        Header: Header,
        Invoice: data.map(arve => {
            // считаем налоги
            const qryeArvedVat = getVat(arve.details);

            //  дата выплаты
            let payDueDate = getPayDueDate(arve.kpv);

            // детали счета
            const qryeArvedDet = arve.details.map(rea => {
                return {
                    Description: `${rea.nimetus.trim()} ${rea.muud ? rea.muud.trim() : ''}`,
                    ItemDetailInfo: {
                        ItemUnit: rea.uhik.trim(),
                        ItemAmount: Number(rea.kogus).toFixed(4),
                        ItemPrice: Number(rea.tais_hind).toFixed(2)
                    },
                    ItemSum: Number(rea.kbmta).toFixed(2),
                    Addition: {
                        AddContent: 'Soodustus',
                        AddSum: rea.soodustus,
                        '@addCode': "DSC"
                    },
                    VAT: {
                        VATRate: rea.km,
                        VATSum: rea.kbm
                    },
                    ItemTotal: Number(rea.summa).toFixed(2)
                }
            });

            return {
                '@invoiceId': arve.number,
                '@serviceId': arve.viitenr, // viitenr
                '@regNumber': arve.regkood,
                '@channelId': asutusConfig.type ? asutusConfig.channelId : null,
                '@channelAddress': asutusConfig.type ? arve.iban : null,
                '@presentment': asutusConfig.type ? 'YES' : null,
                '@invoiceGlobUniqId': asutusConfig.type ? arve.id : null,
                '@sellerContractId': asutusConfig.type && asutusConfig.type == 'swed' ? asutusConfig.swed : asutusConfig.type ? asutusConfig.seb : null,
                '@sellerRegnumber': asutusConfig.regkood,

                InvoiceParties: {
                    SellerParty: {
                        Name: asutusConfig.asutus,
                        RegNumber: asutusConfig.regkood,
                        ContactData: {
                            LegalAddress: {
                                PostalAddress1: 'Peetri pl. 1',
                                City: 'Narva',
                                PostalCode: '20308',
                                Country: 'EE'
                            },
                            ContactInformation: {
                                InformationContent: 'Klienditeenindus: tel 3599035, e-mail ostjad@narvakultuur.ee'
                            }
                        },
                        AccountInfo: {
                            AccountNumber: asutusConfig.payToAccount,
                            IBAN: asutusConfig.payToAccount,
                            BIC: asutusConfig.channelId,
                            BankName: asutusConfig.BankName
                        }

                    },
                    BuyerParty: {
                        Name: arve.asutus,
                        RegNumber: arve.regkood,
                        ContactData: {
                            LegalAddress: {
                                PostalAddress1: arve.aadress ? arve.aadress: '',
                                City: 'Narva',
                                PostalCode: '',
                                Country: 'EE'
                            }
                        },
                        AccountInfo: {
                            AccountNumber: arve.iban,
                            IBAN: arve.iban,
                            BIC: arve.pank == 'SWED' ? 'HABAEE2X' : 'EEUHEE2X',
                            BankName: arve.pank == 'SWED' ? 'Swedbank' : 'SEB Pank'
                        }
                    }
                },
                InvoiceInformation: {
                    Type: {
                        '@type': "DEB"
                    },
                    ContractNumber: arve.lisa,
                    DocumentName: 'Arve',
                    InvoiceNumber: arve.number,
                    InvoiceDate: arve.kpv,
                    DueDate: arve.tahtaeg,
                    Period: {
                        PeriodName: arve.laekumise_period
                    },
                },
                InvoiceSumGroup: {
                    Balance: {
                        BalanceDate: arve.balance_day,
                        BalanceBegin: Number(arve.alg_jaak).toFixed(2),
                        Inbound: Number(arve.laekumised).toFixed(2),
                        Outbound: arve.tagastused ? Number(arve.tagastused).toFixed(2) : 0,
                        BalanceEnd: Number(arve.tasumisele).toFixed(2)
                    },
                    TotalSum: Number(arve.summa).toFixed(2),
                    TotalToPay: Number(arve.tasumisele).toFixed(2),
                    Currency: 'EUR'
                },
                InvoiceItem: {
                    InvoiceItemGroup: {
                        ItemEntry: qryeArvedDet
                    }
                },
                AdditionalInformation: {
                    InformationName: 'Teenuste saaja, asutus, periood',
                    InformationContent: `${arve.lapse_nimi}, ${arve.tais_nimetus}, ${arve.laekumise_period}`
                },
                PaymentInfo: {
                    Currency: 'EUR',
                    PaymentRefId: arve.viitenr, //arve.viitenr
                    PaymentDescription: `Arve ${arve.number}`,
                    Payable: 'YES',
                    PayDueDate: payDueDate,
                    PaymentTotalSum: Number(arve.tasumisele) < 0 ? 0 : Number(arve.tasumisele).toFixed(2),
                    PayerName: arve.asutus,
                    PaymentId: arve.number,
                    PayToAccount: asutusConfig.payToAccount,
                    PayToName: asutusConfig.asutus,
                    PayToBIC: asutusConfig.channelId
                }

            }
        }),
        Footer: {
            TotalNumberInvoices: data.length,
            TotalAmount: totalAmount.toFixed(2)
        }
    };

    let obj;
    let l_xml;
    if (isOmniva) {
        obj = {
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
        l_xml = builder.create(obj, {encoding: 'utf-8'});
        l_xml = l_xml.end({pretty: true});

    } else {
        obj = {
            E_Invoice: eArve
        };

        l_xml = builder.create(obj, {encoding: 'utf-8'});
        l_xml.att('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        l_xml.att('xsi:noNamespaceSchemaLocation', 'e-invoice_ver1.11.xsd');
        l_xml = l_xml.end({pretty: true});

    }

    return l_xml;
};

module.exports = get_earve;


