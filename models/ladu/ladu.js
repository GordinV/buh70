module.exports = {
    selectAsLibs: `select * from com_ladu l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood::varchar(20), l.nimetus::varchar(254), l.status, l.library, 
                $2::integer as userid, 'LADU' as doc_type_id,
                (l.properties::JSONB ->> 'konto') :: varchar(20) as konto,
                l.muud                 
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'LADU' as doc_type_id,
            ''::varchar(20) as  kood,
            0::integer as rekvid,
            ''::varchar(254) as nimetus,
            'LADU'::text as library,
            0::integer as status,
            ''::varchar(20) as konto,
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
    saveDoc: `select libs.sp_salvesta_ladu($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "konto", name: "Konto", width: "25%"}
        ],
        sqlString: `select l.id, l.kood, l.nimetus, l.muud, (l.properties::json->>'konto')::varchar(20) as konto,
            $2::integer as userId
            from libs.library l
            where l.library = 'LADU'
            and l.status <> 3
            and (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curLadu'
    },

};
