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
                     v.properties ->> 'arved'     AS arved,
                     v.properties ->> 'suhtumine' AS suhtumine,
                     v.muud,
                     a.nimetus                    AS vanem_nimi,
                     a.regkood                    AS vanem_isikukood,
                     $2::INTEGER                  AS userid
              FROM lapsed.vanemad v
                       INNER JOIN libs.asutus a ON a.id = v.asutusId
              WHERE v.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  0::INTEGER AS asutusid,                  
                  null::text as lapse_isikukood,
                  null::text as lapse_nimi,
                  null::text as  vanem_isikukood,
                  null::text as vanem_nimi,
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
                    AND v.asutusid IN (SELECT asutusid FROM lapsed.vanemad WHERE id = $1)`,
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
            {id: 'nimi', name: 'Nimi', width: '100px', show: true, type: 'text', readOnly: false},
        ],
    },


    requiredFields: [
        {name: 'parentid', type: 'I'},
        {name: 'asutusid', type: 'I'}
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
            {id: "isikukood", name: "Isikukood", width: "30%"},
            {id: "nimi", name: "Nimi", width: "40%"},
            {id: "lapsed", name: "Lapsed", width: "30%"}
        ],
        sqlString: `SELECT id,
                           isikukood,
                           nimi,
                           lapsed,
                           $1::INTEGER AS rekvid,
                           $2::INTEGER AS user_id
                    FROM lapsed.cur_vanemad v
                    WHERE rekv_ids @> ARRAY [$1::INTEGER] `,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curLapsed'
    }


};

