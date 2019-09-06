module.exports = {
    selectAsLibs: ``,
    select: [{
        sql: `SELECT l.id,
                     l.isikukood,
                     l.nimi,
                     l.properties ->> 'viitenumber' AS viitenumber,
                     l.muud,
                     $2                             AS userid
              FROM lapsed.laps l
              WHERE l.id = $1`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  null::text as isikukood,
                  null::text as nimi,
                  null::text as viitenumber,
                  null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'isikukood', type: 'C'},
        {name: 'nimi', type: 'T'}
    ],
    /*
    executeCommand: {
        command: `SELECT result, selgitus, summa
                  FROM docs.sp_calc_kulum(?tnId::INTEGER, current_date::DATE)`,
        type: 'sql',
        alias: 'arvestaKulum'
    },
*/
    saveDoc: `select lapsed.sp_salvesta_laps($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM lapsed.sp_delete_laps($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "isikukood", name: "Isikukood", width: "30%"},
            {id: "nimi", name: "Nimi", width: "40%"},
            {id: "yksused", name: "Üksused", width: "30%"}
        ],
        sqlString: `SELECT id,
                           isikukood,
                           nimi,
                           yksused,
                           $1::INTEGER AS rekvid,
                           $2::INTEGER AS user_id
                    FROM lapsed.cur_lapsed l
                    WHERE rekv_ids @> ARRAY [$1::INTEGER]::INTEGER[]
        `,     //  $1 всегда ид учреждения, $2 - userId
        params: '',
        alias: 'curLapsed'
    }


};

//WHERE rekv_ids @> ARRAY [$1]::INTEGER[]
