module.exports = {
    selectAsLibs: `select * from cur_pohivara    l
        where  (l.rekvId = $1 or l.rekvid is null)`,
    select: [{
        sql: `select 
                l.id, 
                l.rekvid, l.kood, l.nimetus, l.muud, l.status, l.library, 
                $2::integer as userid, 'POHIVARA' as doc_type_id,
                (l.properties::jsonb ->> 'gruppid')::integer as gruppid,
                (l.properties::jsonb ->> 'konto')::varchar(20) as konto,
                coalesce((l.properties::jsonb ->> 'soetkpv')::date,now()::date) as soetkpv,
                (l.properties::jsonb ->> 'kulum')::numeric(12,4) as kulum,
                (l.properties::jsonb ->> 'algkulum')::numeric(12,4) as algkulum,
                (l.properties::jsonb ->> 'soetmaks')::numeric(12,2) as soetmaks,
                (l.properties::jsonb ->> 'parhind')::numeric(12,2) as parhind,
                (l.properties::jsonb ->> 'jaak')::numeric(12,2) as jaak,
                (l.properties::jsonb ->> 'vastisikid')::integer as vastIsikId,
                (l.properties::jsonb ->> 'selg')::text as selg,
                (l.properties::jsonb ->> 'rentnik')::text as rentnik,
                (l.properties::jsonb ->> 'liik')::text as liik,
                (l.properties::jsonb ->> 'mahakantud')::date as mahakantud,
                'EUR'::varchar(20) as valuuta,
                1::numeric(12,2) as kuurs,
                g.kood                                                                 AS grupp, 
                a.nimetus                                                              AS vastisik,
                (SELECT sum(summa)
                   FROM docs.pv_oper po
                   WHERE po.pv_kaart_id = l.id AND liik = 2)                             AS arv_kulum                            
                from libs.library l 
                  LEFT OUTER JOIN libs.library g ON g.id = (l.properties :: JSONB ->> 'gruppid') :: INTEGER
                  LEFT OUTER JOIN libs.asutus a ON a.id = (l.properties :: JSONB ->> 'vastisikid') :: INTEGER
                where l.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER       AS id,
                      $2 :: INTEGER       AS userid,
                      'POHIVARA'         AS doc_type_id,
                      NULL :: TEXT       AS kood,
                      NULL :: INTEGER    AS rekvid,
                      NULL :: TEXT       AS nimetus,
                      'POHIVARA' :: TEXT AS library,
                      0 :: INTEGER       AS status,
                      NULL :: TEXT       AS muud,
                    NULL:: INTEGER AS gruppid,
                    NULL :: VARCHAR (20) AS konto,
                    now() ::date AS soetkpv,
                    0:: NUMERIC (12, 4) AS kulum,
                    0:: NUMERIC (12, 2) AS algkulum,
                    0:: NUMERIC (12, 2) AS soetmaks,
                    0:: NUMERIC (12, 2) AS parhind,
                    0:: NUMERIC (12, 2) AS jaak,
                    NULL :: INTEGER AS vastisikid,
                    NULL :: TEXT AS selg,
                    'põhivara' :: varchar(100) AS liik,
                    null::date as mahakantud,
                    'EUR'::varchar(20) as valuuta,
                    1::numeric(12,2) as kuurs,
                    NULL::text as grupp,
                    null::text as vastisik,
                    0::numric as arv_kulum,
                    NULL :: TEXT AS rentnik`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }, {
        sql: `select $2 :: INTEGER       AS userid, 
            $1 as pv_id,
            po.*
            from cur_pv_oper po
            where po.pv_kaart_id = $1`, //$1 doc_id, $2 userId
        multiple: true,
        alias: 'details',
        data: []
    }],
    returnData: {
        row: {},
        details: [],
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'library', type: 'C'},
        {name: 'gruppid', type: 'I'}
    ],
    saveDoc: `select libs.sp_salvesta_pv_kaart($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_library($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "pv_grupp", name: "Grupp", width: "35%"},
        ],
        sqlString: `select * 
            from cur_pohivara l
            where (l.rekvId = $1 or l.rekvid is null)`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPohivara'
    },

};
