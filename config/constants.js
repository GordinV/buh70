module.exports = {
    RECORDS_LIMIT: 1000,
    events: {
        LAPS: [
            {name: 'Tabeli koostamine', method: 'arvestaTaabel', docTypeId: 'lapse_taabel'},
            {name: 'Arve koostamine', method: 'koostaArve', docTypeId: 'arv'},
            {name: 'Ettemaksuarve koostamine', method: 'koostaEttemaksuArved', docTypeId: 'arv'},
        ]
    },
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
    tulemused: {
        gridConfig: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "result", name: "Tulemus", width: "5%", show:false},
            {id: "kas_vigane", name: "Staatus", width: "5%", show: true, yesBackgroundColor: 'red', noBackgroundColor:'green'},
            {id: "error_message", name: "Teatis", width: "75%", show: true}
        ]
    },
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
    }


}
;