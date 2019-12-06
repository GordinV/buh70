const builder = require('xmlbuilder');
const l_now = require('./../../libs/getNow')();

const get_sepa = (maksed, asutusConfig) => {
    let totalAmount = 0;

    const data = [];

    maksed.forEach((mk) => {
        data.push(Object.assign({}, mk.row[0], {details: mk.details}));
    });

    data.forEach(mk => {
        totalAmount = totalAmount + Number(mk.summa);
    });


    const eMK = {
        Document: {
            '@xmlns': "urn:iso:std:iso:20022:tech:xsd:pain.001.001.03",
            '@xmlns:xsi': "http://www.w3.org/2001/XMLSchema-instance",
            '@xsi:schemaLocation': "urn:iso:std:iso:20022:tech:xsd:pain.001.001.03 pain.001.001.03.xsd",
            CstmrCdtTrfInitn: {
                GrpHdr: {
                    MsgId: Date.now(),
                    CreDtTm:l_now,
                    NbOfTxs:maksed.length,
                    CtrlSum:totalAmount,
                    InitgPty:asutusConfig.asutus.trim()
                },
                PmtInf: data.map(mk => {
                    return {
                        PmtInfId: mk.number,
                        PmtMtd:'TRF',
                        BtchBookg:true,
                        NbOfTxs:maksed.length,
                        CtrlSum: totalAmount,
                        PmtTpInf: {
                            SvcLvl: {
                                Cd: 'SEPA'
                            }
                        },
                        ReqdExctnDt: l_now,
                        Dbtr: {
                            Nm: asutusConfig.asutus.trim(),
                            PstlAdr: {
                                Ctry:'EE'
                            }
                        },
                        DbtrAcct: {
                            Id: {
                                IBAN: mk.omaarve
                            },
                            Ccy:'EUR'
                        },
                        DbtrAgt:{
                            FinInstnId:{
                                BIC:getBIC(mk.pank)
                            }
                        },
                        ChrgBr: 'SLEV',
                        CdtTrfTxInf: mk.details.map(row => {
                            return {
                                PmtId: {
                                    InstrId: mk.number
                                },
                                Amt: {
                                    InstdAmt: {
                                        '@Ccy':"EUR", '#text': Number(row.summa).toFixed(2)
                                    }

                                },
                                Cdtr: {
                                    Nm: row.asutus
                                },
                                CdtrAcct: {
                                    Id:{
                                        IBAN:row.aa
                                    }
                                },
                                RmtInf: {
                                    Ustrd: row.selg,
                                    Strd: {
                                        CdtrRefInf:{
                                            Tp: {
                                                CdOrPrtry:{
                                                    Cd: 'SCOR'
                                                }
                                            },
                                            Ref: row.viitenr
                                        }
                                    }
                                }
                            }
                        })
                    }


                })
            }
        },
    };
    return builder.create(eMK, {encoding: 'utf-8', allowSurrodateChars:true}).end({pretty: true});
};


module.exports = get_sepa;


function getBIC(kood) {
    l_result = 'HABAEE2X';
    switch(kood) {
        case 401:
            l_result = 'EEUHEE2X';
            break;
        case 767:
            l_result = 'HABAEE2X';
            break;
        case 728:
            l_result = 'NDEAEE2X';
            break;

    }
    return l_result;
}

function getMaksed() {
    return [{"row":[{"id":1616675,"docs_ids":[0,1616676,1616677,1616678],"created":"03.12.2019 05:12:44","lastupdate":"03.12.2019 06:12:34","number":"7","maksepaev":"2019-12-03","maksepaev_print":"03.12.2019","viitenr":"","aa_id":2,"pank":401,"omaarve":"EE051010562011276005","rekvid":63,"kpv":"2019-12-03","kpv_print":"03.12.2019","selg":"test","muud":null,"opt":1,"arvid":0,"aaid":2,"arvnr":null,"summa":"100.00","konto":"201000","dokprop":"sideteenused","doklausid":2358,"koostaja":"temp","lapse_nimi":"Mark","lapsid":16}],"details":[{"userid":70,"kood":"PANK","nimetus":"SEB Uhispank AS","asutus":"Svetlana Tsaikina","aadress":"Kangelaste 24-3, Narva","parent_id":1616675,"id":82666,"parentid":283608,"asutusid":30978,"nomid":744,"summa":"100.0000","aa":"EE671010562013153003","pank":null,"journalid":1616678,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"konto":"10300001","tp":null,"tunnus":"","proj":"","valuuta":"EUR","kuurs":"1.0000","lausnr":6099}],"gridConfig":[{"id":"id","name":"id","width":"0px","show":false,"type":"text","readOnly":true},{"id":"nimetus","name":"Nimetus","width":"100px","show":true,"type":"text","readOnly":false},{"id":"nomid","name":"nomid","width":"200px","show":false},{"id":"asutus","name":"Saaja","width":"200px","show":true,"type":"text","readOnly":false},{"id":"aa","name":"Arveldus arve","width":"150px","show":true,"type":"text","readOnly":false},{"id":"summa","name":"Summa","width":"100px","show":true,"type":"number","readOnly":false},{"id":"konto","name":"Korr.konto","width":"100px","show":true,"type":"text","readOnly":false},{"id":"tunnus","name":"Tunnus","width":"100px","show":true,"type":"text","readOnly":false},{"id":"proj","name":"Projekt","width":"100px","show":true,"type":"text","readOnly":false},{"id":"lausnr","name":"Lausend","width":"100px","show":true,"type":"text","readOnly":false}],"relations":[{"id":1616676,"userid":70,"doc_type":"JOURNAL","name":"Lausendid"},{"id":1616678,"userid":70,"doc_type":"JOURNAL","name":"Lausendid"},{"id":1616677,"userid":70,"doc_type":"JOURNAL","name":"Lausendid"}]},{"row":[{"id":1616680,"docs_ids":[1616591,1616591,1616591],"created":"04.12.2019 04:12:43","lastupdate":"04.12.2019 04:12:48","number":"8","maksepaev":"2019-12-04","maksepaev_print":"04.12.2019","viitenr":"","aa_id":2,"pank":401,"omaarve":"EE051010562011276005","rekvid":63,"kpv":"2019-12-04","kpv_print":"04.12.2019","selg":"test","muud":null,"opt":1,"arvid":1616591,"aaid":2,"arvnr":"Number:50 Kuupäev:2019-11-30 Jääk:0.00","summa":"4.00","konto":"","dokprop":null,"doklausid":0,"koostaja":"temp","lapse_nimi":"Mark","lapsid":16}],"details":[{"userid":70,"kood":"AVAR","nimetus":"Avansiaruanne-v","asutus":"Svetlana Tsaikina","aadress":"Kangelaste 24-3, Narva","parent_id":1616680,"id":82668,"parentid":283610,"asutusid":30978,"nomid":16166,"summa":"4.0000","aa":"EE671010562013153003","pank":null,"journalid":null,"kood1":"01112","kood2":"LE-P","kood3":"","kood4":"","kood5":"5513","konto":"551300","tp":"800699","tunnus":"OSAK                ","proj":"","valuuta":"EUR","kuurs":"1.0000","lausnr":null}],"gridConfig":[{"id":"id","name":"id","width":"0px","show":false,"type":"text","readOnly":true},{"id":"nimetus","name":"Nimetus","width":"100px","show":true,"type":"text","readOnly":false},{"id":"nomid","name":"nomid","width":"200px","show":false},{"id":"asutus","name":"Saaja","width":"200px","show":true,"type":"text","readOnly":false},{"id":"aa","name":"Arveldus arve","width":"150px","show":true,"type":"text","readOnly":false},{"id":"summa","name":"Summa","width":"100px","show":true,"type":"number","readOnly":false},{"id":"konto","name":"Korr.konto","width":"100px","show":true,"type":"text","readOnly":false},{"id":"tunnus","name":"Tunnus","width":"100px","show":true,"type":"text","readOnly":false},{"id":"proj","name":"Projekt","width":"100px","show":true,"type":"text","readOnly":false},{"id":"lausnr","name":"Lausend","width":"100px","show":true,"type":"text","readOnly":false}],"relations":[{"id":1616591,"userid":70,"doc_type":"ARV","name":"Arved"}]}];
}
