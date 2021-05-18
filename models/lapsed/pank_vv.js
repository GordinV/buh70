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
    saveDoc: `SELECT result AS id, result, stamp, error_message, data 
              FROM lapsed.sp_salvesta_pank_vv($1::JSONB, $2::INTEGER, $3::INTEGER)`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: ``, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "maksja", name: "Maksja", width: "10%"},
            {id: "viitenumber", name: "Viitenr", width: "10%"},
            {id: "iban", name: "Arveldus arve", width: "10%"},
            {id: "pank", name: "Pank", width: "10%"},
            {id: "kpv", name: "Maksepäev", width: "10%", show: true, type: 'date', interval: true},
            {id: "summa", name: "Summa", width: "7%"},
            {id: "pank_id", name: "Tehingu nr.", width: "10%"},
            {id: "selg", name: "Makse selgitus", width: "20%"},
            {id: "markused", name: "Impordi märkused", width: "5%"},
            {id: "number", name: "MK number", width: "5%"},
            {id: "asutus", name: "Asutus", width: "10%"}
        ],
        sqlString: `SELECT v.id                                                AS id,
                           v.doc_id                                            AS doc_id,
                           v.maksja,
                           v.viitenumber,
                           v.iban,
                           to_char(v.kpv, 'DD.MM.YYYY')::TEXT                  AS kpv,
                           v.summa::NUMERIC(12, 2)                             AS summa,
                           v.pank_id,
                           v.selg,
                           coalesce(v.markused, 'OK')                          AS markused,
                           (CASE
                                WHEN v.doc_id IS NOT NULL AND NOT empty(v.doc_id) THEN mk.number
                                ELSE 'PUUDUB' END)::TEXT                       AS number,
                           (CASE
                                WHEN v.doc_id IS NOT NULL OR empty(v.doc_id) THEN r.nimetus
                                ELSE 'PUUDUB' END)::TEXT                       AS asutus,
                           v.pank                                              AS pank,
                           to_char(v.timestamp, 'DD.MM.YYYY HH.MM.SSSS')::TEXT AS timestamp,
                           $1                                                  AS not_in_use,
                           count(*) OVER ()                                    AS rows_total
                    FROM lapsed.pank_vv v
                             LEFT OUTER JOIN lapsed.cur_lapsed_mk mk ON mk.id = v.doc_id
                             LEFT OUTER JOIN ou.rekv r ON r.id = mk.rekvid
                             LEFT OUTER JOIN ou.userid u ON u.id = $2
                        ORDER BY timestamp DESC`,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curPankVV'
    },
    koostaMK: {
        command: `SELECT result, error_message
                  FROM lapsed.read_pank_vv($2::INTEGER, $1::TEXT)`, //$1 - docs.doc.id, $2 - userId
        type: "sql",
        alias: 'koostaMK'
    },
    loeMakse: {
        command: `SELECT result, error_message
                  FROM lapsed.loe_makse($2::INTEGER, $1::INTEGER)`, //$1 - pank_vv.id, $2 - userId
        type: "sql",
        alias: 'loeMakse'
    },
    deleteDoc: `SELECT error_code, result, error_message
                FROM lapsed.sp_delete_pank_vv($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId


};

