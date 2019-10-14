module.exports = {
    selectAsLibs: `SELECT lk.id                         AS id,
                          n.kood::TEXT                  AS kood,
                          n.nimetus::TEXT ||
                          coalesce(' (' || (lk.properties ->> 'yksus') || '/' || (lk.properties ->> 'all_yksus') || ')',
                                   '')::TEXT            AS nimetus,
                          lk.parentid                   AS lapsid,
                          lk.properties ->> 'yksus'     AS yksus,
                          lk.properties ->> 'all_yksus' AS all_yksus,
                          lk.rekvid                     AS rekvid
                   FROM lapsed.lapse_kaart lk
                            INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                   WHERE lk.staatus <> 3
                     AND lk.rekvid = $1`,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "isikukood", name: "isikukood", width: "100px"},
            {id: "nimi", name: "Nimi", width: "100px"}
        ]
    }
    ,
    select: [{
        sql: `SELECT lk.id,
                     lk.parentid,
                     lk.rekvid,
                     lk.nomid,
                     lk.hind,
                     lk.tunnus,
                     lk.properties ->> 'yksus'                                             AS yksus,
                     lk.properties ->> 'all_yksus'                                         AS all_yksus,
                     lk.muud,
                     coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC           AS soodus,
                     coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN AS kas_protsent,
                     to_char((lk.properties ->> 'sooduse_alg')::DATE, 'YYYY-MM-DD')        AS sooduse_alg,
                     to_char((lk.properties ->> 'sooduse_lopp')::DATE, 'YYYY-MM-DD')       AS sooduse_lopp,
                     coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE)::BOOLEAN   AS kas_eraldi,
                     coalesce((lk.properties ->> 'kas_ettemaks')::BOOLEAN, FALSE)::BOOLEAN AS kas_ettemaks,
                     coalesce((lk.properties ->> 'kas_inf3')::BOOLEAN, FALSE)::BOOLEAN     AS kas_inf3,
                     n.kood,
                     n.nimetus,
                     $2                                                                    AS userid,
                     l.nimi                                                                AS lapse_nimi
              FROM lapsed.lapse_kaart lk
                       INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                       INNER JOIN lapsed.laps l ON l.id = lk.parentid
              WHERE lk.id = $1::INTEGER
                AND lk.staatus <> 3`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  null::TEXT AS lapse_nimi,
                  null::integer as parentid,
                  null::INTEGER AS nomid,                  
                  null::text as kood,
                  null::text as nimetus,
                  null::text as tunnus,
                  null::text as yksus,
                  null::text as all_yksus,
                  0::numeric as hind,
                  0::numeric as soodus,
                  false as kas_protsent,
                  false as kas_eraldi,
                  false as kas_ettemaks,
                  true as kas_inf3,
                  null::date as sooduse_alg,
                  null::date as sooduse_lopp,
                  null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }
    ],
    returnData:
        {
            row: {}
            ,
            teenused: [],
            gridConfig:
                [
                    {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'kood', name: 'Kood', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'hind', name: 'Hind', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'yksus', name: 'Üksus', width: '100px', show: true, type: 'text', readOnly: false}
                ],
        }
    ,


    requiredFields: [
        {name: 'parentid', type: 'I'},
        {name: 'nomid', type: 'I'},
        {name: 'hind', type: 'I'}

    ],
    /*
    executeCommand: {
        command: `SELECT result, selgitus, summa
                  FROM docs.sp_calc_kulum(?tnId::INTEGER, current_date::DATE)`,
        type: 'sql',
        alias: 'arvestaKulum'
    },
*/
    saveDoc:
        `select lapsed.sp_salvesta_lapse_kaart($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_lapse_kaart($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "1%", show: false},
                {id: "isikukood", name: "Isikukood", width: "20%", show: true},
                {id: "nimi", name: "Nimi", width: "20%", show: true},
                {id: "kood", name: "Kood", width: "20%"},
                {id: "nimetus", name: "Nimetus", width: "40%"},
                {id: "hind", name: "Hind", width: "20%"},
                {id: "yksus", name: "Üksus", width: "20%"}
            ],
            sqlString:
                    `SELECT id,
                            lapsid,
                            isikukood,
                            nimi,
                            kood,
                            nimetus,
                            yksus::TEXT ||
                            CASE WHEN all_yksus IS NOT NULL THEN '(' || all_yksus::TEXT || ')' ELSE '' END AS yksus,
                            hind,
                            $1::INTEGER                                                                    AS rekvid,
                            $2::INTEGER                                                                    AS user_id
                     FROM lapsed.cur_lapse_kaart v
                     WHERE rekvid = $1::INTEGER`,     //  $1 всегда ид учреждения, $2 - userId
            params:
                '',
            alias:
                'curLapsed'
        }


}
;

