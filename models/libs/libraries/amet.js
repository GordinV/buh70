module.exports = {
    selectAsLibs: `select * from com_ametid l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.muud, l.status, l.library,
                $2::integer as userid, 'AMET' as doc_type_id,
                (l.properties:: JSONB ->> 'osakondid') :: INTEGER AS osakondId,
                (l.properties:: JSONB ->> 'kogus') :: numeric(18,2) AS kogus,
                (l.properties:: JSONB ->> 'palgamaar') ::integer AS palgamaar,
                (l.properties:: JSONB ->> 'tunnusid') ::integer AS tunnusId
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            $2::integer as userid, 
            'AMET' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'AMET'::text as library,
            0::integer as status,
            null::integer as osakondId,
            null::numeric(18,2) as kogus,
            null::integer as palgamaar,
            null::integer as tunnusId,
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
        {name: 'osakondid', type: 'C'},
        {name: 'library', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_amet($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "osakond", name: "Osakond", width: "30%"},
            {id: "amet", name: "Amet", width: "30%"},
            {id: "kogus", name: "Kogus", width: "20%"},
            {id: "palgamaar", name: "Palgamaar", width: "20%"},
        ],
        sqlString: `select * from cur_ametid a
            where (a.rekvId = $1 or a.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAmetid'
    },

};
