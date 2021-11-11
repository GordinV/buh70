module.exports = {
    selectAsLibs: ``,
    select: [{
        sql: `SELECT $2        AS userid,
                     v.id,
                     v.viitenumber,
                     v.isikukood,
                     l.nimi,
                     v.rekv_id,
                     r.nimetus AS asutus,
                     l.id      AS laps_id
              FROM lapsed.viitenr v
                       LEFT OUTER JOIN ou.rekv r ON r.id = v.rekv_id
                       INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood

              WHERE v.id = $1::INTEGER`,
        sqlAsNew: `SELECT $1 :: INTEGER   AS id,
                          $2 :: INTEGER   AS userid,
                          NULL::TEXT      AS viitenumber,
                          NULL::TEXT      AS isikukood,
                          NULL::TEXT      AS nimi,
                          r.id::INTEGER   AS rekv_id,
                          r.nimetus::TEXT AS asutus
                   FROM ou.userid u
                            INNER JOIN ou.rekv r ON u.rekvid = r.id
                   WHERE u.id =  $2`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {}
    },


    requiredFields: ['viitenumber', 'rekv_id', 'laps_id'],
    saveDoc: `SELECT lapsed.sp_salvesta_viitenr($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM lapsed.sp_delete_viitenr($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId

    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "maksja", name: "Maksja", width: "10%"},
            {id: "maksja_ik", name: "Maksja IK", width: "7%"},
            {id: "viitenumber", name: "Viitenr", width: "10%"},
            {id: "iban", name: "Arveldus arve", width: "12%"},
            {id: "pank", name: "Pank", width: "7%"},
            {id: "kpv", name: "Maksepäev", width: "7%", show: true, type: 'date', interval: true},
            {id: "summa", name: "Summa", width: "5%"},
            {id: "pank_id", name: "Tehingu nr.", width: "10%"},
            {id: "selg", name: "Makse selgitus", width: "10%"},
            {id: "markused", name: "Impordi märkused", width: "5%"},
            {id: "number", name: "MK number", width: "5%"},
            {id: "asutus", name: "Asutus", width: "10%"}
        ],
        sqlString: `SELECT v.id                                                AS id,
                           v.doc_id                                            AS doc_id,
                           v.maksja,
                           v.isikukood                                         AS maksja_ik,
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
                    ORDER BY id DESC`,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curPankVV'
    },

};

