module.exports = {
    selectAsLibs: `SELECT *, NULL::DATE AS valid
                   FROM com_ladu_oper l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.status,
                     l.library,
                     tun1        AS tun1,
                     $2::INTEGER AS userid,
                     'LADU_OPER' AS doc_type_id,
                     l.muud
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'LADU_OPER' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'LADU_OPER'::text as library,
            1::integer as tun1,
            0::integer as status,
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
        {name: 'tun1', type: 'I'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_library($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "liik", name: "Liik", width: "25%"}
        ],
        sqlString: `SELECT l.id,
                           l.kood,
                           l.nimetus,
                           (CASE WHEN l.tun1 = 1 THEN '+' ELSE '-' END)::TEXT AS liik,
                           $2::INTEGER                                        AS userId
                    FROM libs.library l
                    WHERE l.library = 'LADU_OPER'
                      AND l.status <> 3
                      AND (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLaduOper'
    },

};
