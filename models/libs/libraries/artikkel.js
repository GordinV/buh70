module.exports = {
    selectAsLibs: `select *, $1 as rekv_id from com_artikkel l`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.muud, l.status, l.library, l.tun5,
                $2::integer as userid, 'ARTIKKEL' as doc_type_id
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'ARTIKKEL' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'TULUDEALLIKAD'::text as library,
            1::integer as tun5,
            0::integer as status,
            null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql:`SELECT Library.id 
                    FROM libs.library Library 
                    WHERE Library.library = 'ARTIKKEL'   
                    AND RTRIM(LTRIM(Library.kood)) = $1`, //lib.kood
            query: null,
            multiple:true,
            alias: 'validate_artikkel',
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
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `select id, kood, nimetus,  $2::integer as userId
            from libs.library l
            where l.library = 'TULUDEALLIKAD'
            and l.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTuludeAllikad'
    },

};
