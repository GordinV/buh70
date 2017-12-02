module.exports = {
    select: [{
        sql: `select *, $2::integer as userid, 'ASUTUSED' as doc_type_id from libs.asutus where id = $1`,
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
            null::text as mark`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `select id, trim(nimetus) as name from libs.asutus`,
    returnData: {
        row: {}
    },
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
        sqlString: `select id, regkood, nimetus, omvorm, aadress, $2::integer as userId
            from libs.asutus a
            where (a.rekvId = $1 or a.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: ''
    },
}