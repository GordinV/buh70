module.exports = {
    select: [{
        sql: `select n.*, $2::integer as userid, 'NOMENCLATURE' as doc_type_id,
                v.valuuta, v.kuurs,
                (n.properties::jsonb ->>'vat')::text as vat,
                (n.properties::jsonb ->>'konto')::text as konto,
                (n.properties::jsonb ->>'projekt')::text as projekt,
                (n.properties::jsonb ->>'tunnus')::text as tunnus,
                (n.properties::jsonb ->>'tegev')::text as tegev,
                (n.properties::jsonb ->>'allikas')::text as allikas,
                (n.properties::jsonb ->>'rahavoog')::text as rahavoog,
                (n.properties::jsonb ->>'artikkel')::text as artikkel                
                from libs.nomenklatuur n 
                left outer join docs.dokvaluuta1 v on v.dokliik = 17 and v.dokid = n.id
                where n.id = $1`,
        sqlAsNew: `select  $1::integer as id , $2::integer as userid, 'NOMENCLATURE' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            null::text as dok,
            null::text as uhik,
            0::numeric as hind,
            0::numeric as ulehind,
            1::numeric as kogus,
            null::text as formula,
            0::integer as status,
            null::text as muud,
            null::text as properties,
            'EUR' as valuuta, 1 as kuurs,
            '20'::text as vat,
            null::text as konto,
            null::text as projekt,
            null::text as tunnus,
            null::text as tegev,
            null::text as allikas,
            null::text as rahavoog,
            null::text as artikkel`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `select * from com_nomenclature 
            where (rekvid = $1 or rekvid is null)
            order by kood`,
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood',type: 'C'},
        {name: 'nimetus',type: 'C'},
        {name: 'dok',type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_nomenclature($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_nomenclature($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "dok", name: "Dokument", width: "30%"}
        ],
        sqlString: `select id, coalesce(kood,'') as kood, coalesce(nimetus,'') as nimetus,  $2::integer as userId, dok
            from libs.nomenklatuur n
            where (n.rekvId = $1 or n.rekvid is null) and n.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curNomenklatuur'
    },

};
