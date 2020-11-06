module.exports = {
    selectAsLibs: `SELECT *
                   FROM com_osakonnad l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.muud,
                     l.status,
                     l.library,
                     $2::INTEGER                             AS userid,
                     'OSAKOND'                               AS doc_type_id,
                     (l.properties::JSONB ->> 'valid')::DATE AS valid
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'OSAKOND' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'OSAKOND'::text as library,
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
                           $2::INTEGER                             AS userId,
                           (l.properties::JSONB ->> 'valid')::DATE AS valid
                    FROM libs.library l
                    WHERE l.library = 'OSAKOND'
                      AND l.status <> 3
                      AND (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curOsakonnad'
    },

};
