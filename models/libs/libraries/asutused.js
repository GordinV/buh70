module.exports = {
    select: [{
        sql: `SELECT *,
                     $2::INTEGER                                     AS userid,
                     'ASUTUSED'                                      AS doc_type_id,
                     (properties ->> 'pank')::VARCHAR(20)            AS pank,
                     (properties ->> 'kmkr')::VARCHAR(20)            AS kmkr,
                     (properties ->> 'kehtivus')::DATE               AS kehtivus,
                     (properties -> 'asutus_aa' -> 0 ->> 'aa')::TEXT AS aa
              FROM libs.asutus
              WHERE id = $1`,
        sqlAsNew: `select $1::integer as id , $2::integer as userid, 'ASUTUSED' as doc_type_id,
            ''::text as  regkood,
            ''::text as nimetus,
            ''::text as omvorm,
            ''::text as aadress,
            ''::text as kontakt,
            ''::text as tel,
            ''::text as faks,
            ''::text as email,
            null::text as muud,
            ''::text as tp,
            0::integer as staatus,
            ''::varchar(20) as pank,
            ''::varchar(20) as kmkr,
            ''::text as mark,
            ''::TEXT AS aa`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT (e.element ->> 'aa') :: VARCHAR(20) AS aa,
                         $2 :: INTEGER                       AS userid
                  FROM libs.asutus a,
                       json_array_elements(CASE
                                               WHEN (a.properties ->> 'asutus_aa') IS NULL THEN '[]'::JSON
                                               ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (element)
                  WHERE a.id = $1`, //$1 - doc_id, $2 0 userId
            query: null,
            multiple: true,
            alias: 'asutus_aa',
            data: []

        }, {
            sql: `SELECT Asutus.id
                  FROM libs.asutus Asutus
                  WHERE (upper(rtrim(ltrim(Asutus.regkood))) = upper($1) OR empty($1))
                    AND (upper(rtrim(ltrim(Asutus.nimetus))) = upper($2) OR empty($2))`, //$1 regkood, $2 nimetus
            query: null,
            multiple: false,
            alias: 'validate_asutus',
            data: []

        }
    ],
    selectAsLibs: `SELECT *
                   FROM com_asutused a
                   WHERE libs.check_asutus(a.id::INTEGER, $1::INTEGER)
                     AND (kehtivus IS NULL OR kehtivus >= date())
                   ORDER BY nimetus`, //$1 - rekvId

    libGridConfig: {
        grid: [
            {id: "id", name: "id", width: "50px", show: false},
            {id: "regkood", name: "Isikukood", width: "25%"},
            {id: "nimetus", name: "Nimi", width: "75%"}
        ]
    },
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'regkood', type: 'C', serverValidation: 'validateIsikukood'},
        {name: 'nimetus', type: 'C'},
        {name: 'omvorm', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_asutus($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_asutus($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Reg.kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "omvorm", name: "Om.vorm", width: "20%"},
            {id: "aadress", name: "Aadress", width: "25%"}
        ],
        sqlString: `SELECT a.*, $2::INTEGER AS userId
                    FROM cur_asutused a
                    WHERE libs.check_asutus(a.id::INTEGER, $1::INTEGER)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAsutused'
    },
    importAsutused: {
        command: `SELECT error_code, result, error_message
                  FROM lapsed.import_asutused($1::JSONB, $2::INTEGER, $3::INTEGER)`,//$1 data [], $2 - userId, $3 rekvid
        type: 'sql',
        alias: 'importAsutused'
    },

    validateIsikukood: {
        command: `SELECT id
                  FROM libs.asutus
                  WHERE regkood = $1::TEXT
                  ORDER BY id DESC
                  LIMIT 1`,
        type: 'sql',
        alias: 'validateIsikukood'
    },
    print: [
        {
            view: 'asutus_register',
            params: 'id'
        },
        {
            view: 'asutus_register',
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
                           SELECT jsonb_array_elements(d.ajalugu) AS ajalugu, d.id
                           FROM libs.asutus d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry`,
        type: "sql",
        alias: "getLogs"
    },

};