module.exports = {
    select: [{
        sql: `SELECT $2 :: INTEGER AS userid,
                     'TOOGRAF'     AS doc_type_id,
                     p.id,
                     p.lepingid,
                     p.kuu,
                     p.aasta,
                     p.tund,
                     p.status,
                     p.muud,
                     t.parentid
              FROM palk.toograf p
                       INNER JOIN palk.tooleping t ON t.id = p.lepingid
              WHERE p.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                     'TOOGRAF' AS doc_type_id,
                      0 as id,
                      0::integer as lepingid,
                      month(current_date)::integer as kuu,
                      year(current_date)::integer as aasta,
                      0::numeric(12,4) as tund,
                      1 as status,
                      0::integer          as parentid,
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
        {name: 'lepingid', type: 'I'},
        {name: 'kuu', type: 'I'},
        {name: 'aasta', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_toograafik($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM palk.sp_delete_toograafik($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "isik", name: "Isik", width: "25%"},
            {id: "osakond", name: "Osakond", width: "15%"},
            {id: "amet", name: "Amet", width: "15%"},
            {id: "tund", name: "Tunnid", width: "15%"},
            {id: "kuu", name: "Kuu", width: "15%"},
            {id: "aasta", name: "Aasta", width: "15%"},
        ],
        sqlString: `SELECT t.*, $2::INTEGER AS userId
                    FROM palk.cur_toografik t
                    WHERE (t.rekvid = $1 OR rekvid IS NULL)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curToograf'
    },
    executeCommand: {
        command: `SELECT t.result as tunnid,
                         t.tahtpaeva_tunnid,
                         palk.get_holidays($1::JSONB) AS tahtpaevad
                  FROM palk.get_taabel2($1::JSONB) t`, //$1 - params ("lepingid":4, "kuu":4, "aasta":2018)
        type: 'sql',
        alias: 'calcTaabel'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                  AS id,
                         (qry.ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((qry.ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)             AS koostatud,
                         coalesce(to_char((qry.ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)             AS muudatud,
                         coalesce(to_char((qry.ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)             AS prinditud,
                         coalesce(to_char((qry.ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)             AS
                                                                  email,
                         coalesce(to_char((qry.ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)             AS earve,
                         coalesce(to_char((qry.ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)             AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu) AS ajalugu, d.id
                           FROM palk.toograf d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (qry.ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },

};