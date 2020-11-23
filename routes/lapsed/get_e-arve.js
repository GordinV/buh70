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

const get_earve = (arved, asutusConfig, isOmniva = true) => {
    let totalAmount = 0;

    const data = [];

    arved.forEach((arve, index) => {
        //  подготовим данные
        data.push(Object.assign({}, arve.row[0], {details: arve.details}));
    });

    data.forEach(arve => {
        totalAmount = totalAmount + Number(arve.tasumisele);
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

            // детали счета
            const qryeArvedDet = arve.details.map(rea => {
                return {
                    Description: `${rea.nimetus.trim()} ${rea.muud ? rea.muud.trim() : ''}`,
                    /*
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
                    */
                    ItemTotal: Number(rea.summa).toFixed(2)
                }
            });

            return {
                '@invoiceId': arve.number,
                '@serviceId': arve.viitenr,
                '@regNumber': arve.regkood.trim(),
                '@channelId': asutusConfig.type ? asutusConfig.channelId : null,
                '@channelAddress': asutusConfig.type ? arve.iban : null,
                '@presentment': asutusConfig.type ? 'YES' : null,
                '@invoiceGlobUniqId': asutusConfig.type ? arve.id : null,
                '@sellerContractId': asutusConfig.type && asutusConfig.type == 'swed' ? asutusConfig.swed : asutusConfig.type ? asutusConfig.seb : null,
                '@sellerRegnumber': asutusConfig.regkood.trim(),

                InvoiceParties: {
                    SellerParty: {
                        Name: asutusConfig.asutus.trim(),
                        RegNumber: asutusConfig.regkood.trim(),
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
                            BIC: asutusConfig.channelId
                        }

                    },
                    BuyerParty: {
                        Name: arve.asutus,
                        RegNumber: arve.regkood.trim(),
                        ContactData: {
                            LegalAddress: {
                                PostalAddress1: arve.aadress,
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
                    }
                },
                InvoiceSumGroup: {
                    Balance: {
                        BalanceDate: arve.period_alg,
                        BalanceBegin: Number(arve.alg_jaak).toFixed(2),
                        Inbound: Number(arve.laekumised).toFixed(2),
                        Outbound: Number(arve.tagastused).toFixed(2),
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
                PaymentInfo: {
                    Currency: 'EUR',
                    PaymentRefId: arve.viitenr,
                    PaymentDescription: `Arve ${arve.number}`,
                    Payable: 'YES',
                    PayDueDate: arve.tahtaeg,
                    PaymentTotalSum: Number(arve.tasumisele).toFixed(2),
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


    const obj = isOmniva ? omnivaObj : {E_Invoice: eArve};

    return builder.create(obj, {encoding: 'utf-8'}).end({pretty: true});
};

module.exports = get_earve;


