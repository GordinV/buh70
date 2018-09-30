module.exports = {
    selectAsLibs: `select * from (
        select 0 as id, ''::varchar(20) as kood, ''::varchar(254) as nimetus 
        union 
        select id, trim(kood) as kood, trim(nimetus) as name 
        from cur_tunnus 
        where rekvid = $1
        ) qry  
        order by kood`,
    select: [{
        sql: `select 
                l.id, 
                l.kood::varchar(20) as kood, 
                l.nimetus::varchar(254) as nimetus, 
                l.library::varchar(20), l.muud,
                $2::integer as userid, 
                'TUNNUS' as doc_type_id
                from libs.library l 
                where l.library = 'TUNNUS' and l.id = $1`,
        sqlAsNew: `select  
                    $1::integer as id , 
                    $2::integer as userid, 
                    'TUNNUS' as doc_type_id,
                    null::varchar(20) as  kood,
                    null::integer as rekvid,
                    null::varchar(254) as nimetus,
                    'TUNNUS'::varchar(20) as library,
                    null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {},
        details: [],
        gridConfig: []
    },
    requiredFields: [
        {name: 'kood',type: 'C'},
        {name: 'nimetus',type: 'C'},
        {name: 'library',type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_library($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `select l.*, $2::integer as userId
            from cur_tunnus l
            where (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTunnus'
    },

};
