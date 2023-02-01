module.exports = {
    select: [{
        sql: `SELECT id,
                     regkood,
                     nimetus,
                     omvorm,
                     aadress,
                     kontakt,
                     tel,
                     faks,
                     email,
                     muud,
                     tp,
                     staatus,
                     $2::INTEGER                                     AS userid,
                     'ASUTUSED'                                      AS doc_type_id,
                     (properties ->> 'pank')::VARCHAR(20)            AS pank,
                     (properties ->> 'kmkr')::VARCHAR(20)            AS kmkr,
                     (properties ->> 'kehtivus')::DATE               AS kehtivus,
                     (properties ->> 'kehtivus')::DATE               AS valid,
                     (properties -> 'asutus_aa' -> 0 ->> 'aa')::TEXT AS aa,
                     (properties ->> 'palk_email'):: VARCHAR(254)    AS palk_email
              FROM libs.asutus
              WHERE id = $1`,
        sqlAsNew: `select $1::integer as id , $2::integer as userid, 'ASUTUSED' as doc_type_id,
            ''::text as  regkood,
            ''::text as nimetus,
            'ISIK'::text as omvorm,
            ''::text as aadress,
            ''::text as kontakt,
            ''::text as tel,
            ''::text as faks,
            ''::text as email,
            null::text as muud,
            '800699'::text as tp,
            0::integer as staatus,
            ''::varchar(20) as pank,
            '' :: VARCHAR(254)    AS palk_email,            
            ''::varchar(20) as kmkr,
            ''::text as mark,
            ''::TEXT AS aa`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT (e.element ->> 'aa') :: VARCHAR(20)                  AS aa,
                         $2 :: INTEGER                                        AS userid,
                         ((e.element ->> 'kas_palk') :: BOOLEAN)::INTEGER     AS kas_palk,
                         ((e.element ->> 'kas_raama') :: BOOLEAN)::INTEGER    AS kas_raama,
                         ((e.element ->> 'kas_oppetasu') :: BOOLEAN)::INTEGER AS kas_oppetasu,
                         row_number() OVER ()                                 AS id,
                         libs.get_asutuse_aa(a.id, 'RAAMA'::TEXT)             AS default_aa
                  FROM libs.asutus a,
                       json_array_elements(CASE
                                               WHEN (a.properties ->> 'asutus_aa') IS NULL THEN '[]'::JSON
                                               ELSE (a.properties -> 'asutus_aa') :: JSON END) AS e (element)
                  WHERE a.id = $1`, //$1 - doc_id, $2 0 userId
            query: null,
            multiple: true,
            alias: 'asutus_aa',
            data: []

        },
        {
            sql: `SELECT Asutus.id
                  FROM libs.asutus Asutus
                  WHERE (upper(rtrim(ltrim(Asutus.regkood))) = upper($1) OR empty($1))
                    AND (upper(rtrim(ltrim(Asutus.nimetus))) = upper($2) OR empty($2))`, //$1 regkood, $2 nimetus
            query: null,
            multiple: false,
            alias: 'validate_asutus',
            data: [],
            not_initial_load: true

        },
        {
            sql: `SELECT rekl.get_luba_number($1,
                                              (SELECT rekvid FROM ou.userid WHERE id = $2 LIMIT 1))::VARCHAR(20) AS number`, //$1 - id, $2 userId
            query: null,
            multiple: false,
            alias: 'rekl_number',
            data: [],
            not_initial_load: true

        },
        {
            sql: `SELECT *
                  FROM jsonb_to_recordset(
                               get_asutus_kasutus($2::INTEGER, $3::DATE,
                                                  $1::INTEGER)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: [],
            not_initial_load: true

        },
        {
            sql: `SELECT d.*
                  FROM docs.dokumendid($1) d`, //$1 asutus_id
            query: null,
            multiple: true,
            alias: 'dokumenidid',
            data: [],
            not_initial_load: true

        }
    ],
    selectAsLibs: `SELECT *, kehtivus AS valid, regkood AS kood
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
            {id: "aadress", name: "Aadress", width: "25%"},
            {id: "valid", name: "Kehtivus", width: "10%", type: 'date', show: false},
        ],
        sqlString: `SELECT a.*, $2::INTEGER AS userId, a.kehtivus AS valid
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
        command: `SELECT ROW_NUMBER() OVER ()              AS id,
                         (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS prinditud,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu::JSONB) AS ajalugu, d.id
                           FROM libs.asutus d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },

};