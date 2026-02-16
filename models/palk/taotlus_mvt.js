module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER            AS userid,
                 'TAOTLUS_MVT' AS doc_type_id,
                  p.id,
                  p.lepingid,
                  p.kpv,
                  p.alg_kpv,
                  p.lopp_kpv,
                  p.summa,
                  p.status,
                  p.muud,
                  t.parentid
                FROM palk.taotlus_mvt p
                inner join palk.tooleping t on t.id = p.lepingid
                WHERE p.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                     'TAOTLUS_MVT' AS doc_type_id,
                      0 as id,
                      0::integer as lepingid,
                      now()::date as kpv,
                      make_date(date_part('year', $3::date)::INT, date_part('month', $3::date)::INT, 1)::date as alg_kpv,
                      make_date(date_part('year', $3::date)::INT, 12, 31)::date as lopp_kpv,
                      palk.get_soodustus_mvt(null::text, $3::date)::numeric(12,2) as summa,
                      1 as status,
                      0::integer          as parentid,
                      null::text as muud`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },{
        sql: `select 
                $1 as doc_id,
                p.* 
                from palk.palk_config p 
                where status <> 'deleted' 
                and rekvid in (select rekvid from ou.userid where id = $2)`,
        query: null,
        multiple: false,
        alias: 'palk_config',
        data: []
    },
        {
            sql:`SELECT t.*, 
                $2 as user_id 
                from palk.isiku_mvt_taotlused t
                WHERE t.isikid = $1`, //$1 - isik_id, $2 - user_id
            query: null,
            multiple: false,
            alias: 'v_isiku_mvt_taotlused',
            data: []
        },
        {
            sql:`SELECT palk.kas_soodustus_mvt($1::TEXT, $2::DATE)::INTEGER as tulemus ,
                palk.get_soodustus_mvt($1::TEXT, $2::DATE)::NUMERIC as mvt`, //$1 - isikukood, $2 - seisuga
            query: null,
            multiple: false,
            alias: 'v_pensionari_mvt_kontrol',
            data: []
        },
    ],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'lepingid', type: 'I'},
        {name: 'kpv', type: 'D'},
        {name: 'alg_kpv', type: 'D'},
        {name: 'lopp_kpv', type: 'D'},
        {name: 'summa', type: 'N'}
    ],
    saveDoc: `select palk.sp_salvesta_taotlus_mvt($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_taotlus_mvt($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "kuu", name: "Kuu", width: "25%"},
            {id: "aasta", name: "Aasta", width: "15%"},
            {id: "taotluse_summa", name: "Taotluse summa", width: "15%"},
            {id: "mvt_summa", name: "MVT summa", width: "15%"},
            {id: "amet", name: "Amet", width: "15%"}
        ],
        sqlString: `select *, $2::integer as userId
            from palk.get_taotlus_mvt_data($1, (select rekvid from ou.userid where id = $2)::integer)`, //$1 asutus_id, $2 - userid
        params: '',
        alias: 'curTaotlus_mvt'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (qry.ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((qry.ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((qry.ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((qry.ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((qry.ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((qry.ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((qry.ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements('[]'::jsonb || d.ajalugu) AS ajalugu, d.id
                           FROM palk.taotlus_mvt d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry where (qry.ajalugu ->> 'user') is not null`,
        type: "sql",
        alias: "getLogs"
    },

/*
    executeCommand: {
        command: `select error_code, result, error_message from palk.gen_taabel1($1, $2::json)`, //$1 - user_id, $2 - params
        type: 'sql',
        alias: 'genTaabel'
    },
*/
};