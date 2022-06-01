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

    select: [
        {
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
                                  k.hind                                                                      hind,
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
                                  CASE
                                      WHEN n.properties ->> 'tyyp' IS NOT NULL AND n.properties ->> 'tyyp' = 'SOODUSTUS'
                                          THEN (-1 * k.hind)::NUMERIC
                                      ELSE coalesce((k.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC END  AS soodustus,
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
                         l.id      AS laps_id,
                         r.nimetus AS asutus,
                         $2        AS userid
                  FROM lapsed.viitenr v
                           INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
                           INNER JOIN ou.rekv r ON r.id = v.rekv_id
                           INNER JOIN ou.userid u ON u.id = $2 AND r.id = u.rekvid
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
            viitenumbers: [],
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
                ],
            gridViitenumberConfig: [
                {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
                {id: 'viitenumber', name: 'Viitenumber', width: '30%', show: true, type: 'text', readOnly: false},
                {id: 'asutus', name: 'Asutus', width: '70%', show: true, type: 'text', readOnly: false},

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
                {id: "isikukood", name: "Isikukood", width: "15%"},
                {id: "nimi", name: "Nimi", width: "25%"},
                {id: "viitenumber", name: "Viitenumber", width: "25%"},
                {id: "vana_vn", name: "Vana vn", width: "25%"},
                {id: "yksused", name: "Üksused", width: "30%"},
                {id: "lopp_kpv", name: "Lõpp kpv", width: "20%", type: 'date', interval: true},
                {id: "period", name: "Kehtivuse periood", width: "20%", type: 'date', interval: true, show: false, default: 'AASTA'},
                {id: "kehtivus", name: "Kehtivus", width: "10%", type: 'select', data: ['','Jah','Ei']},
                {id: "rekv_names", name: "Asutused", width: "30%", default: `DocContext.userData.asutus`},
                {id: "select", name: "Valitud", width: "10%", show: false, type: 'boolean', hideFilter: true}
            ],
            sqlString: `
         WITH range_parameters AS (
             SELECT ('[' || format_date(coalesce($3::text, make_date(year(current_date), 01, 01)::TEXT))::TEXT || ',' ||
                     (format_date(($4::date + case when $3::date = $4::date then interval '1 day' else interval '0 day' end)::text)::TEXT) ||
                     ')') ::DATERANGE AS range,
                    $3::DATE        AS period_start,
                    $4::DATE        AS period_finish
         ),
            
       cur_lapsed AS (
            SELECT l.id,
                   l.isikukood,
                   l.nimi,
                   l.properties,
                   lk.rekv_ids,
                   (SELECT string_agg(nimetus, ', ') FROM ou.rekv WHERE id IN (SELECT unnest(lk.rekv_ids)))       AS rekv_names,
                   lk.lopp_kpv,
                   (SELECT string_agg(yksus, ', ') FROM (SELECT DISTINCT yksus FROM unnest(yksused) yksus) yksus) AS yksused,
        
                   lk_range,
                   (SELECT string_agg(vn, ', ')
                    FROM (SELECT DISTINCT vn FROM unnest(viitenumbers) vn) vn)                                    AS viitenumbers
        
            FROM lapsed.laps l
                     JOIN (SELECT parentid,
                                  array_agg(rekvid)      AS rekv_ids,
                                  array_agg(yksused)     AS yksused,
                                  array_agg(viitenumber) AS viitenumbers,
                                  array_agg(lk_range)    AS lk_range,
                                  max(lopp_kpv)          AS lopp_kpv
                           FROM (
                                    SELECT parentid,
                                           rekvid,
                                           lapsed.get_viitenumber(k.rekvid, k.parentid)                                                       AS viitenumber,
                                           (k.properties ->> 'lopp_kpv')::DATE                                                                AS lopp_kpv,
                                           ('[' || ((k.properties ->> 'alg_kpv')::DATE)::TEXT || ',' || (CASE
                                                                                                             WHEN (k.properties ->> 'alg_kpv')::DATE >=
                                                                                                                  (k.properties ->> 'lopp_kpv')::DATE
                                                                                                                 THEN (k.properties ->> 'alg_kpv')::DATE
                                                                                                             ELSE (k.properties ->> 'lopp_kpv')::DATE END)::TEXT ||
                                            ')') ::DATERANGE                                                                                  AS lk_range,
                                           (get_unique_value_from_json(json_agg((k.properties ->> 'yksus')::TEXT || CASE
                                                                                                                        WHEN (k.properties ->> 'all_yksus') IS NOT NULL
                                                                                                                            THEN
                                                                                                                                '-' ||
                                                                                                                                (k.properties ->> 'all_yksus')::TEXT
                                                                                                                        ELSE '' END)::JSONB)) AS yksused
                                    FROM lapsed.lapse_kaart k
                                    WHERE k.staatus <> 3
                                      AND k.rekvid IN (SELECT rekv_id
                                                       FROM get_asutuse_struktuur($1))
                                    GROUP BY parentid, rekvid, (k.properties ->> 'alg_kpv'), (k.properties ->> 'lopp_kpv')
                                ) qry,
                                  range_parameters
                                 WHERE (lk_range -|- range_parameters.range or lk_range &&
                                 range_parameters.range)
                                    OR range_parameters.period_start IS NULL                                
                           GROUP BY parentid) lk ON lk.parentid = l.id
            WHERE l.staatus <> 3
        ),
             qry_range AS (
                with qry_range as (
                 SELECT DISTINCT unnest(lk.lk_range) AS range,
                                 lk.id
                 FROM cur_lapsed lk)
                 SELECT DISTINCT lk.range &&
                                 range_parameters.range or lk.range -|-
                                 range_parameters.range AS kehtivus,
                                 lk.id
                 FROM qry_range lk, range_parameters
             )
        SELECT TRUE                                  AS select,
               l.id,
               l.isikukood,
               l.nimi,
               l.yksused,
               l.rekv_names,
               vn.vn                                 AS vana_vn,
               l.viitenumbers                        AS viitenumber,
               $1::INTEGER                           AS rekvid,
               $2::INTEGER                           AS user_id,
               count(*) OVER ()                      AS rows_total,
               to_char(lopp_kpv, 'DD.MM.YYYY')::TEXT AS lopp_kpv,
               CASE
                   WHEN coalesce(qr.kehtivus, FALSE) IS TRUE THEN
                       'Jah'
                   ELSE
                       'Ei' END                      AS kehtivus,
                       $3::date as period
        FROM cur_lapsed l
                 LEFT OUTER JOIN (SELECT string_agg(viitenumber, ', ') AS vn, vn.isikukood
                                  FROM lapsed.viitenr vn
                                  WHERE vn.rekv_id IN (SELECT rekv_id
                                                       FROM get_asutuse_struktuur($1))
                                  GROUP BY vn.isikukood
        ) vn
                                 ON vn.isikukood = l.isikukood
                 LEFT OUTER JOIN (SELECT * FROM qry_range WHERE kehtivus IS TRUE) qr ON qr.id = l.id
`,     //  $1 всегда ид учреждения, $2 - userId
            params: ['rekvid', 'userid', 'period_start', 'period_end'],
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
        command: `SELECT DISTINCT *
                  FROM jsonb_to_recordset(
                               (
                                   SELECT qry.tulemus
                                   FROM (
                                            SELECT * FROM lapsed.import_viitenr($1::JSONB, $2::INTEGER, $3::INTEGER)
                                        ) qry
                               )
                           ) AS x (id INTEGER, isikukood TEXT, viitenr TEXT, rekv_id NUMERIC, status TEXT)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importViitenr'
    },
    validateIsikukood: {
        command: `SELECT id
                  FROM lapsed.laps
                  WHERE isikukood = $1::TEXT
                    AND staatus < 3`,
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
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS kustutatud

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

