module.exports = {
    select: [{
        sql: `select coalesce(l.rekvid,0) as rekvid, 
                case when l.tun5 = 1 then 'SD' when l.tun5 = 2 then 'SK' when l.tun5 = 3 then 'D' when l.tun5 = 4 then 'K' else null end::varchar(20) as konto_tyyp, 
                l.id, trim(l.kood)::varchar(20) as kood, trim(l.nimetus)::varchar(254) as nimetus, 
                l.library, l.tun1, l.tun2, l.tun3, l.tun4, l.muud, $2::integer as userid, 
                'KONTOD' as doc_type_id, l.tun5 as tyyp, 
                l.status,
                (l.properties::jsonb ->> 'valid')::date as valid
                from libs.library l 
                where id = $1`,
        sqlAsNew: `select null::integer as rekvId, 
            'SD'::varchar(20) as konto_tyyp, 
            $1::integer as id , $2::integer as userid, 'KONTOD' as doc_type_id,
            null::varchar(20) as  kood,
            null::varchar(20) as nimetus,
            'KONTOD'::text as library,
            null::integer as tun1,
            null::integer as tun2,
            null::integer as tun3,
            null::integer as tun4,
            2 as tyyp,
            0 as status,
            null::text as muud,
            null::date as valid`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT s.*,  
                left(a.nimetus,120)::varchar AS nimetus 
                FROM  libs.subkonto s 
                INNER JOIN   libs.asutus a on a.id = s.asutusid 
                inner join ou.userid u on u.id = $2
                WHERE  s.kontoid = $1 
                and s.rekvid = u.rekvId`,
            query: null,
            multiple: true,
            alias: 'subkonto',
            data: []
        }
    ],
    selectAsLibs: `select *, $1 as rekv_id from com_kontoplaan l order by kood`, //where ($1::integer is null or l.rekvId = $1 or l.rekvid is null)
    returnData: {
        row: {}
    },
    requiredFields: [
        {
            name: 'kood',
            type: 'C'
        },
        {
            name: 'nimetus',
            type: 'C'
        }
    ],
    saveDoc: `select libs.sp_salvesta_konto($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_konto($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "konto_tyyp", name: "Konto tüüp", width: "20%"}
        ],
        sqlString: `select id, trim(kood)::varchar(20) as kood, trim(nimetus)::varchar(254) as nimetus,  $2::integer as userId,
            case when l.tun5 = 1 then 'SD' when l.tun5 = 2 then 'SK' when l.tun5 = 3 then 'D' when l.tun5 = 4 then 'K' else null end::varchar(20) as konto_tyyp
            from libs.library l
            where library = 'KONTOD' 
            and l.status <> 3`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curKontod'
    },

};
