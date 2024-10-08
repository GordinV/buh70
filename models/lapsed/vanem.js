module.exports = {
    selectAsLibs: `
        SELECT DISTINCT a.id,
                        a.nimetus                               AS nimi,
                        a.regkood                               AS isikukood,
                        $1::INTEGER                             AS rekvid,
                        a.email                                 AS email,
                        NULL::DATE                              AS valid,
                        lk.parentid,
                        lapsed.get_viitenumber($1, lk.parentid) AS viitenr
        FROM lapsed.vanemad v
                 INNER JOIN libs.asutus a ON a.id = v.asutusid
                 INNER JOIN (SELECT DISTINCT parentid, rekvid
                             FROM lapsed.lapse_kaart lk
                             WHERE rekvid = $1
                               AND staatus <> 3) lk ON lk.parentid = v.parentid
        WHERE a.staatus <> 3
          AND v.staatus <> 3`,
    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "isikukood", name: "Isikukood", width: "100px"},
            {id: "nimi", name: "Nimi", width: "100px"}
        ]
    },
    select: [{
        sql: `SELECT v.id,
                     v.parentid,
                     v.asutusid,
                     coalesce((va.arveldus)::BOOLEAN, FALSE)::BOOLEAN                                  AS arved,
                     v.properties ->> 'suhtumine'                                                      AS suhtumine,
                     va.kas_paberil                                                                    AS kas_paberil,
                     coalesce((va.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN                AS kas_earve,
                     (va.properties ->> 'pank')::TEXT                                                  AS pank,
                     (va.properties ->> 'iban')::TEXT                                                  AS iban,
                     va.kas_email                                                                      AS kas_email,
                     to_char(CASE
                                 WHEN NOT coalesce((v.properties ->> 'kas_email')::BOOLEAN, FALSE)::BOOLEAN
                                     THEN gomonth(make_date(year(current_date), month(current_date), 1), 1)
                                 ELSE (v.properties ->> 'email_alates')::DATE END, 'YYYY-MM-DD')::TEXT AS email_alates,
                     coalesce((v.properties ->> 'kas_esindaja')::BOOLEAN, FALSE)::BOOLEAN              AS kas_esindaja,
                     v.muud,
                     a.nimetus::TEXT                                                                   AS vanem_nimi,
                     a.regkood::TEXT                                                                   AS vanem_isikukood,
                     $2::INTEGER                                                                       AS userid,
                     a.nimetus::TEXT                                                                   AS nimi,
                     a.regkood::TEXT                                                                   AS isikukood,
                     a.aadress::TEXT,
                     a.email::TEXT,
                     a.tel::TEXT,
                     exists(
                             (SELECT id
                              FROM ou.rekv r
                              WHERE r.nimetus ILIKE '%lasteaed%'
                                AND r.id = va.rekvid))::BOOLEAN                                        AS kas_lasteaed

              FROM lapsed.vanemad v
                       INNER JOIN libs.asutus a ON a.id = v.asutusId
                       LEFT OUTER JOIN lapsed.vanem_arveldus va ON v.parentid = va.parentid
                  AND va.asutusid = a.id
                  AND va.rekvid IN (SELECT rekvid
                                    FROM ou.userid
                                    WHERE id = $2)
              WHERE v.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  0::INTEGER AS asutusid,                  
                  null::text as lapse_isikukood,
                  null::text as lapse_nimi,
                  null::text as  vanem_isikukood,
                  null::text as vanem_nimi,
                  false as arved,
                  null::text as suhtumine,
                  false as kas_paberil,
                  true as kas_email,
                  NULL::date as email_alates,
                  true as kas_earve,
                  null::text as pank,
                  null::text as iban,
                  false as kas_esindaja,
                  false as kas_lasteaed,
                  null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT l.id,
                         l.isikukood,
                         l.nimi,
                         $2 AS userid
                  FROM lapsed.laps l
                           INNER JOIN lapsed.vanemad v ON l.id = v.parentid
                  WHERE l.staatus < 3
                    AND v.staatus < 3
                    AND v.asutusid IN (SELECT asutusid
                                       FROM lapsed.vanemad
                                       WHERE id = $1)`,
            query: null,
            multiple: true,
            alias: 'lapsed',
            data: []
        }
    ],
    returnData: {
        row: {},
        lapsed: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'isikukood', name: 'Isikukood', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'nimi', name: 'Nimi', width: '100px', show: true, type: 'text', readOnly: false}
        ],
    },


    requiredFields: [
        {name: 'parentid', type: 'I'},
        {name: 'asutusid', type: 'I'},

    ],

    /*
    executeCommand: {
        command: `SELECT result, selgitus, summa
                  FROM docs.sp_calc_kulum(?tnId::INTEGER, current_date::DATE)`,
        type: 'sql',
        alias: 'arvestaKulum'
    },
*/
    saveDoc: `select lapsed.sp_salvesta_vanem($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM lapsed.sp_delete_vanem($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "row_id", name: "Jrk", width: "3%", show: true, hideFilter: true},
            {id: "isikukood", name: "Isikukood", width: "8%"},
            {id: "nimi", name: "Nimi", width: "12%"},
            {id: "email", name: "E-mail", width: "15%"},
            {id: "printimine", name: "Arved esita", width: "10%"},
            {id: "lapsed", name: "Lapsed", width: "12%"},
            {id: "kehtiv_kpv", name: "Kehtiv seisuga", width: "1%", type: 'date', show: false},
            {id: "kehtivus", name: "Kehtivus", width: "5%", type: 'select', data: ['', 'Jah', 'Ei']},
            {id: "iban", name: "Iban", width: "10%"},
            {id: "asutused", name: "Asutused", width: "10%"},
            {id: "aa", name: "Aa", width: "1%", show:false},

        ],
        sqlString: `WITH range_parameters AS (
                        SELECT 
                            CASE
                                WHEN $3::DATE::TEXT IS NOT NULL AND $3::DATE::TEXT = '' THEN NULL::DATE
                                ELSE $3::DATE::DATE END::DATE AS kehtiv_kpv,
                            $1::integer                                    AS rekv_id
                        ),
                     rekv_ids AS (
                         SELECT a.rekv_id
                         FROM range_parameters,
                              get_asutuse_struktuur(range_parameters.rekv_id) a
                     ),                        
                     cur_lapsed AS (
                         SELECT l.id,
                                lk.lopp_kpv,
                                lk_range
                         FROM lapsed.laps l
                                  JOIN (SELECT parentid,
                                               array_agg(lk_range) AS lk_range,
                                               max(lopp_kpv)       AS lopp_kpv
                                        FROM (
                                                 SELECT parentid,
                                                        (k.properties ->> 'lopp_kpv')::DATE AS lopp_kpv,
                                                        ('[' || ((k.properties ->> 'alg_kpv')::DATE)::TEXT || ',' || (CASE
                                                                                                                          WHEN (k.properties ->> 'alg_kpv')::DATE >=
                                                                                                                               (k.properties ->> 'lopp_kpv')::DATE
                                                                                                                              THEN (k.properties ->> 'alg_kpv')::DATE
                                                                                                                          ELSE (k.properties ->> 'lopp_kpv')::DATE END)::TEXT ||
                                                         ')') ::DATERANGE                   AS lk_range
                                                 FROM lapsed.lapse_kaart k,
                                                      range_parameters
                                                 WHERE k.staatus <> 3
                                                   AND k.rekvid = range_parameters.rekv_id
                                                 GROUP BY parentid,  (k.properties ->> 'alg_kpv'), (k.properties ->> 'lopp_kpv')
                                             ) qry,
                                             range_parameters
                                        GROUP BY parentid) lk ON lk.parentid = l.id
                         WHERE l.staatus <> 3
                     ),

                     qry_range AS (
                         WITH qry_range AS (
                             SELECT DISTINCT unnest(lk.lk_range) AS range,
                                             lk.id
                             FROM cur_lapsed lk)
                         SELECT DISTINCT bool_or(lk.range @> range_parameters.kehtiv_kpv) AS kehtivus,
                                         lk.id,
                                         array_agg(lk.range)                              AS range
                         FROM qry_range lk,
                              range_parameters
                         GROUP BY lk.id
                     ),
                     asutused AS (SELECT v.id,
                                         array_agg(r.id)                    AS a_ids,
                                         array_agg(ltrim(rtrim(r.nimetus))) AS asutused,
                                         get_unique_value_from_array(array_agg(v.printimine))            AS printimine,
                                         get_unique_value_from_array(array_agg(v.iban))                  AS iban,
                                         array_agg(v.aa)                    AS aa
                                  FROM lapsed.cur_vanemad v
                                           INNER JOIN ou.rekv r ON r.id = v.rekv_id
                                  WHERE v.rekv_id IN (SELECT r.rekv_id FROM rekv_ids r)
                                  GROUP BY v.id
                     )
                         select * from (                                
                            SELECT DISTINCT v.id,
                                   v.laps_id,
                                   isikukood,
                                   nimi,
                                   lapsed,
                                   aadress,
                                   email,v.
                                   tel,
                                   range_parameters.rekv_id::INTEGER      AS rekvid,
                                   $2::INTEGER    AS user_id,
                                   count(*) OVER () AS rows_total,
                                   CASE
                                       WHEN coalesce(qr.kehtivus, FALSE) IS TRUE THEN
                                           'Jah'
                                       ELSE
                                           'Ei' END                      AS kehtivus,
                                   range_parameters.kehtiv_kpv::date as kehtiv_kpv,
                                    array_to_string(a.printimine, ',')          AS printimine,
                                    array_to_string(a.asutused, ',')            AS asutused,
                                    trim(array_to_string(a.iban, ','), ',')     AS iban,
                                    array_to_string(a.aa, ',')                  AS aa,
                                    a.a_ids @> ARRAY [range_parameters.rekv_id] AS kas_muuda                       
                            FROM lapsed.cur_vanemad v
                                     INNER JOIN asutused a ON a.id = v.id                
                                     LEFT OUTER JOIN (SELECT * FROM qry_range WHERE coalesce(kehtivus, false) IS TRUE) qr ON qr.id = v.laps_id     ,
                                 range_parameters) qry
                                 order by isikukood`,     //  $1 всегда ид учреждения, $2 - userId
        params: ['rekvid', 'userid', 'kehtiv_kpv'],
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
            view: 'vanem_register',
            params: 'id'
        },
        {
            view: 'vanem_register',
            params: 'sqlWhere'
        },
    ],
    importVanemad: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_vanemad($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importVanemad'
    },
    importVanemateRegister: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_vanem_register($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importVanemateRegister'
    },
    importPankLeping: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.loe_panga_lepingud($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importPankLeping'
    },


    validateEsindaja: {
        command: `SELECT id
                  FROM lapsed.vanemad
                  WHERE parentId IN (SELECT parentid
                                     FROM lapsed.vanemad
                                     WHERE id = $1)
                    AND coalesce((properties ->> 'kas_esindaja')::BOOLEAN, FALSE)::BOOLEAN`,
        TYPE: 'sql',
        ALIAS: 'validateEsindaja'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH:MI:SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH:MI:SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH:MI:SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH:MI:SS') AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements(d.ajalugu)
                                      AS
                                      ajalugu
                           FROM lapsed.vanemad d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },


};

