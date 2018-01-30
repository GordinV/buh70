module.exports = {
    selectAsLibs: `select * from com_tp l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.muud, l.status, l.library,
                l.tun1, l.tun2, l.tun3, l.tun4, l.tun5, 
                $2::integer as userid, 'TP' as doc_type_id
                from libs.library l 
                where l.id = $1`,
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
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `select id, kood, nimetus,  $2::integer as userId
            from libs.library l
            where l.library = 'TP'
            and l.status <> 3
            and (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTPR'
    },

};
