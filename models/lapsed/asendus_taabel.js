module.exports = {
    selectAsLibs: ``,
    select: [{
        sql: `SELECT lt.id,
                     lt.staatus                                                                AS doc_status,
                     lt.parentid,
                     lt.viitenumber,
                     lt.rekvid,
                     lt.nomid,
                     y.kood                                                                    AS yksys,
                     lt.yksusid,
                     coalesce((n.properties ->> 'kas_umberarvestus')::BOOLEAN, FALSE)::BOOLEAN AS kas_umberarvestus,
                     lt.kuu,
                     lt.aasta,
                     lt.kogus::NUMERIC(14, 4),
                     lt.hind,
                     lt.soodustus,
                     lt.summa::NUMERIC(12, 2),
                     lt.muud,
                     l.isikukood,
                     ltrim(rtrim(l.nimi))::TEXT                                                AS nimi,
                     ltrim(rtrim(ar.nimetus))::TEXT                                            AS asutus,
                     $2                                                                        AS userid,
                     n.kood,
                     n.nimetus                                                                 AS teenus,
                     TRUE                                                                      AS loaded_data
                  FROM
                     lapsed.asendus_taabel lt
                         INNER JOIN lapsed.laps l ON l.id = lt.parentid
                         INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
                         LEFT OUTER JOIN libs.library y ON lt.yksusid = y.id
                         LEFT OUTER JOIN ou.rekv ar ON ar.id = left(lt.viitenumber, 3)::INTEGER
                  WHERE
                     lt.id = $1::INTEGER`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER        AS id,
                  $2 :: INTEGER        AS userid,
                  1::integer as doc_status,
                  null::integer as parentid,
                  null::integer as nomid,
                  null::text as yksus,
                  null::text as viitenumber,
                  date_part('month', now()) as kuu,
                  date_part('year', now()) as aasta,
                  0::numeric as kogus,
                  0::numeric as hind,
                  0::numeric as summa,
                  null::text as isikukood,
                  null::text as nimi,
                  null::text as asutus,
                  null::text as kood,
                  null::text as nimetus,
                  true as loaded_data,
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
        {name: 'viitenumber', type: 'I'},
        {name: 'isikukood', type: 'I'},
        {name: 'kogus', type: 'N'},
        {name: 'kuu', type: 'I'},
        {name: 'aasta', type: 'I'}

    ],
    saveDoc:
        `select lapsed.sp_salvesta_asendus_taabel($1::jsonb, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT lapsed.sp_delete_asendus_taabel($1::INTEGER, id::INTEGER)
                    FROM lapsed.asendus_taabel
                    WHERE id::TEXT IN (SELECT unnest(string_to_array($2::TEXT, ',')))`, // $1 - userId, $2 - docId
    grid:
        {
            gridConfiguration: [
                {id: "id", name: "id", width: "1%", show: false},
                {id: "isikukood", name: "Isikukood", width: "10%"},
                {id: "nimi", name: "Nimi", width: "20%"},
                {id: "viitenumber", name: "Viitenumber", width: "10%"},
                {id: "teenus", name: "Teenus", width: "20%"},
                {id: "yksus", name: "Üksus", width: "12%"},
                {id: "kuu", name: "Kuu", width: "5%", type: "integer", interval: true},
                {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
                {id: "kogus", name: "Kogus", width: "8%", type: "number", interval: true},
                {id: "hind", name: "Hind", width: "8%", type: "number", interval: true},
                {id: "summa", name: "Summa", width: "10%", type: "number", interval: true},
                {id: "asutus", name: "Asutus", width: "10%", type: "text"},
                {id: "select", name: "Valitud", width: "10%", show: false, type: 'boolean', hideFilter: true}
            ],
            sqlString:
                    `SELECT lt.id,
                            lt.parentid,
                            lt.rekvid,
                            lt.nomid,
                            lt.kuu::INTEGER,
                            lt.aasta::INTEGER,
                            lt.kogus::NUMERIC(12, 4),
                            lt.hind::NUMERIC(12, 2),
                            lt.uhik,
                            lt.soodustus AS           soodustus,
                            lt.summa     AS           summa,
                            lt.isikukood,
                            lt.nimi,
                            lt.kood,
                            lt.teenus,
                            lt.yksus     AS           yksus,
                            lt.viitenumber,
                            $2::INTEGER  AS           userid,
                            lt.asutus,
                            lt.muud
                         FROM
                            lapsed.cur_asendus_taabel lt
                         WHERE
                            lt.rekvid IN (SELECT rekv_id
                                              FROM get_asutuse_struktuur($1::INTEGER))`,     //  $1 всегда ид учреждения, $2 - userId
            params: '',
            alias: 'curAsendusTaabel',
            totals: `sum(summa) over() as summa_kokku`
        },
    print: [
        {
            view: 'asendus_taabel_register',
            params: 'id'
        },
        {
            view: 'asendus_taabel_register',
            params: 'sqlWhere'
        },
    ],
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                               AS id,
                         (ajalugu ->> 'user')::TEXT                                         AS kasutaja,
                         to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS koostatud,
                         to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS muudatud,
                         to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS')   AS prinditud,
                         to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS') AS kustutatud
                      FROM
                         (
                             SELECT jsonb_array_elements(d.ajalugu) AS ajalugu
                                 FROM
                                    lapsed.asendus_taabel              d,
                                    ou.userid                          u
                                 WHERE
                                    d.id = $1
                                        AND u.id = $2
                         )                                                                     qry`,
        type: "sql",
        alias: "getLogs"
    },
    importTaabel: {
        command: `SELECT error_code,
                         result,
                         error_message
                      FROM
                         lapsed.import_laste_taabelid($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importTaabel'
    },
    executeTask: (task, docId, userId) => {
        // выполнит задачу, переданную в параметре

        let executeTask = task;
        if (executeTask.length == 0) {
            executeTask = ['start'];
        }

        let taskFunction = eval(executeTask[0]);
        return taskFunction(docId, userId);
    },
    getIsik: {
        command: `SELECT *
                      FROM (
                             WITH params AS (
                                 SELECT $4::TEXT             AS vn,
                                        left($4, 3)::INTEGER AS rekv_id,
                                        $1::INTEGER          AS doc_id,
                                        $2::INTEGER          AS user_id,
                                        $3::DATE             AS kpv
                             )
                             SELECT l.id,
                                    l.isikukood,
                                    l.nimi,
                                    r.nimetus AS                                                              asutus
                                 FROM
                                    (SELECT laps_id FROM params, lapsed.get_laps_from_viitenumber(params.vn)) lid,
                                    lapsed.laps                                                               l,
                                    ou.rekv                                                                   r,
                                    params
                                 WHERE
                                    l.id = lid.laps_id
                                        AND r.id = params.rekv_id
                         ) qry
                      LIMIT 1`,
        type: 'sql',
        alias: 'getIsik'
    },
    /*
        KoostaUlekanneMakse: {
            command: `SELECT error_code, result, error_message, doc_type_id
                      FROM docs.ulekanne_makse($2::INTEGER, (SELECT to_jsonb(row.*)
                                                             FROM (SELECT $1          AS mk_id,
                                                                          $3::DATE    AS maksepaev,
                                                                          $4::TEXT    AS viitenumber,
                                                                          $5::NUMERIC AS kogus) row))`, //$1 - docs.doc.id, $2 - userId, $3 - maksepaev
            type: "sql",
            alias: 'KoostaUlekanneMakse'
        },
    */


};

