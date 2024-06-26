module.exports = {
    RECORDS_LIMIT: 1000,
    MAX_RECORDS_LIMIT: 5000,
    // таски
    events: {
        LAPS: [
            {name: 'Tabeli koostamine (kuni 1000)', method: 'arvestaTaabel', docTypeId: 'lapse_taabel'},
            {name: 'Tabeli koostamine (kõik)', method: 'arvestaKoikTaabelid', docTypeId: 'lapse_taabel'},
            {name: 'Arvete koostamine (kuni 1000)', method: 'koostaArved', docTypeId: 'arv'},
            {name: 'Arvete koostamine (kõik)', method: 'koostaKoikArved', docTypeId: 'arv'},
            {name: 'Ettemaksuarve koostamine', method: 'koostaEttemaksuArved', docTypeId: 'arv'},
//            {name: 'Lõpeta kõik teenused', method: 'lopetaKoikTeenused', docTypeId: 'laps'},
        ]
    },
    // извещения
    noticed: {
        gridConfig: [
            {id: "timestamp", name: "Aeg", width: "20%"},
            {id: "task_name", name: "Tegevus", width: "20%"},
            {id: "teatis", name: "Teatis", width: "60%"}]

    },
    // логи
    logs: {
        gridConfig: [
            {id: "kasutaja", name: "Kasutaja", width: "20%", show: true},
            {id: "koostatud", name: "Koostatud", width: "15%"},
            {id: "muudatud", name: "Muudatud", width: "15%"},
            {id: "prinditud", name: "Prinditud", width: "15%"},
            {id: "email", name: "Meilitud", width: "15%"},
            {id: "earve", name: "e-Arve", width: "15%"},
            {id: "kustutatud", name: "Kustutatud", width: "15%"}]

    },
    // отчет об исполнении
    tulemused: {
        gridConfig: [
            {id: "id", name: "id", width: "5%", show: false},
            {
                id: 'kas_vigane',
                name: 'Staatus',
                width: '5%',
                show: true,
                yesBackgroundColor: 'red',
                noBackgroundColor: 'green'
            },
            {id: "result", name: "Tulemused", width: "10%", show: false},
            {id: "error_message", name: "Teatis", width: "70%", show: true},
            {id: "viitenr", name: "Viitenumber", width: "15%", show: true}
        ]
    },
    // счета
    ARV: {
        LIB_OBJS: [
            {id: 'kontod', filter: ``},
            {id: 'dokProps', filter: `where kood = 'ARV'`},
            {id: 'users', filter: ''},
            {id: 'tunnus', filter: ''},
            {id: 'project', filter: ''},
            {id: 'artikkel', filter: ''},
            {id: 'allikas', filter: ''},
            {id: 'tegev', filter: ''},
            {id: 'aa', filter: ''},
            {id: 'nomenclature', filter: `where dok = 'ARV'`},
            {id: 'lapse_grupp', filter: ``}

        ]
    },
    NOMENCLATURE: {
        LIBRARIES: [
            {id: 'kontod', filter: ``},
            {id: 'tunnus', filter: ``},
            {id: 'project', filter: ``},
            {id: 'document', filter: `where kood::TEXT in ('ARV','VMK','SMK')`},
            {id: 'artikkel', filter: ``},
            {id: 'allikas', filter: ``},
            {id: 'tegev', filter: ``},
            {id: 'koolituse_liik', filter: ``},
        ],

        TAXIES: [
            {id: 1, kood: null, name: '-%'},
            {id: 2, kood: '0', name: '0%'},
            {id: 3, kood: '5', name: '5%'},
            {id: 4, kood: '10', name: '10%'},
            {id: 5, kood: '18', name: '18%'},
            {id: 6, kood: '20', name: '20%'}
        ],

        UHIK: [
            {id: 1, kood: 'muud', name: 'Muud'},
            {id: 2, kood: 'tk', name: 'Tükk'},
            {id: 3, kood: 'päev', name: 'Päev'},
            {id: 4, kood: 'kuu', name: 'Kuu'},
            {id: 5, kood: 'aasta', name: 'Aasta'}
        ],

        ALGORITMID: [
            {id: 1, kood: 'päev', name: 'Päev'},
            {id: 2, kood: 'konstantne', name: 'Konstantne'},
            {id: 3, kood: 'külastamine', name: 'Külastamine'},
        ],

        TYYP: [
            {id: 2, kood: 'SOODUSTUS', name: ' '}
        ]

    },
    LAPS: {
        LIBRARIES: [{id: 'lapse_grupp', filter: ``}],
        ERITUNNUSED: [
            {id: 1, kood: '3008', name: 'Kulud seoses pagulaste vastuvotmisega'},
        ],
        DOCS: ['ARV', 'SMK', 'VMK', 'LAPSE_TAABEL']
    },
    LAPSE_KAART: {
        LIBRARIES: [
            {id: 'nomenclature', filter: `where dok = 'ARV'`},
            {id: 'lapse_grupp', filter: ``},
            {id: 'viitenr', filter: ``}
        ]
    },
    REKV: {
        LIB_OBJS: [
            {id: 'kontod', filter: ``},
            {id: 'asutuse_liik', filter: ''}
        ]
    },
    LAPSE_GRUPP: {
        LIBRARIES: [
            {id: 'nomenclature', filter: `where dok = 'ARV'`},
            {id: 'koolituse_tyyp', filter: ``}
        ],
    },
    ASENDUS_TAABEL: {
        LIBRARIES: [
            {id: 'nomenclature', filter: `where dok = 'ARV'`},
            {id: 'lapse_grupp', filter: ``},
        ],
    },
    PAEVA_TAABEL: {
        LIBRARIES: [
            {
                id: 'lapse_grupp',
                filter: ``
            }
        ],
        FILTER_VALIDATION: [
            {
                kpv: () => {
                    console.log('validation')
                }
            }

        ]
    },
    // нода для справочников
    LIBS: {
        POST_LOAD_LIBS_URL: '/newApi/loadLibs'
    },
    // нода для документов
    DOCS: {
        POST_LOAD_DOCS_URL: '/newApi/document'
    },
    INF3_ANALUUS: {
        CONFIG: [
            {id: "maksja_nimi", name: "Maksja nimi", width: "15%", show: true},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "10%", show: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "asutus", name: "Asutus", width: "15%"},
            {id: "number", name: "Dok.number", width: "10%"},
            {id: "kpv", name: "Kuupäev", width: "8%", type: "date", interval: true},
            {id: "summa", name: "Summa", width: "7%", type: "number", interval: true},
            {id: "inf3_summa", name: "INF3 Summa", width: "7%", type: "number", interval: true},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer", show: false},
            {id: "markused", name: "Märkused", width: "10%"},
            {id: "kas_inf3", name: "Kas INF3 sisu", width: "10%", type: 'select', data: ['', 'JAH', 'EI'], show: true},
        ]
    }
}
;