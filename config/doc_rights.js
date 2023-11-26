module.exports = {
    ARVETE_SAATMINE: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['admin','kasutaja'],
        edit: ['admin','kasutaja'],
        delete: [],
    },
    ARV: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'peakasutaja'],
        edit: ['kasutaja', 'peakasutaja'],
        view: ['arvestaja','kasutaja', 'peakasutaja'],
        delete: ['kasutaja', 'peakasutaja'],
        generatePaymentOrder: ['kasutaja', 'peakasutaja'],
        generateCashOrder:['kasutaja', 'peakasutaja'],
        ebatoenaolised: ['kasutaja', 'peakasutaja']
    },
    SMK: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'peakasutaja'],
        edit: ['kasutaja', 'peakasutaja'],
        delete: ['kasutaja', 'peakasutaja'],
        import: ['admin'],
        KoostaTagasimakse: ['kasutaja', 'peakasutaja'],
        KoostaUlekanneMakse: ['kasutaja', 'peakasutaja']
    },
    PANK_VV: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'peakasutaja','arvestaja'],
        edit: ['kasutaja', 'peakasutaja','arvestaja'],
        delete: ['kasutaja', 'peakasutaja'],
    },
    INF3_ANALUUS: {
        select: ['kasutaja', 'peakasutaja']
    },
    VMK: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'peakasutaja'],
        edit: ['kasutaja', 'peakasutaja'],
        delete: ['kasutaja', 'peakasutaja']
    },
    VORDER: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'peakasutaja'],
        edit: ['kasutaja', 'peakasutaja'],
        delete: ['kasutaja', 'peakasutaja']
    },
    SORDER: {
        select: ['kasutaja', 'arvestaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'peakasutaja'],
        edit: ['kasutaja', 'peakasutaja'],
        delete: ['kasutaja', 'peakasutaja']
    },
    KONTOD: {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['peakasutaja'],
        edit: ['peakasutaja'],
        delete: ['peakasutaja']
    },
    TUNNUS: {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja']
    },
    //nomenclature
    NOMENCLATURE: {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja'],
        import: ['admin']
    },
    ASUTUSED: {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja', 'arvestaja'],
        edit: ['kasutaja','arvestaja'],
        delete: ['kasutaja']
    },

    PROJECT : {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja']
    },
    ARTIKKEL: {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja']
    },
    ALLIKAS: {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja']
    },
    TEGEV : {
        select: ['kasutaja', 'vaatleja', 'peakasutaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja']
    },
    //asutuse_liik
    ASUTUSE_LIIK : {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja']
    },
    //koolituse_liik
    KOOLITUSE_LIIK : {
        select: ['arvestaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja']
    },
    //koolituse_tyyp
    KOOLITUSE_TYYP: {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja']
    },
    TEATIS : {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja']
    },
    LAPS: {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja'],
        koostaArve: ['kasutaja'],
        koostaEttemaksuArved: ['kasutaja'],
        koostaEttemaksuArve: ['kasutaja'],
        arvestaTaabel: ['kasutaja'],
        importLapsed: ['admin'],
        importViitenr: ['admin']
    },
    VANEM: {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja'],
        importVanemad: ['admin'],
        importVanemateRegister: ['admin'],
        importLepingud:['admin']
    },
    LAPSE_KAART: {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja'],
        importTeenused: ['admin'],
        muudaEttemaksuPeriod: ['arvestaja'],
        muudaTeenusteTahtaeg: ['arvestaja'],
    },
    LAPSE_TAABEL: {
        select: ['arvestaja'],
        add: ['kasutaja'],
        edit: ['kasutaja'],
        delete: ['kasutaja'],
        importTaabel: ['admin'],
        importAsendusTaable: ['kasutaja']
    },
    PAEVA_TAABEL: {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja'],
        arvestaPaevaTaabel: ['arvestaja']
    },
    LAPSE_GRUPP: {
        select: ['arvestaja'],
        add: ['arvestaja'],
        edit: ['arvestaja'],
        delete: ['arvestaja'],
        uuendaHinnad: ['arvestaja'],
        importGroups: ['admin'],
        arvestaKondTaabel: ['arvestaja']
    }

};