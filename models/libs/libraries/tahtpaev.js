module.exports = {
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.status, l.library, 
                $2::integer as userid, 'TAHTPAEV' as doc_type_id,
                (l.properties::JSONB ->> 'paev') :: integer as paev,
                (l.properties::JSONB ->> 'kuu') :: integer as kuu,
                (l.properties::JSONB ->> 'aasta') :: integer as aasta,
                (l.properties::JSONB ->> 'luhipaev') :: integer as luhipaev,
                l.muud                 
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'TAHTPAEV' as doc_type_id,
            ''::text as  kood,
            0::integer as rekvid,
            ''::text as nimetus,
            'TAHTPAEV'::text as library,
            1::integer as paev,
            1::integer as kuu,
            year(current_date)::integer as aasta,
            0::integer as luhipaev,
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
        {name: 'nimetus', type: 'C'},
        {name: 'paev', type: 'I'},
        {name: 'kuu', type: 'I'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_tahtpaev($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "paev", name: "Päev", width: "25%"},
            {id: "kuu", name: "Kuu", width: "25%"},
            {id: "aasta", name: "Aasta", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `select 
                $2::integer as userId, *
                from cur_tahtpaevad l       
                where (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curHoliday'
    },

};
