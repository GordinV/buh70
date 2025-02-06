module.exports = {
    select: [{
        sql: `SELECT $2 :: INTEGER                                                        AS userid,
                     'PALK_TAABEL'                                                        AS doc_type_id,
                     p.id,
                     p.lepingid,
                     p.kuu,
                     p.aasta,
                     p.kokku,
                     p.too,
                     p.paev,
                     p.ohtu,
                     p.oo,
                     p.tahtpaev,
                     p.puhapaev,
                     p.uleajatoo,
                     p.status,
                     p.muud,
                     coalesce((p.properties ->> 'tahtpaeva_tunnid')::NUMERIC, 0)::NUMERIC AS tahtpaeva_tunnid,
                     t.parentid
              FROM palk.palk_taabel1 p
                       INNER JOIN palk.tooleping t ON t.id = p.lepingid
              WHERE p.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                     'PALK_TAABEL' AS doc_type_id,
                      0 as id,
                      0::integer as lepingid,
                      month(current_date)::integer as kuu,
                      year(current_date)::integer as aasta,
                      0::numeric(12,4) as kokku,
                      0::numeric(12,4) as too,
                      0::numeric(12,4) as paev,
                      0::numeric(12,4) as ohtu,
                      0::numeric(12,4) as oo,
                      0::numeric(12,4) as tahtpaev,
                      0::numeric(12,4) as puhapaev,
                      0::numeric(12,4) as uleajatoo,
                      0::numeric(12,4) as tahtpaeva_tunnid,
                      1 as status,
                      0::integer          as parentid,
                      null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT *
                  FROM
                      jsonb_to_recordset((
                                             SELECT
                                                 p.data
                                             from
                                                 palk.sp_import_taabel_from_virosoft($2::integer,$3::integer, $1::JSONB) p
                                         )
                      )
                          AS x (error_message TEXT, error_code INTEGER, result INTEGER)`,
            query: null,
            multiple: false,
            alias: 'importDok',
            data: [],
            not_initial_load: true
        },

    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'lepingid', type: 'I'},
        {name: 'kuu', type: 'I'},
        {name: 'aasta', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_palk_taabel($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM palk.sp_delete_palk_taabel($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "isik", name: "Isik", width: "25%"},
            {id: "osakond", name: "Osakond", width: "15%"},
            {id: "amet", name: "Amet", width: "15%"},
            {id: "kokku", name: "Kokku", width: "15%"},
            {id: "paev", name: "Tööpäevas", width: "15%"},
            {id: "puhkus", name: "Pühapäevas", width: "10%"},
            {id: "kuu", name: "Kuu", width: "15%"},
            {id: "aasta", name: "Aasta", width: "15%"},
        ],
        sqlString: `SELECT t.*, $2::INTEGER AS userId
                    FROM palk.cur_palk_taabel t
                    WHERE (t.rekvid = $1 OR rekvid IS NULL)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTaabel1'
    },
    executeCommand: {
        command: `SELECT *
                  FROM jsonb_to_recordset(
                               (
                                   SELECT qry.data
                                   FROM (
                                            SELECT *
                                            FROM palk.gen_taabel1($1::INTEGER, $2::JSON)
                                        ) qry
                               )
                           ) AS x (error_message TEXT, error_code INTEGER, result INTEGER)
        `, //$1 - user_id, $2 - params
        type: 'sql',
        alias: 'genTaabel'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (qry.ajalugu ->> 'user')::VARCHAR(20)                                                       AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu) AS ajalugu, d.id
                           FROM palk.palk_taabel1 d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (qry.ajalugu ->> 'user') IS NOT NULL
        `,
        type: "sql",
        alias: "getLogs"
    },
    importDoc: {
        comment: 'import from virosoft',
        command: `SELECT result AS id, result, error_message, $2::integer as userId, $3::integer as rekvId
                  FROM palk.sp_import_taabel_from_virosoft($2::integer,$3::integer, $1::JSONB)`, // $1 - data json, $2 - userid, $3 - rekvid
        type: 'sql',
        alias: 'importDok'
    },

};