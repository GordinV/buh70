module.exports = {
    selectAsLibs: `SELECT lk.id                         AS id,
                          n.kood::TEXT                  AS kood,
                          n.nimetus::TEXT ||
                          coalesce(' (' || (lk.properties ->> 'yksus') || '/' || (lk.properties ->> 'all_yksus') || ')',
                                   '')::TEXT || ', hind: ' || (lk.hind::NUMERIC(12, 2)) || ' ' ||
                          n.uhik::TEXT                  AS nimetus,
                          lk.parentid                   AS lapsid,
                          lk.properties ->> 'yksus'     AS yksus,
                          lk.properties ->> 'all_yksus' AS all_yksus,
                          lk.rekvid                     AS rekvid,
                          NULL::DATE                    AS valid
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
                     coalesce((lk.properties ->> 'kogus')::NUMERIC, 0)::NUMERIC            AS kogus,
                     coalesce((lk.properties ->> 'ettemaksu_period')::NUMERIC, 0)::NUMERIC AS ettemaksu_period,
                     lk.tunnus,
                     lk.properties ->> 'yksus'                                             AS yksus,
                     lk.properties ->> 'all_yksus'                                         AS all_yksus,
                     lk.muud,
                     coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC           AS soodus,
                     coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN AS kas_protsent,
                     to_char((lk.properties ->> 'sooduse_alg')::DATE, 'YYYY-MM-DD')        AS sooduse_alg,
                     to_char((lk.properties ->> 'sooduse_lopp')::DATE, 'YYYY-MM-DD')       AS sooduse_lopp,
                     to_char((lk.properties ->> 'sooduse_alg')::DATE, 'DD.MM.YYYY')        AS sooduse_alg_print,
                     to_char((lk.properties ->> 'sooduse_lopp')::DATE, 'DD.MM.YYYY')       AS sooduse_lopp_print,
                     coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE)::BOOLEAN   AS kas_eraldi,
                     coalesce((lk.properties ->> 'kas_ettemaks')::BOOLEAN, FALSE)::BOOLEAN AS kas_ettemaks,
                     coalesce((lk.properties ->> 'kas_inf3')::BOOLEAN, FALSE)::BOOLEAN     AS kas_inf3,
                     to_char(coalesce((lk.properties ->> 'alg_kpv')::DATE, date(year(), month(), 1)),
                             'YYYY-MM-DD')                                                 AS alg_kpv,
                     to_char(coalesce((lk.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31)),
                             'YYYY-MM-DD')                                                 AS lopp_kpv,
                     n.kood,
                     n.nimetus,
                     $2                                                                    AS userid,
                     l.isikukood                                                           AS isikukood,
                     l.nimi                                                                AS lapse_nimi,
                     to_char(coalesce((lk.properties ->> 'alg_kpv')::DATE, date(year(), month(), 1)),
                             'DD-MM-YYYY') ||
                     to_char(coalesce((lk.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31)),
                             'DD.MM.YYYY')                                                 AS kehtivus,
                     lk.properties ->> 'viitenr'                                           AS viitenr

              FROM lapsed.lapse_kaart lk
                       INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                       INNER JOIN lapsed.laps l ON l.id = lk.parentid
              WHERE lk.id = $1::INTEGER
                AND lk.staatus <> 3`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  null::TEXT AS isikukood,
                  null::TEXT AS lapse_nimi,
                  null::integer as parentid,
                  null::INTEGER AS nomid,                  
                  null::text as kood,
                  null::text as nimetus,
                  null::text as tunnus,
                  null::text as yksus,
                  null::text as all_yksus,
                  0::numeric as hind,
                  1::numeric as kogus,
                  1::numeric as  ettemaksu_period,
                  0::numeric as soodus,
                  false as kas_protsent,
                  false as kas_eraldi,
                  false as kas_ettemaks,
                  true as kas_inf3,
                  null::date as sooduse_alg,
                  null::date as sooduse_lopp,
                  to_char(date(year(), 1, 1),'YYYY-MM-DD')  AS alg_kpv, 
                  to_char(date(year(), 12, 31),'YYYY-MM-DD')  AS lopp_kpv,
                  null::text as viitenr,
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
        {name: 'hind', type: 'I'},
        {name: 'alg_kpv', type: 'D', expression: 'data.alg_kpv < data.lopp_kpv'},
        {name: 'lopp_kpv', type: 'D', expression: 'data.lopp_kpv > data.alg_kpv'}

    ],
    saveDoc:
        `select lapsed.sp_salvesta_lapse_kaart($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_lapse_kaart($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "1%", show: false},
                {id: "row_id", name: "Jrk", width: "3%", show: true, hideFilter: true},
                {id: "isikukood", name: "Isikukood", width: "10%", show: true},
                {id: "nimi", name: "Nimi", width: "15%", show: true},
                {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
                {id: "kood", name: "Kood", width: "7%"},
                {id: "nimetus", name: "Nimetus", width: "12%"},
                {id: "hind", name: "Hind", width: "10%", type: "number"},
                {id: "soodustus", name: "Soodustus", width: "10%"},
                {id: "uhik", name: "Ühik", width: "5%"},
                {id: "yksus", name: "Üksus", width: "10%"},
                {id: "alg_kpv", name: "Kpv-st", width: "7%", type: 'date', interval: true},
                {id: "lopp_kpv", name: "Kpv-ni", width: "7%", type: 'date', interval: true},
                {id: "kehtiv_kpv", name: "Kehtiv seisuga", width: "20%", type: 'date', show: false},
                {id: "period",name: "Kehtivuse periood",width: "0%",type: 'date',interval: true,show: false,default: 'AASTA',filterValidation: true},
                {id: "kas_kehtib", name: "Kehtivus", width: "10%", type: 'select', data: ['', 'Jah', 'Ei']},
                {id: "inf3", name: "INF3", width: "5%"},
                {id: "tapne_viitenumber", name: "Vana VN", width: "10%"},
                {id: "asutus", name: "Asutus", width: "10%", default: `DocContext.userData.asutus`},
                {id: "select", name: "Valitud", width: "5%", show: false, type: 'boolean', hideFilter: true}
            ],
            sqlString:
                `WITH range_parameters AS (
                     SELECT ('[' || format_date(coalesce($3::text, make_date(year(current_date), 01, 01)::TEXT))::TEXT || ',' ||
                             (format_date(($4::date + case when $3::date = $4::date then interval '1 day' else interval '0 day' end)::text)::TEXT) ||
                             ')') ::DATERANGE AS range,
                            $3::DATE        AS period_start,
                            $4::DATE        AS period_finish,
                            case when $5::text is not null and $5::text = '' then null::date else $5::DATE end::date as kehtiv_kpv
                 ),
                 lk AS (            
                    SELECT id,
                            lapsid,
                            isikukood,
                            nimi,
                            kood,
                            nimetus,
                            yksus::TEXT ||
                            CASE WHEN all_yksus IS NOT NULL THEN '(' || all_yksus::TEXT || ')' ELSE '' END AS yksus,
                            hind                                                                           AS hind,
                            uhik,
                            lapsed.get_viitenumber(v.rekvid, lapsid)                                       AS viitenumber,
                            v.rekvid::INTEGER                                                              AS rekvid,
                            $2::INTEGER                                                                    AS user_id,
                            to_char(alg_kpv, 'DD.MM.YYYY') || ' - ' || to_char(lopp_kpv, 'DD.MM.YYYY')     AS kehtivus,
                            v.inf3                                                                         AS inf3,
                            CASE
                                WHEN (soodustus::NUMERIC(12, 2)) > 0 THEN ((soodustus::NUMERIC(12, 2))::TEXT || ' ' ||
                                                                           kas_protsent || '(' || sooduse_kehtivus ||
                                                                           ')')
                                WHEN v.tyyp IS NOT NULL AND v.tyyp = 'SOODUSTUS' THEN (-1 * hind)::TEXT
                                ELSE '' END                                                                AS soodustus,
                            soodustus::NUMERIC(12, 2)                                                      AS soodustuse_summa,
                            kas_ettemaks::BOOLEAN                                                          AS ettemaks,
                            TRUE                                                                           AS select,
                            v.kogus,
                            v.tunnus,
                            v.ettemaksu_period,
                            v.kas_eraldi,
                            to_char(v.sooduse_alg, 'DD.MM.YYYY')                                           AS sooduse_alg,
                            to_char(v.sooduse_lopp, 'DD.MM.YYYY')                                          AS sooduse_lopp,
                            to_char(v.alg_kpv, 'DD.MM.YYYY')                                               AS alg_kpv,
                            to_char(v.lopp_kpv, 'DD.MM.YYYY')                                              AS lopp_kpv,
                            $3::date as period,
                            v.yksuse_kood,
                            count(*) OVER ()                                                               AS rows_total,
                            v.asutus,
                            v.vana_viitenumber,    
                            v.viitenr AS tapne_viitenumber,
                            ('[' || ((v.alg_kpv)::DATE)::TEXT || ',' || (CASE
                                                                             WHEN (v.alg_kpv)::DATE >=
                                                                                  (v.lopp_kpv)::DATE
                                                                                 THEN (v.alg_kpv)::DATE
                                                                             ELSE (v.lopp_kpv)::DATE END)::TEXT ||
                             ')') ::DATERANGE                                                              AS lk_range,
                            r.kehtiv_kpv::DATE                                                             AS kehtiv_kpv
                     FROM lapsed.cur_lapse_kaart v,
                          range_parameters r
                     WHERE rekvid IN (SELECT rekv_id
                                      FROM get_asutuse_struktuur($1::INTEGER))
                    )
                    SELECT lk.*,
                           CASE
                               WHEN coalesce((
                                                 CASE
                                                     WHEN lk.kehtiv_kpv IS NULL THEN lk.lk_range &&
                                                                                     r.range OR lk.lk_range -|-
                                                                                                r.range
                                                     ELSE lk.lk_range @>
                                                          r.kehtiv_kpv END
                                                 ), FALSE) IS TRUE THEN
                                   'Jah'
                               ELSE
                                   'Ei' END AS kas_kehtib
                    
                    FROM lk,
                         range_parameters r`,     //  $1 всегда ид учреждения, $2 - userId
            params: ['rekvid', 'userid', 'period_start', 'period_end', 'kehtiv_kpv'],
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
    print: [
        {
            view: 'lapse_teenused_kaart',
            params: 'id'
        },
        {
            view: 'lapse_teenused_register',
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
                           FROM lapsed.lapse_kaart d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },
    muudaEttemaksuPeriod: {
        command: `SELECT error_code, result, error_message, doc_type_id
                  FROM lapsed.muuda_ettemaksu_period($2::INTEGER, $1::INTEGER, $3::INTEGER)`,//$1 docId, $2 - userId, $3 - ETTEMAKSU_PERIOD
        type: 'sql',
        alias: 'muudaEttemaksuPeriod'
    },
    muudaTeenusteTahtaeg: {
        command: `SELECT lapsed.muuda_teenuste_tahtaeg($2::INTEGER, id::INTEGER, $3::DATE)
                  FROM lapsed.lapse_kaart
                  WHERE id IN (
                      SELECT unnest(string_to_array($1::TEXT, ','::TEXT))::INTEGER
                  )
                    AND staatus <> 3`,//$1 docId, $2 - userId
        type: 'sql',
        alias: 'muudaTeenusteTahtaeg'
    },

    importTeenused: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_laste_teenused($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importTeenused'
    },


};

