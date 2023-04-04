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
                     coalesce((va.arveldus)::BOOLEAN, FALSE)::BOOLEAN                     AS arved,
                     v.properties ->> 'suhtumine'                                         AS suhtumine,
                     coalesce((v.properties ->> 'kas_paberil')::BOOLEAN, FALSE)::BOOLEAN  AS kas_paberil,
                     coalesce((va.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN   AS kas_earve,
                     (va.properties ->> 'pank')::TEXT                                     AS pank,
                     (va.properties ->> 'iban')::TEXT                                     AS iban,
                     coalesce((v.properties ->> 'kas_email')::BOOLEAN, FALSE)::BOOLEAN    AS kas_email,
                     coalesce((v.properties ->> 'kas_esindaja')::BOOLEAN, FALSE)::BOOLEAN AS kas_esindaja,
                     v.muud,
                     a.nimetus::TEXT                                                      AS vanem_nimi,
                     a.regkood::TEXT                                                      AS vanem_isikukood,
                     $2::INTEGER                                                          AS userid,
                     a.nimetus::TEXT                                                      AS nimi,
                     a.regkood::TEXT                                                      AS isikukood,
                     a.aadress::TEXT,
                     a.email::TEXT,
                     a.tel::TEXT
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
                  true as kas_earve,
                  null::text as pank,
                  null::text as iban,
                  false as kas_esindaja,
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
            {id: "isikukood", name: "Isikukood", width: "10%"},
            {id: "nimi", name: "Nimi", width: "20%"},
            {id: "email", name: "E-mail", width: "15%"},
            {id: "printimine", name: "Arved esita", width: "10%"},
            {id: "lapsed", name: "Lapsed", width: "20%"},
            {id: "kehtiv_kpv", name: "Kehtiv seisuga", width: "15%", type: 'date', show: false},
            {id: "kehtivus", name: "Kehtivus", width: "10%", type: 'select', data: ['', 'Jah', 'Ei']},

        ],
        sqlString: `WITH range_parameters AS (
                        SELECT 
                            CASE
                                WHEN $3::DATE::TEXT IS NOT NULL AND $3::DATE::TEXT = '' THEN NULL::DATE
                                ELSE $3::DATE::DATE END::DATE AS kehtiv_kpv,
                            $1::integer                                    AS rekv_id
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
                     )
                
                
                SELECT v.id,
                       v.laps_id,
                       isikukood,
                       nimi,
                       lapsed,
                       aadress,
                       email,v.
                       tel,
                       printimine,
                       range_parameters.rekv_id::INTEGER      AS rekvid,
                       $2::INTEGER    AS user_id,
                       count(*) OVER () AS rows_total,
                       CASE
                           WHEN coalesce(qr.kehtivus, FALSE) IS TRUE THEN
                               'Jah'
                           ELSE
                               'Ei' END                      AS kehtivus,
                       range_parameters.kehtiv_kpv::date as kehtiv_kpv
                FROM lapsed.cur_vanemad v
                         LEFT OUTER JOIN (SELECT * FROM qry_range WHERE coalesce(kehtivus, false) IS TRUE) qr ON qr.id = v.laps_id     ,
                     range_parameters
                WHERE v.rekv_id = range_parameters.rekv_id::INTEGER
                ORDER by v.isikukood`,     //  $1 всегда ид учреждения, $2 - userId
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
        command: `SELECT ROW_NUMBER() OVER () AS id,
                         (ajalugu -> > 'user'
                             )
                             ::TEXT
                                              AS
                                                 kasutaja,
                         to_char((ajalugu -> > 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'
                             )
                                              AS
                                                 koostatud,
                         to_char((ajalugu -> > 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'
                             )
                                              AS
                                                 muudatud,
                         to_char((ajalugu -> > 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'
                             )
                                              AS
                                                 prinditud,
                         to_char((ajalugu -> > 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'
                             )
                                              AS
                                                 prinditud,
                         to_char((ajalugu -> > 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'
                             )
                                              AS
                                                 kustutatud

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

