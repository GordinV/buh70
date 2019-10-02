module.exports = {
    selectAsLibs: ``,

    select: [{
        sql: `SELECT lt.id,
                     lt.parentid,
                     lt.rekvid,
                     lt.nomid,
                     lt.kuu,
                     lt.aasta,
                     lt.kogus,
                     lt.muud,
                     l.isikukood,
                     l.nimi,
                     $2        AS userid,
                     n.kood,
                     n.nimetus AS teenus
              FROM lapsed.lapse_taabel lt
                       INNER JOIN lapsed.laps l ON l.id = lt.parentid
                       INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
              WHERE lt.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  null::integer as nomid,
                  date_part('month', now()) as kuu,
                  date_part('year', now()) as aasta,
                  0::numeric as kogus,
                  null::text as isikukood,
                  null::text as nimi,
                  null::text as kood,
                  null::text as nimetus,
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
        }
    ,


    requiredFields: [
        {name: 'nomid', type: 'I'},
        {name: 'parentid', type: 'I'},
        {name: 'kogus', type: 'N'},
        {name: 'kuu', type: 'I'},
        {name: 'aasta', type: 'I'}

    ],
    saveDoc:
        `select lapsed.sp_salvesta_lapse_taabel($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc:
            `SELECT error_code, result, error_message
             FROM lapsed.sp_delete_lapse_taabel($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "10%", show: false},
                {id: "isikukood", name: "Isikukood", width: "20%"},
                {id: "nimi", name: "Nimi", width: "30%"},
                {id: "kood", name: "Kood", width: "10%"},
                {id: "teenus", name: "Teenus", width: "30%"},
                {id: "kuu", name: "Kuu", width: "10%"},
                {id: "aasta", name: "Aasta", width: "10%"},
                {id: "kogus", name: "Kogus", width: "10%"},
            ],
            sqlString:
                    `SELECT lt.id,
                            lt.parentid,
                            lt.rekvid,
                            lt.nomid,
                            lt.kuu,
                            lt.aasta,
                            lt.kogus,
                            lt.isikukood,
                            lt.nimi,
                            lt.kood,
                            lt.teenus,
                            $2::INTEGER AS userid
                     FROM lapsed.cur_lapse_taabel lt
                     WHERE rekvid = $1::INTEGER
            `,     //  $1 всегда ид учреждения, $2 - userId
            params:
                '',
            alias:
                'curLapseTaabel'
        }
}
;

