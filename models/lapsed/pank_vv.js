module.exports = {
    selectAsLibs: `WITH params AS (
            WITH nimed AS (
                SELECT $1 AS nimi,
                       ''             AS isikukood
            )
            SELECT isikukood, nimi, regexp_split_to_array(nimi, '\\s+') AS nimed
            FROM nimed
        ),
             lapsed AS
                 (SELECT get_unique_value_from_array(rekv_ids::TEXT[]) AS asutused,
                         l.nimi,
                         a.id                                          AS asutus_id,
                         l.id                                          AS laps_id
                  FROM libs.asutus a
                           INNER JOIN lapsed.vanemad v ON v.asutusid = a.id
                           INNER JOIN lapsed.cur_lapsed l ON l.id = v.parentid
                          ,
                       params
                  WHERE (a.nimetus ILIKE '%' || coalesce(params.nimed[1], '') || '%'
                      AND a.nimetus ILIKE '%' || coalesce(params.nimed[2], '') || '%'
                      AND a.regkood ILIKE coalesce(params.isikukood, '') || '%'
                            )
                 ),
             maksjad AS (
                 SELECT maksja_id,
                        max(kpv)                                                  AS kpv,
                        get_unique_value_from_array(array_agg(mk.rekvid)::TEXT[]) AS rekv_ids,
                        laps_id
                 FROM lapsed.cur_lapsed_mk mk
                 WHERE maksja_id IN (
                     SELECT asutus_id
                     FROM lapsed
                 )
                 GROUP BY maksja_id, laps_id
             ),
             vn AS (
                 WITH vns AS (
                     SELECT (lapsed.get_viitenumber(unnest(m.rekv_ids)::INTEGER, laps_id)) AS vn_s, laps_id
                     FROM maksjad m)
                 SELECT array_agg(vn_s) AS vn_s, laps_id
                 FROM vns
                 GROUP BY laps_id
             )
                ,
             rekvs AS (
                 SELECT m.laps_id,
                        m.maksja_id,
                        array_agg(left(r.nimetus, 7)) AS asutused
                 FROM (SELECT laps_id, maksja_id, unnest(rekv_ids)::INTEGER AS rekv_id FROM maksjad) m
                          INNER JOIN ou.rekv r ON r.id = m.rekv_id
                 GROUP BY laps_id, maksja_id
             )
        SELECT a.id,
                null::date as valid,
                a.nimetus                        AS maksja,
               a.regkood                        AS isikukood,
               l.nimi,
               to_char(m.kpv,'DD.MM.YYYY')         AS viimane_makse,
               array_to_string(vn.vn_s, ' ')    AS vn_s,
               array_to_string(r.asutused, ',') AS asutused
        FROM lapsed l
                 INNER JOIN maksjad m ON l.asutus_id = m.maksja_id AND l.laps_id = m.laps_id
                 INNER JOIN vn ON vn.laps_id = l.laps_id
                 INNER JOIN libs.asutus a ON a.id = m.maksja_id
                 INNER JOIN rekvs r ON r.laps_id = m.laps_id AND r.maksja_id = m.maksja_id`,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "maksja", name: "Maksja", width: "20%", show: true},
            {id: "isikukood", name: "Isikukood", width: "10%", show: false},
            {id: "nimi", name: "Lapse nimi", width: "20%", show: true},
            {id: "viimane_makse", name: "Viimane makse", width: "10%", show: true},
            {id: "vn_s", name: "Viitenumbrid", width: "10%", show: true},
            {id: "asutused", name: "Asutused", width: "20%", show: true},
        ]
    },
    select: [{
        sql: `with pank_vv as (
                select *,
                       lapsed.get_laps_from_viitenumber(pank_vv.viitenumber) as laps_id,
                       lapsed.get_rekv_id_from_viitenumber(pank_vv.viitenumber)::integer as rekv_id
                from lapsed.pank_vv  WHERE pank_vv.id = $1::INTEGER
            )
            SELECT $2                                       AS userid,
                   pank_vv.id,
                   to_char(pank_vv.kpv, 'YYYY-MM-DD')::TEXT AS kpv,
                   pank_vv.pank_id,
                   pank_vv.viitenumber,
                   pank_vv.maksja,
                   pank_vv.isikukood,
                   pank_vv.selg,
                   pank_vv.doc_id,
                   pank_vv.summa,
                   pank_vv.iban,
                   pank_vv.pank,
                   pank_vv.aa,
                   mk.number,
                   l.nimi,
                   r.nimetus                                AS asutus
            FROM  pank_vv
                     LEFT OUTER JOIN docs.mk mk ON mk.parentid = pank_vv.doc_id
                     LEFT OUTER JOIN lapsed.laps l ON l.id =pank_vv.laps_id
                     LEFT OUTER JOIN ou.rekv r ON r.id = pank_vv.rekv_id`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `WITH params AS (
                WITH nimed AS (
                    SELECT $1 AS nimi,
                    $2 as isikukood
                    )
                SELECT nimi, regexp_split_to_array(nimi, '\\s+') AS nimed
                FROM nimed
            ),
                 lapsed AS
                     (SELECT get_unique_value_from_array(rekv_ids::TEXT[]) AS asutused,
                             l.nimi,
                             a.id                                          AS asutus_id,
                             l.id                                          AS laps_id
                      FROM libs.asutus a
                               INNER JOIN lapsed.vanemad v ON v.asutusid = a.id
                               INNER JOIN lapsed.cur_lapsed l ON l.id = v.parentid
                              ,
                           params
                      WHERE (nimetus ILIKE '%' || coalesce(params.nimed[1], '') || '%'
                          AND nimetus ILIKE '%' || coalesce(params.nimed[2], '') || '%'
                           AND a.regkood ILIKE coalesce(params.isikukood, '') || '%'
                                )
                     ),
                 maksjad AS (
                     SELECT maksja_id,
                            max(kpv)                                                  AS kpv,
                            get_unique_value_from_array(array_agg(mk.rekvid)::TEXT[]) AS rekv_ids,
                            laps_id
                     FROM lapsed.cur_lapsed_mk mk
                     WHERE maksja_id IN (
                         SELECT asutus_id
                         FROM lapsed
                     )
                     GROUP BY maksja_id, laps_id
                 ),
                 vn AS (
                     WITH vns AS (
                         SELECT (lapsed.get_viitenumber(unnest(m.rekv_ids)::INTEGER, laps_id)) AS vn_s, laps_id
                         FROM maksjad m)
                     SELECT array_agg(vn_s) as vn_s, laps_id
                     FROM vns
                     GROUP BY laps_id
                 )
                    ,
                 rekvs AS (
                     SELECT m.laps_id,
                            m.maksja_id,
                            array_agg(left(r.nimetus, 7)) AS asutused
                     FROM (SELECT laps_id, maksja_id, unnest(rekv_ids)::INTEGER AS rekv_id FROM maksjad) m
                              INNER JOIN ou.rekv r ON r.id = m.rekv_id
                     GROUP BY laps_id, maksja_id
                 )
            SELECT a.nimetus                        AS maksja,
                   l.nimi,
                   m.kpv                            AS viimane_makse,
                   array_to_string(vn.vn_s, ' ')    AS vn_s,
                   array_to_string(r.asutused, ',') AS asutused
            FROM lapsed l
                     INNER JOIN maksjad m ON l.asutus_id = m.maksja_id AND l.laps_id = m.laps_id
                     INNER JOIN vn ON vn.laps_id = l.laps_id
                     INNER JOIN libs.asutus a ON a.id = m.maksja_id
                     INNER JOIN rekvs r ON r.laps_id = m.laps_id AND r.maksja_id = m.maksja_id`,
            not_initial_load: true,
            query: null,
            multiple: true,
            alias: 'maksjad',
            data: []
        }
    ],
    returnData: {
        row: {}
    },
    requiredFields: [],
    saveDoc: `SELECT lapsed.muuda_pank_vv($1::JSONB, $2::INTEGER, $3::INTEGER) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: ``, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "maksja", name: "Maksja", width: "10%"},
            {id: "maksja_ik", name: "Maksja IK", width: "7%"},
            {id: "viitenumber", name: "Viitenr", width: "10%"},
            {id: "iban", name: "Arveldus arve", width: "12%"},
            {id: "pank", name: "Pank", width: "7%"},
            {id: "kpv", name: "Maksepäev", width: "7%", show: true, type: 'date', interval: true},
            {id: "summa", name: "Summa", width: "5%", type: 'number', interval: true},
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
                             LEFT OUTER JOIN docs.mk mk ON mk.parentid = v.doc_id
                             LEFT OUTER JOIN ou.rekv r ON r.id = mk.rekvid
                             LEFT OUTER JOIN ou.userid u ON u.id = $2
                    WHERE coalesce(v.selg, '') NOT LIKE '%intres%'
                      AND coalesce(v.isikukood, '') NOT IN ('75024260')
                    ORDER BY id DESC`,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curPankVV'
    },
    print: [
        {
            view: 'pank_vv',
            params: 'id',
        },
        {
            view: 'pank_vv',
            params: 'sqlWhere'
        },
    ],
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
    importDoc: {
        command: `SELECT result AS id, result, stamp, error_message, data
                  FROM lapsed.sp_salvesta_pank_vv($1::JSONB, $2::INTEGER, $3::INTEGER)`, // $1 - data json, $2 - userid, $3 - rekvid
        type: 'sql',
        alias: 'importVV'
    },
    logs: true

};

