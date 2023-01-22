module.exports = {
    selectAsLibs: `SELECT *
                   FROM com_tp l`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.muud,
                     l.status,
                     l.library,
                     l.tun1,
                     l.tun2,
                     l.tun3,
                     l.tun4,
                     l.tun5,
                     $2::INTEGER                             AS userid,
                     'TP'                                    AS doc_type_id,
                     (l.properties::JSONB ->> 'valid')::DATE AS valid
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'TP' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'TP'::text as library,
            null::integer as tun1,
            null::integer as tun2,
            null::integer as tun3,
            null::integer as tun4,
            null::integer as tun5,
            0::integer as status,
            null::date as valid,
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
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_library($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT id,
                           kood,
                           nimetus,
                           $2::INTEGER                           AS userId,
                           (properties::JSONB ->> 'valid')::DATE AS valid
                    FROM libs.library l
                    WHERE l.library = 'TP'
                      AND l.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTPR'
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
