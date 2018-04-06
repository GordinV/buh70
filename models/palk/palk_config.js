module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER            AS userid,
                 'PALK_CONFIG' AS doc_type_id,
                  p.id,
                  p.rekvid,
                  coalesce(p.minpalk,430)::numeric(14,2) as minpalk,
                  coalesce(p.tulubaas,500)::numeric(14,2) as tulubaas,
                  p.round::numeric(14,2) as round,
                  p.jaak::numeric(14,2) as jaak,
                  p.genlausend,
                  p.suurasu,
                  coalesce(p.tm,20) as tm,
                  coalesce(p.pm,2) as pm,
                  coalesce(p.tka,0.80) as tka,
                  coalesce(p.tki,1.6) as tki,
                  coalesce(p.sm,33) as sm,
                  p.muud1,
                  p.muud2,
                  p.status
                FROM palk.palk_config p
                WHERE p.rekvid = $1 and p.status <> 'deleted'`,
        sqlAsNew: `SELECT
                      0 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                     'PALK_CONFIG' AS doc_type_id,
                      $1::integer as rekvid,
                      430::numeric(12,4) as minpalk,
                      500::numeric(12,4) as tulubaas,
                      0::numeric(12,4) as round,
                      1 as jaak,
                      1 as genlausend,
                      0 as suurasu,
                      20::numeric as tm,
                      2::numeric as pm,
                      0.80::numeric as tka,
                      1.60::numeric as tki,
                      33::numeric as sm,
                      0::numeric as muud1,
                      0::numeric as muud2,
                      1 as status,
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
        {name: 'rekvid', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_palk_config($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_palk_config($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [],
        sqlString: `select *, $2::integer as userId
            from palk.palk_config where rekvid = $1`, //$1 rekv_id, $2 - userid
        params: '',
        alias: 'curPalkConfig'
    },
    /*
        executeCommand: {
            command: `select error_code, result, error_message from palk.gen_taabel1($1, $2::json)`, //$1 - user_id, $2 - params
            type: 'sql',
            alias: 'genTaabel'
        },
    */
};