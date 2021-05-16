module.exports = {
    selectAsLibs: ``,

    select: [{
        sql: `SELECT lt.id,
                     lt.staatus                    AS doc_status,
                     lt.parentid,
                     lt.rekvid,
                     lt.nomid,
                     lt.lapse_kaart_id,
                     lk.properties ->> 'yksus'     AS yksys,
                     lk.properties ->> 'all_yksus' AS all_yksys,
                     lt.kuu,
                     lt.aasta,
                     lt.kogus,
                     lt.muud,
                     l.isikukood,
                     l.nimi,
                     $2                            AS userid,
                     n.kood,
                     n.nimetus                     AS teenus
              FROM lapsed.lapse_taabel lt
                       INNER JOIN lapsed.laps l ON l.id = lt.parentid
                       INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
                       LEFT OUTER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
              WHERE lt.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  1::integer as doc_status,
                  null::integer as nomid,
                  null::integer as lapse_kaart_id,
                  null::text as yksus,
                  null::text as all_yksus,
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
        {name: 'lapse_kaart_id', type: 'I'},
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
                {id: "teenus", name: "Teenus", width: "30%"},
                {id: "yksus", name: "Üksus", width: "20%"},
                {id: "kuu", name: "Kuu", width: "10%", type: "integer", interval: true},
                {id: "aasta", name: "Aasta", width: "10%", type: "integer"},
                {id: "kogus", name: "Kogus", width: "10%", type: "number", interval: true},
                {id: "hind", name: "Hind", width: "10%", type: "number", interval: true},
                {id: "uhik", name: "Ühik", width: "5%"},
                {id: "soodustus", name: "Soodustus", width: "10%", type: "number"},
                {id: "summa", name: "Summa", width: "15%", type: "number", interval: true},
            ],
            sqlString:
                `with qryNoms as 
                        (SELECT lt.id,
                            lt.parentid,
                            lt.rekvid,
                            lt.nomid,
                            lt.kuu,
                            lt.aasta,
                            lt.kogus::NUMERIC(12, 2),
                            lt.hind::NUMERIC(12, 2),
                            lt.uhik,
                            (CASE
                                 WHEN lt.kas_protsent THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                           ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                 ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus END)::NUMERIC(12, 2)     AS soodustus,
                            ((lt.hind * lt.kogus - (CASE
                                             WHEN lt.kas_protsent THEN (lt.hind * lt.kogus)::NUMERIC(12, 2) *
                                                                       ((lt.soodustus * lt.sooduse_kehtivus) / 100)
                                             ELSE lt.soodustus * lt.kogus * lt.sooduse_kehtivus END)))::NUMERIC(12, 2)                                            AS summa,
                            lt.isikukood,
                            lt.nimi,
                            lt.kood,
                            lt.teenus,
                            (coalesce(lt.yksus, '') ||
                             CASE WHEN lt.all_yksus IS NULL THEN '' ELSE '-' || lt.all_yksus END) AS yksus,
                            $2::INTEGER                                                           AS userid
                     FROM lapsed.cur_lapse_taabel lt
                     WHERE rekvid = $1::INTEGER
                     )
                     select * from qryNoms
                     ORDER BY aasta DESC, kuu DESC, nimi`,     //  $1 всегда ид учреждения, $2 - userId
            params: '',
            alias: 'curLapseTaabel',
            totals: ` sum(soodustus) over() as soodustus_kokku,  
                   sum(summa) over() as summa_kokku `
        },
    print: [
        {
            view: 'lapse_taabel_register',
            params: 'id'
        },
        {
            view: 'lapse_taabel_register',
            params: 'sqlWhere'
        },
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS') AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements(d.ajalugu) AS ajalugu
                           FROM lapsed.lapse_taabel d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },

};

