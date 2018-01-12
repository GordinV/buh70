module.exports = {
    select: [{
        sql: `select *, $2::integer as userid, 'ASUTUSED' as doc_type_id,
                (properties->>'pank')::text as pank,
                (properties->>'kmkr')::text as kmkr,
                (properties->>'kehtivus')::date as kehtivus                
                from libs.asutus where id = $1`,
        sqlAsNew: `select $1::integer as id , $2::integer as userid, 'ASUTUSED' as doc_type_id,
            null::text as  regkood,
            null::text as nimetus,
            null::text as omvorm,
            null::text as aadress,
            null::text as kontakt,
            null::text as tel,
            null::text as faks,
            null::text as email,
            null::text as muud,
            null::text as tp,
            0::integer as staatus,
            null::text as pank,
            null::text as kmkr,
            null::text as mark`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `select * from com_asutused a 
        where libs.check_asutus(a.id, $1) 
        and (kehtivus is null or kehtivus > date())`, //$1 - rekvId
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'regkood',type: 'C'},
        {name: 'nimetus',type: 'C'},
        {name: 'omvorm',type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_asutus($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_asutus($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Reg.kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "omvorm", name: "Om.vorm", width: "20%"},
            {id: "aadress", name: "Aadress", width: "25%"}
        ],
        sqlString: `select a.*, $2::integer as userId
            from cur_asutused a
            where libs.check_asutus(a.id, $1)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curAsutused'
    },
};