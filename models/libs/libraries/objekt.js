module.exports = {
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.muud,
                     l.status,
                     l.library,
                     $2::INTEGER                                   AS userid,
                     'OBJEKT'                                      AS doc_type_id,
                     (l.properties::JSONB ->> 'parentid')::INTEGER AS parentid,
                     (l.properties::JSONB ->> 'asutusid')::INTEGER AS asutusid,
                     (l.properties::JSONB ->> 'nait02')::NUMERIC   AS nait02,
                     (l.properties::JSONB ->> 'nait03')::NUMERIC   AS nait03,
                     (l.properties::JSONB ->> 'nait04')::NUMERIC   AS nait04,
                     (l.properties::JSONB ->> 'nait05')::NUMERIC   AS nait05,
                     (l.properties::JSONB ->> 'nait06')::NUMERIC   AS nait06,
                     (l.properties::JSONB ->> 'nait07')::NUMERIC   AS nait07,
                     (l.properties::JSONB ->> 'nait08')::NUMERIC   AS nait08,
                     (l.properties::JSONB ->> 'nait09')::NUMERIC   AS nait09,
                     (l.properties::JSONB ->> 'nait10')::NUMERIC   AS nait10,
                     (l.properties::JSONB ->> 'nait11')::NUMERIC   AS nait11,
                     (l.properties::JSONB ->> 'nait14')::NUMERIC   AS nait14,
                     (l.properties::JSONB ->> 'nait15')::NUMERIC   AS nait15,
                     (l.properties::JSONB ->> 'valid')::DATE       AS valid
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'OBJEKT' as doc_type_id,
            ''::varchar(20) as  kood,
            0::integer as rekvid,
            ''::varchar(20) as nimetus,
            'OBJEKT'::text as library,
            0::integer as asutusid,
            0::integer as parentid,            
            0::numeric as nait02,
            0::numeric as nait03,
            0::numeric as nait04,
            0::numeric as nait05,
            0::numeric as nait06,
            0::numeric as nait07,
            0::numeric as nait08,
            0::numeric as nait09,
            0::numeric as nait10,
            0::numeric as nait11,
            0::numeric as nait14,
            0::numeric as nait15,
            0::integer as status,
            null::date as valid,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT $1 AS rekv_id, *
                  FROM jsonb_to_recordset(
                               get_objekt_kasutus($2::INTEGER, $3::DATE)
                           ) AS x (error_message TEXT, error_code INTEGER)
                  WHERE error_message IS NOT NULL
            `, //$1 rekvid, $2 v_nom.kood
            query: null,
            multiple: true,
            alias: 'validate_lib_usage',
            data: []
        }

    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_objekt($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    selectAsLibs: `SELECT *
                   FROM com_objekt l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)
                   ORDER BY kood`,
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "20%"},
            {id: "nimetus", name: "Nimetus", width: "40%"},
            {id: "asutus", name: "Omanik", width: "40%"}
        ],
        sqlString: `SELECT $2::INTEGER AS userId,
                           o.*
                    FROM cur_objekt o
                    WHERE o.rekvid = $1::INTEGER`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curObjekt'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()              AS id,
                         (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS prinditud,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MI.SS'),
                                  '')::VARCHAR(20)         AS kustutatud

                  FROM (SELECT $2                                                      AS user_id,
                               jsonb_array_elements(jsonb_agg(jsonb_build_object('updated', propertis ->> 'updated', 'user',
                                                            ltrim(rtrim(u.kasutaja))))) AS ajalugu
                        FROM ou.logs l
                                 LEFT OUTER JOIN ou.userid u ON u.id = l.user_id
                        WHERE propertis ->> 'table' = 'library'
                          AND doc_id = $1) qry
        `,
        type: "sql",
        alias: "getLogs"
    },

};