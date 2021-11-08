module.exports = {
    selectAsLibs: `SELECT l.*,
                          exists(
                                  SELECT id
                                  FROM lapsed.lapse_kaart lk
                                  WHERE lk.rekvid = $1
                                    AND lk.parentid = l.id
                              )      AS is_exists,
                          NULL::DATE AS valid
                   FROM lapsed.laps l
                   WHERE l.staatus < 3
                   ORDER BY nimi`,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "isikukood", name: "Isikukood", width: "100px"},
            {id: "nimi", name: "Nimi", width: "100px"}
        ]
    },

    select: [{
        sql: `SELECT l.id,
                     l.isikukood,
                     l.nimi,
                     l.muud,
                     lapsed.get_viitenumber((SELECT rekvid
                                             FROM ou.userid
                                             WHERE id = $2), l.id) AS viitenumber,
                     $2::INTEGER                                   AS userid,
                     coalesce(ll.jaak, 0)::NUMERIC                 AS jaak
              FROM lapsed.laps l
                       LEFT OUTER JOIN lapsed.lapse_saldod(current_date, $1) ll ON ll.laps_id = l.id AND
                                                                                   ll.rekv_id IN (SELECT rekvid
                                                                                                  FROM ou.userid u
                                                                                                  WHERE u.id = $2)
              WHERE l.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  0::integer as vanemid,
                  null::text as isikukood,
                  null::text as nimi,
                  null::text as viitenumber,
                  null::text as muud,
                  0::numeric(14,2) as jaak`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT v.id,
                         v.parentid,
                         v.asutusid,
                         a.nimetus,
                         a.tel,
                         a.email,
                         v.properties ->> 'arved'     AS arved,
                         v.properties ->> 'suhtumine' AS suhtumine,
                         $2                           AS userid
                  FROM lapsed.vanemad v
                           INNER JOIN libs.asutus a ON a.id = v.asutusid
                  WHERE v.parentid = $1
                    AND v.staatus < 3`,
            query: null,
            multiple: true,
            alias: 'vanemad',
            data: []
        },
        {
            sql: `SELECT *
                  FROM (
                           SELECT k.id,
                                  k.parentid,
                                  k.nomid,
                                  n.kood,
                                  n.nimetus,
                                  k.hind,
                                  gr.nimetus::TEXT                                                         AS yksus,
                                  k.properties ->> 'all_yksus'                                             AS all_yksus,
                                  CASE WHEN (n.properties ->> 'kas_inf3')::BOOLEAN THEN 'INF3' ELSE '' END AS inf3,
                                  n.uhik,
                                  n.properties ->> 'tyyp'                                                  AS tyyp,
                                  to_char(coalesce((k.properties ->> 'alg_kpv')::DATE, date(year(), 1, 1)),
                                          'DD.MM.YYYY') ||
                                  ' - ' ||
                                  to_char(coalesce((k.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31)),
                                          'DD.MM.YYYY')                                                    AS kehtivus,
                                  coalesce((k.properties ->> 'lopp_kpv')::DATE,
                                           date(year(), 12, 31))                                           AS lopp_kpv,
                                  coalesce((k.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC               AS soodustus,
                                  CASE
                                      WHEN coalesce((k.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN
                                          THEN 'Jah'
                                      ELSE 'Ei' END::TEXT                                                  AS kas_protsent,
                                  to_char((k.properties ->> 'sooduse_alg')::DATE, 'DD.MM.YYYY') || ' ' ||
                                  to_char((k.properties ->> 'sooduse_lopp')::DATE, 'DD.MM.YYYY')           AS soodustuste_period

                           FROM lapsed.lapse_kaart k
                                    INNER JOIN libs.nomenklatuur n ON n.id = k.nomid
                                    LEFT OUTER JOIN libs.library gr
                                                    ON gr.library = 'LAPSE_GRUPP' AND gr.status <> 3 AND
                                                       gr.rekvid = k.rekvid
                                                        AND gr.kood::TEXT = (k.properties ->> 'yksus')::TEXT
                           WHERE k.parentid = $1
                             AND k.staatus <> 3
                             AND k.rekvid IN (SELECT rekvid
                                              FROM ou.userid
                                              WHERE id = $2)
                       ) qry
                  ORDER BY lopp_kpv, kehtivus, yksus, kood`,
            query: null,
            multiple: true,
            alias: 'teenused',
            data: []
        },
        {
            sql: `SELECT v.id,
                         v.viitenumber,
                         v.isikukood,
                         l.id AS laps_id,
                      $2 AS userid
                  FROM lapsed.viitenr v
                           INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
                  WHERE l.id = $1`,
            query: null,
            multiple: true,
            alias: 'viitenumbers',
            data: []
        },


    ],
    returnData:
        {
            row: {},
            details: [],
            teenused: [],
            vanemad: [],
            gridConfig:
                [
                    {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'parentid', name: 'parentid', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'asutusid', name: 'asutusid', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'nimetus', name: 'Nimetus', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'tel', name: 'Tel. nr', width: '100px', show: true, type: 'text', readOnly: false},
                    {id: 'email', name: 'E-mail', width: '100px', show: true, type: 'text', readOnly: false},
                ],
            gridTeenusteConfig:
                [
                    {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                    {id: 'kood', name: 'Kood', width: '10%', show: true, type: 'text', readOnly: false},
                    {id: 'nimetus', name: 'Nimetus', width: '20%', show: true, type: 'text', readOnly: false},
                    {id: 'uhik', name: 'Ühik', width: '5%', show: true, type: 'text', readOnly: false},
                    {id: 'hind', name: 'Hind', width: '10%', show: true, type: 'text', readOnly: false},
                    {id: 'yksus', name: 'Üksus', width: '10%', show: true, type: 'text', readOnly: false},
                    {id: 'all_yksus', name: 'All üksus', width: '5%', show: true, type: 'text', readOnly: false},
                    {id: 'inf3', name: 'INF3', width: '5%', show: true, type: 'text', readOnly: false},
                    {id: 'kehtivus', name: 'Period', width: '10%', show: true, type: 'text', readOnly: false},
                    {id: 'soodustus', name: 'Soodustus', width: '10%', show: true, type: 'text', readOnly: false},
                    {id: 'soodustuste_period', name: 'Kehtiv', width: '10%', show: true, type: 'text', readOnly: false},
                    {id: 'kas_protsent', name: '%', width: '5%', show: true, type: 'text', readOnly: false},
                ]
        },
    requiredFields: [
        {name: 'isikukood', type: 'C', serverValidation: 'validateIsikukood'},
        {name: 'nimi', type: 'T'}
    ],
    saveDoc:
        `select lapsed.sp_salvesta_laps($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_laps($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "10%", show: false},
                {id: "row_id", name: "Jrk", width: "3%", show: true, hideFilter: true},
                {id: "isikukood", name: "Isikukood", width: "20%"},
                {id: "nimi", name: "Nimi", width: "30%"},
                {id: "viitenumber", name: "Viitenumber", width: "20%"},
                {id: "yksused", name: "Üksused", width: "30%"},
                {id: "lopp_kpv", name: "Kehtivus", width: "20%", type: 'date', interval: true},
                {id: "select", name: "Valitud", width: "10%", show: false, type: 'boolean', hideFilter: true}
            ],
            sqlString:
                    `SELECT TRUE                                  AS select,
                            id,
                            isikukood,
                            nimi,
                            yksused,
                            lapsed.get_viitenumber($1, l.id)      AS viitenumber,
                            $1::INTEGER                           AS rekvid,
                            $2::INTEGER                           AS user_id,
                            count(*) OVER ()                      AS rows_total,
                            to_char(lopp_kpv, 'DD.MM.YYYY')::TEXT AS lopp_kpv
                     FROM lapsed.cur_lapsed l
                     WHERE rekv_ids @> ARRAY [$1::INTEGER]::INTEGER[]
            `,     //  $1 всегда ид учреждения, $2 - userId
            params: ['rekvid', 'userid'],
            alias: 'curLapsed',
            converter: function (data) {
                let row_id = 0;
                return data.map(row => {
                    row_id++;
                    row.row_id = row_id;
                    return row;
                })
            }

        },
    koostaArve: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM lapsed.koosta_arve_taabeli_alusel($2::INTEGER, $1::INTEGER, $3::DATE)`, //$1 docId, $2 - userId
        type: 'sql',
        alias: 'koostaArve'
    },
    koostaArved: {
        command: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message,
                         tulemus ->> 'viitenr'                                         AS viitenr
                  FROM (
                           SELECT to_jsonb(
                                          lapsed.koosta_arve_taabeli_alusel($2::INTEGER, id::INTEGER, $3::DATE)) tulemus
                           FROM lapsed.laps
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`, //$1 docId, $2 - userId
        type: 'sql',
        alias: 'koostaArved'
    },

    koostaEttemaksuArved: {
        command: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus -> 'error_message'                                    AS error_message,
                         tulemus ->> 'viitenr'                                         AS viitenr
                  FROM (
                           SELECT to_jsonb(lapsed.koosta_ettemaksu_arve($2::INTEGER, id::INTEGER, $3::DATE)) tulemus
                           FROM lapsed.laps
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                           )) qry`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'koostaEttemaksuArved'
    },
    koostaEttemaksuArve: {
        command: `SELECT *
                  FROM lapsed.koosta_ettemaksu_arve($2::INTEGER, $1::INTEGER, $3::DATE)`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'koostaEttemaksuArve'
    },
    arvestaTaabel: {
        command: `SELECT row_number() OVER ()                                          AS id,
                         tulemus -> 'result'                                           AS result,
                         tulemus -> 'error_code'                                       AS error_code,
                         coalesce((tulemus ->> 'error_code')::INTEGER, 0)::INTEGER > 0 AS kas_vigane,
                         tulemus ->> 'error_message'                                   AS error_message,
                         tulemus ->> 'viitenr'                                         AS viitenr
                  FROM (
                           SELECT to_jsonb(lapsed.arvesta_taabel($2::INTEGER, id::INTEGER, $3::DATE)) tulemus
                           FROM lapsed.laps
                           WHERE id IN (
                               SELECT unnest(string_to_array($1::TEXT
                                   , ','::TEXT))::INTEGER
                           )) qry`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'arvestaTaabel'
    },
    importLapsed: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_lapsed($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importLapsed'
    },
    importViitenr: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_viitenr($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importViitenr'
    },
    validateIsikukood: {
        command: `SELECT id
                  FROM lapsed.laps
                  WHERE isikukood = $1::TEXT`,
        type: 'sql',
        alias: 'validateIsikukood'
    },
    lopetaKoikTeenused: {
        command: `SELECT *
                  FROM lapsed.lopeta_koik_teenused($2::INTEGER, $1::INTEGER, $3::DATE)`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'lopetaKoikTeenused'
    },
    SaamaYksuseTeenused: {
        command: `SELECT *
                  FROM lapsed.saama_yksuse_teenused($2::INTEGER, $1::INTEGER, $4::INTEGER, $3::DATE)`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'SaamaYksuseTeenused'
    },

    bpm: [
        {
            name: 'Arvesta taabel',
            task: 'arvestaTaabel',
            type: 'manual',
            action: 'arvestaTaabel',
        },
        {
            name: 'Koosta arve taabeli alusel',
            task: 'koostaArve',
            type: 'manual',
            action: 'generateJournal',
        },
        {
            name: 'Koosta ettemaksuarve',
            task: 'koostaEttemaksuArve',
            type: 'manual',
            action: 'generateJournal',
        },
        {
            name: 'Lõpeta kõik teenused',
            task: 'lopetaKoikTeenused',
            type: 'manual',
            action: 'lopetaKoikTeenused',
        },
        {
            name: 'Saama üksuse teenused',
            task: 'SaamaYksuseTeenused',
            type: 'manual',
            hideDate: false,
            showYksus: true,
            action: 'SaamaYksuseTeenused',
        }


    ],
    print: [
        {
            view: 'lapse_kaart',
            params: 'id'
        },
        {
            view: 'laste_register',
            params: 'sqlWhere'
        },
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements(d.ajalugu) AS ajalugu
                           FROM lapsed.laps d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },


}
;

