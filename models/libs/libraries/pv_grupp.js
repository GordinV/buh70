module.exports = {
    selectAsLibs: `select * from com_pv_gruppid l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.status, l.library, l.tun1, l.tun5,
                $2::integer as userid, 'PVGRUPP' as doc_type_id,
                (l.properties::JSONB ->> 'konto') :: varchar(20) as konto,
                (l.properties::JSONB ->> 'kulum_konto') :: varchar(20) as kulum_konto,
                l.muud                 
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            null::integer as tun1, null::integer as tun2,
            $2::integer as userid, 
            'PVGRUPP' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'PVGRUPP'::text as library,
            0::integer as status,
            NULL::varchar(20) as konto,
            NULL::varchar(20) as kulum_konto,
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
    saveDoc: `select libs.sp_salvesta_pv_grupp($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "konto", name: "Konto", width: "25%"}
        ],
        sqlString: `select l.id, l.kood, l.nimetus,
            coalesce((l.properties::JSONB ->> 'konto'),'')::varchar(20) as konto,
            coalesce((l.properties::JSONB ->> 'kulum_konto'),'')::varchar(20) as  kulum_konto, 
            $2::integer as userId,
            l.muud
            from libs.library l
            where l.library = 'PVGRUPP'
            and l.status <> 3
            and (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPvgruppid'
    },

};
