module.exports = {
    selectAsLibs: `SELECT
                       $1               AS rekv_id,
                       l.properties::jsonb->'palgaastmed' -> (jsonb_array_length(l.properties::jsonb->'palgaastmed') - 1) ->>
                       'summa'          as summa,
                       (l.properties::jsonb ->'palgaastmed'-> (jsonb_array_length(l.properties::jsonb->'palgaastmed') - 1) ->>
                        'alates')::date as alates,
                       id,
                       kood,
                       (l.properties::JSONB ->> 'valid')::DATE AS valid

                   from
                       libs.library l
                   where
                         l.library = 'PALGAASTMED'
                     and status < 3`,
    select: [{
        sql: `SELECT
                  l.id,
                  (l.properties::jsonb->'palgaastmed' -> (jsonb_array_length(l.properties::jsonb->'palgaastmed') - 1) ->>
                   'summa')::numeric(12, 2)               as summa,
                  (l.properties::jsonb->'palgaastmed' -> (jsonb_array_length(l.properties::jsonb->'palgaastmed') - 1) ->>
                   'alates')::date                        as alates,
                  l.rekvid,
                  l.kood,
                  l.nimetus,
                  l.muud,
                  l.status,
                  l.library,
                  $2::INTEGER                             AS userid,
                  'PALGASTMED'                            AS doc_type_id,
                  (l.properties::JSONB ->> 'valid')::DATE AS valid
              FROM
                  libs.library l
              WHERE
                  l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'PALGASTMED' as doc_type_id,
            0 as summa,
            null::date as alates,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            null:: text as palgaastmed,
            'PALGASTMED'::text as library,
            null::date as valid,
            0::integer as status,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT
                      $1 as rekv_id,
                      *
                  FROM
                      jsonb_to_recordset(
                              get_allikas_kasutus($2::INTEGER, $3::date)
                      ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE
                      error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: []
        },
        {
            sql: `
                select *
                from
                    (
                        SELECT
                            (jsonb_array_elements(properties::jsonb->'palgaastmed') ->> 'id')::integer           as id,
                            (jsonb_array_elements(properties::jsonb->'palgaastmed') ->> 'summa')::numeric(12, 2) AS summa,
                            (jsonb_array_elements(properties::jsonb->'palgaastmed') ->> 'alates')::date          AS alates
                        FROM
                            libs.library l
                        WHERE
                            l.id = $1
                    ) qry
                order by
                    alates desc `,
            query: null,
            multiple: true,
            alias: 'palgaastmed',
            data: []

        }
    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_palgaastmed($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT
                    error_code,
                    result,
                    error_message
                FROM
                    libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "summa", name: "Summa", width: "35%"},
            {id: "alates", name: "Alates", width: "35%"}
        ],
        sqlString: `SELECT
                        id,
                        kood,
                        coalesce((l.properties::jsonb -> 'palgaastmed' ->
                                  (jsonb_array_length(l.properties::jsonb -> 'palgaastmed') - 1) ->>
                                  'summa')::numeric(12, 2),
                                 0)::numeric                     as summa,
                        coalesce((l.properties::jsonb -> 'palgaastmed' ->
                                  (jsonb_array_length(l.properties::jsonb -> 'palgaastmed') - 1) ->>
                                  'alates')::date, current_date) as alates,
                        $2::INTEGER                              AS userId,
                        muud,
                        (properties::JSONB ->> 'valid')::DATE    AS valid
                    FROM
                        libs.library l
                    WHERE
                          l.library = 'PALGAASTMED'
                      AND l.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalgaastmed'
    },
    getLog: {
        command: `SELECT
                      ROW_NUMBER() OVER ()              AS id,
                      (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                      coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                               '')::VARCHAR(20)         AS koostatud,
                      coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                               '')::VARCHAR(20)         AS muudatud,
                      coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                               '')::VARCHAR(20)         AS prinditud,
                      coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                               '')::VARCHAR(20)         AS kustutatud

                  FROM
                      (
                          SELECT
                              $2                                                                            AS user_id,
                              jsonb_array_elements(jsonb_agg(jsonb_build_object('updated', propertis ->> 'updated',
                                                                                'user',
                                                                                ltrim(rtrim(u.kasutaja))))) AS ajalugu
                          FROM
                              ou.logs                       l
                                  LEFT OUTER JOIN ou.userid u ON u.id = l.user_id
                          WHERE
                                propertis ->> 'table' = 'library'
                            AND doc_id = $1
                      ) qry
        `,
        type: "sql",
        alias: "getLogs"
    },

};
