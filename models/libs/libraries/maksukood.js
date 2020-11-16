module.exports = {
    selectAsLibs: `SELECT $1::INTEGER AS rekv_id, *
                   FROM palk.com_maksukood l`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.status,
                     l.library,
                     l.muud,
                     l.tun1,
                     l.tun2,
                     l.tun3,
                     l.tun4,
                     l.tun5,
                     (l.properties::JSON ->> 'valid')::DATE AS valid
              FROM libs.library l
              WHERE l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'MAKSUKOOD' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'PALK'::text as library,
            0::integer as status,
            0 as tun1,
            0 as tun2,
            0 as tun3,
            0 as tun4,
            0 as tun5,
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
                               get_tululiik_kasutus($1::INTEGER, $2::DATE)
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
    saveDoc: `select libs.sp_salvesta_library($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT $1::INTEGER                            AS rekv_id,
                           $2::INTEGER                            AS userId,
                           l.id,
                           l.kood,
                           l.nimetus,
                           l.tun1,
                           l.tun2,
                           l.tun3,
                           l.tun4,
                           l.tun5,
                           (l.properties::JSON ->> 'valid')::DATE AS valid
                    FROM libs.library l
                    WHERE l.library = 'MAKSUKOOD'
                      AND l.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curMaksukood'
    },

};
