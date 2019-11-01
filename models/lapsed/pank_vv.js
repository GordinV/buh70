module.exports = {
    selectAsLibs: ``,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
        ]
    },
    select: [{
        sql: `SELECT id, $2 AS userid
              FROM lapsed.pank_vv pank_vv
              WHERE pank_vv.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {}
    },


    requiredFields: [],
    saveDoc: `SELECT result AS id, result, stamp, error_message
              FROM lapsed.sp_salvesta_pank_vv($1::JSONB, $2::INTEGER, $3::INTEGER)`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: ``, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "maksja", name: "Maksja", width: "20%"},
            {id: "viitenumber", name: "Viitenr", width: "10%"},
            {id: "iban", name: "Arveldus arve", width: "20%"},
            {id: "kpv", name: "Kuupäev", width: "10%"},
            {id: "summa", name: "Summa", width: "10%"},
            {id: "pank_id", name: "Tehingu nr.", width: "10%"},
            {id: "selg", name: "Makse selgitus", width: "20%"},
            {id: "markused", name: "Impordi märkused", width: "20%"},
            {id: "number", name: "MK number", width: "10%"},
            {id: "asutus", name: "Asutus", width: "20%"}
        ],
        sqlString: `SELECT v.id                                                                    AS id,
                           v.doc_id                                                                AS doc_id,
                           v.maksja,
                           v.viitenumber,
                           v.iban,
                           to_char(v.kpv, 'DD.MM.YYY')::TEXT                                       AS kpv,
                           v.summa::NUMERIC(12, 2)                                                 AS summa,
                           v.pank_id,
                           v.selg,
                           v.markused,
                           (CASE WHEN v.doc_id IS NOT NULL THEN mk.number ELSE 'PUUDUB' END)::TEXT AS number,
                           (CASE WHEN v.doc_id IS NOT NULL THEN r.nimetus ELSE 'PUUDUB' END)::TEXT AS asutus,
                           to_char(v.timestamp, 'DD.MM.YYYY HH.MM.SSSS')::TEXT                     AS timestamp,
                           $1                                                                      AS not_in_use
                    FROM lapsed.pank_vv v
                             LEFT OUTER JOIN lapsed.cur_lapsed_mk mk ON mk.id = v.doc_id
                             LEFT OUTER JOIN ou.rekv r ON r.id = mk.rekvid
                             LEFT OUTER JOIN ou.userid u ON u.id = $2`,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curPankVV'
    },
    koostaMK: {
        command: `SELECT result, error_message
                  FROM lapsed.read_pank_vv($2::INTEGER, $1::TEXT)`, //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'koostaMK'
    },
    deleteDoc: `SELECT error_code, result, error_message
                FROM lapsed.sp_delete_pank_vv($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId


};

