module.exports = {
    select: [{
        sql: `select n.*, $2::integer as userid, 
                'VARA' as doc_type_id,
                'EUR'::varchar(20) as valuuta, 1 as kuurs,
                n.uhik,
                n.hind,
                n.ulehind,
                n.dok,
                n.kogus,
                (n.properties::jsonb ->>'gruppid')::integer as gruppid,
                (n.properties::jsonb ->>'vat')::text as vat,
                (n.properties::jsonb ->>'konto')::text as konto,
                (n.properties::jsonb ->>'projekt')::text as projekt,
                (n.properties::jsonb ->>'tunnus')::text as tunnus,
                (n.properties::jsonb ->>'tegev')::text as tegev,
                (n.properties::jsonb ->>'allikas')::text as allikas,
                (n.properties::jsonb ->>'artikkel')::text as artikkel,                
                (n.properties::jsonb ->>'kalor')::numeric as kalor,               
                (n.properties::jsonb ->>'valid')::date as valid,                
                (n.properties::jsonb ->>'sahharid')::numeric as sahharid,                
                (n.properties::jsonb ->>'rasv')::numeric as rasv,                
                (n.properties::jsonb ->>'vailkaine')::numeric as vailkaine              
                from libs.nomenklatuur n 
                where n.id = $1`,
        sqlAsNew: `select  $1::integer as id , $2::integer as userid, 'VARA' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'VARA'::text as dok,
            null::text as uhik,
            0::numeric as hind,
            0::numeric as ulehind,
            1::numeric as kogus,
            null::text as formula,
            0::integer as status,
            null::text as muud,
            'EUR' as valuuta, 1 as kuurs,
            '20'::text as vat,
            null::integer as gruppid,
            null::text as konto,
            null::text as projekt,
            null::text as tunnus,
            null::text as tegev,
            null::text as allikas,
            null::text as artikkel,
            0::numeric as kalor,
            null::date as valid,
            0::numeric as sahharid,
            0::numeric as rasv,
            0::numeric as vailkaine`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `select * from com_varad 
            where (rekvid = $1 or rekvid is null)
            and status <> 3
            order by kood`,
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'kood',type: 'C'},
        {name: 'nimetus',type: 'C'},
        {name: 'gruppid',type: 'I'},
        {name: 'dok',type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_nomenclature($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_nomenclature($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "grupp", name: "Grupp", width: "30%"}
        ],
        sqlString: `select n.id, coalesce(n.kood,'') as kood, 
            coalesce(n.nimetus,'') as nimetus,  $2::integer as userId, 
            l.nimetus as grupp,
            n.hind,
            n.uhik
            from libs.nomenklatuur n
            inner join libs.library l on l.id = (n.properties::jsonb ->>'gruppid')::integer 
            where (n.rekvId = $1 or n.rekvid is null) and n.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curVara'
    },

};
