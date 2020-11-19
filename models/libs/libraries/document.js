module.exports = {
    selectAsLibs: `SELECT id,
                          trim(kood)                           AS kood,
                          trim(nimetus)                        AS name,
                          $1                                   AS rekvid,
                          (properties::JSON ->> 'valid')::DATE AS valid
                   FROM libs.library
                   WHERE library = 'DOK'
                     AND kood IN ('ARV', 'AVANS', 'DEKL', 'PV_OPER', 'SARV', 'SMK', 'SORDER', 'VARV', 'VMK', 'VORDER')
                   ORDER BY kood`,
    select: [{
        sql: `SELECT l.*,
                     $2::INTEGER                              AS userid,
                     'DOCUMENT'                               AS doc_type_id,
                     (l.properties::JSONB ->> 'type')::TEXT   AS type,
                     (l.properties::JSONB ->> 'module')::TEXT AS module
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , $2::integer as userid, 'DOCUMENT' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'DOK'::text as library,
            null::text as muud,
            '{"type":"library", "module":["Libraries"]}' as properties,
            null::text as type,
            null::text as module`,
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
        sqlString: `SELECT id, kood, nimetus, $2::INTEGER AS userId
                    FROM libs.library l
                    WHERE l.library = 'DOK'
                      AND (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curDok'
    },


};
