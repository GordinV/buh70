module.exports = {
    selectAsLibs: `SELECT DISTINCT a.id,
                                   a.nimetus   AS nimi,
                                   a.regkood   AS isikukood,
                                   $1::INTEGER AS rekvid
                   FROM lapsed.vanemad v
                            INNER JOIN libs.asutus a ON a.id = v.asutusId
                   WHERE v.staatus <> 3`,
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
                     coalesce((v.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN    AS kas_earve,
                     (v.properties ->> 'pank')::TEXT                                      AS pank,
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
            {id: "id", name: "id", width: "10%", show: false},
            {id: "isikukood", name: "Isikukood", width: "20%"},
            {id: "nimi", name: "Nimi", width: "40%"},
            {id: "email", name: "E-mail", width: "15%"},
            {id: "lapsed", name: "Lapsed", width: "25%"}
        ],
        sqlString: `SELECT id,
                           isikukood,
                           nimi,
                           lapsed,
                           aadress,
                           email,
                           tel,
                           $1::INTEGER AS rekvid,
                           $2::INTEGER AS user_id
                    FROM lapsed.cur_vanemad v
                    WHERE rekv_ids @> ARRAY [$1::INTEGER] `,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curLapsed'
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

