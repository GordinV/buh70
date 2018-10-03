module.exports = {
    selectAsLibs: `select * from palk.com_palk_lib l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select l.id, l.rekvid, l.kood, l.nimetus, l.status, l.library, l.tun1, l.tun5,
                $2::integer as userid, 'PALK_LIB' as doc_type_id,
                (l.properties::JSONB ->> 'liik') :: INTEGER as liik,
                (l.properties::JSONB ->> 'tund') :: INTEGER as tund,
                (l.properties::JSONB ->> 'maks') :: INTEGER as maks,
                (l.properties::JSONB ->> 'asutusest') :: INTEGER as asutusest,
                (l.properties::JSONB ->> 'palgafond') :: INTEGER as palgafond,
                (l.properties::JSONB ->> 'sots') :: INTEGER as sots,
                (l.properties::JSONB ->> 'round') :: numeric(12,4) as round,
                (l.properties::JSONB ->> 'konto') :: varchar(20) as konto,
                (l.properties::JSONB ->> 'korrkonto') :: varchar(20) as korrkonto,
                (l.properties::JSONB ->> 'tunnusid') :: integer as tunnusId,
                (l.properties::JSONB ->> 'elatis') :: integer as elatis,
                (l.properties::JSONB ->> 'uuritus') :: varchar(20) as uuritus,
                (l.properties::JSONB ->> 'proj') :: varchar(20) as proj,
                (l.properties::JSONB ->> 'tegev') :: varchar(20) as tegev,
                (l.properties::JSONB ->> 'allikas') :: varchar(20) as allikas,
                (l.properties::JSONB ->> 'artikkel') :: varchar(20) as artikkel,
                (l.properties::JSONB ->> 'tululiik') :: varchar(20) as tululiik,
                l.muud                 
                from libs.library l 
                where l.id = $1`,
        sqlAsNew: `select  $1::integer as id , 
            null::integer as tun1, null::integer as tun5,
            $2::integer as userid, 
            'PALK_LIB' as doc_type_id,
            null::text as  kood,
            null::integer as rekvid,
            null::text as nimetus,
            'PALK'::text as library,
            0::integer as status,
            null::integer as liik,
            null::integer as tund,
            null::integer as maks,
            null::integer as asutusest,
            null::integer as palgafond,
            null::integer as sots,
            null::numeric(12,4) as round,
            NULL::varchar(20) as konto,
            NULL::varchar(20) as korrkonto,
            null::integer as tunnusId,
            null::integer as elatis,
            null::varchar(20) as uuritus,
            null::varchar(20) as proj,
            null::varchar(20) as tegev,
            null::varchar(20) as allikas,
            null::varchar(20) as artikkel,
            null::varchar(20) as tululiik,
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
    saveDoc: `select libs.sp_salvesta_palk_lib($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "tululiik", name: "Maksukood", width: "25%"}
        ],
        sqlString: `select l.id, l.kood, l.nimetus, l.tun5 as kehtiv,
            coalesce((l.properties::JSONB ->> 'tululiik'),'')::varchar(20) as tululiik,  
            coalesce((l.properties::JSONB ->> 'liik')::integer,1) as liik,
            $2::integer as userId,
            l.tun5 as is_arhiiv
            from libs.library l
            where l.library = 'PALK'
            and l.status <> 3
            and (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalklib'
    },

};
