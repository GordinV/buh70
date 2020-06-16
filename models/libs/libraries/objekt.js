module.exports = {
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.muud, l.status, l.library, 
                $2::integer as userid, 'OBJEKT' as doc_type_id,
                (l.properties::jsonb->>'parentid')::integer as parentid,
                (l.properties::jsonb->>'asutusid')::integer as asutusid,
                (l.properties::jsonb->>'nait02')::numeric as nait02,
                (l.properties::jsonb->>'nait03')::numeric as nait03,
                (l.properties::jsonb->>'nait04')::numeric as nait04,
                (l.properties::jsonb->>'nait05')::numeric as nait05,
                (l.properties::jsonb->>'nait06')::numeric as nait06,
                (l.properties::jsonb->>'nait07')::numeric as nait07,
                (l.properties::jsonb->>'nait08')::numeric as nait08,
                (l.properties::jsonb->>'nait09')::numeric as nait09,
                (l.properties::jsonb->>'nait10')::numeric as nait10,
                (l.properties::jsonb->>'nait11')::numeric as nait11,
                (l.properties::jsonb->>'nait14')::numeric as nait14,
                (l.properties::jsonb->>'nait15')::numeric as nait15
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'OBJEKT' as doc_type_id,
            ''::varchar(20) as  kood,
            0::integer as rekvid,
            ''::varchar(20) as nimetus,
            'OBJEKT'::text as library,
            0::integer as asutusid,
            0::integer as parentid,            
            0::numeric as nait02,
            0::numeric as nait03,
            0::numeric as nait04,
            0::numeric as nait05,
            0::numeric as nait06,
            0::numeric as nait07,
            0::numeric as nait08,
            0::numeric as nait09,
            0::numeric as nait10,
            0::numeric as nait11,
            0::numeric as nait14,
            0::numeric as nait15,
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
    saveDoc: `select libs.sp_salvesta_objekt($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    selectAsLibs: `select * from com_objekt l 
        where (l.rekvId = $1 or l.rekvid is null) order by kood`,
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "20%"},
            {id: "nimetus", name: "Nimetus", width: "40%"},
            {id: "asutus", name: "Omanik", width: "40%"}
        ],
        sqlString: `select $2::integer as userId,
             o.*
            FROM cur_objekt o 
            WHERE o.rekvid = $1::integer`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curObjekt'
    }

};