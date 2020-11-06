module.exports = {
    selectAsLibs: `SELECT *
                   FROM com_pv_gruppid l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.status,
                     l.library,
                     l.tun1,
                     l.tun5,
                     $2::INTEGER                                            AS userid,
                     'PVGRUPP'                                              AS doc_type_id,
                     (l.properties::JSONB ->> 'konto') :: VARCHAR(20)       AS konto,
                     (l.properties::JSONB ->> 'kulum_konto') :: VARCHAR(20) AS kulum_konto,
                     (l.properties::JSONB ->> 'valid')::DATE                AS valid,
                     l.muud
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            null::integer as tun1, null::integer as tun2,
            $2::integer as userid, 
            'PVGRUPP' as doc_type_id,
            ''::varchar(20) as  kood,
            ''::varchar(254) as nimetus,
            'PVGRUPP'::text as library,
            0::integer as status,
           ''::varchar(20) as konto,
            ''::varchar(20) as kulum_konto,
            null::date as valid,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT Library.id
                  FROM libs.library Library
                  WHERE Library.rekvid = $1
                    AND Library.library = 'PVGRUPP'
                    AND library.status <> 3
                    AND RTRIM(LTRIM(Library.kood)) = $2`,//$1 rekvid, $2 kood
            query: null,
            multiple: true,
            alias: 'validate_pvgrupp',
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
    saveDoc: `select libs.sp_salvesta_pv_grupp($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "konto", name: "Konto", width: "25%"}
        ],
        sqlString: `SELECT l.id,
                           l.kood,
                           l.nimetus,
                           coalesce((l.properties::JSONB ->> 'konto'), '')::VARCHAR(20)       AS konto,
                           coalesce((l.properties::JSONB ->> 'kulum_konto'), '')::VARCHAR(20) AS kulum_konto,
                           (l.properties::JSONB ->> 'valid')::DATE                            AS valid,
                           $2::INTEGER                                                        AS userId,
                           l.muud
                    FROM libs.library l
                    WHERE l.library = 'PVGRUPP'
                      AND l.status <> 3
                      AND (l.rekvId = $1 OR l.rekvid IS NULL)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPvgruppid'
    },

};
