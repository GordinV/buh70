module.exports = {
    selectAsLibs: `select * from com_valuuta l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.muud, l.status, l.library,
                $2::integer as userid, 'VALUUTA' as doc_type_id,
                l.tun1, l.tun4, l.tun5
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'VALUUTA' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'VALUUTA'::text as library,
            0::integer as status,
            0::integer as tun1,
            null::integer as tun4,
            null::integer as tun5,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },{
        sql: `select $2::integer as userid, v.* from libs.valuuta v where v.parentId = $1`,
        query: null,
        multiple: true,
        alias: 'details',
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
    saveDoc: `select libs.sp_salvesta_valuuta($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `select id, kood, nimetus,  $2::integer as userId
            from libs.library l
            where l.library = 'VALUUTA'
            and l.status <> 3
            and (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curValuuta'
    },

};
