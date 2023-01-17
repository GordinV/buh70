module.exports = {
    select: [{
        sql: `SELECT $2 :: INTEGER                                                                 AS userid,
                     'PALK_CONFIG'                                                                 AS doc_type_id,
                     p.id,
                     p.rekvid,
                     coalesce(p.minpalk, 725)::NUMERIC(14, 2)                                      AS minpalk,
                     coalesce(p.tulubaas, 654)::NUMERIC(14, 2)                                     AS tulubaas,
                     coalesce(p.pensionari_tulubaas, 704)::NUMERIC(12, 2)                          AS pensionari_tulubaas,
                     p.round::NUMERIC(14, 2)                                                       AS round,
                     p.jaak::NUMERIC(14, 2)                                                        AS jaak,
                     p.genlausend,
                     p.suurasu,
                     coalesce(p.tm, 20)                                                            AS tm,
                     coalesce(p.pm, 2)                                                             AS pm,
                     coalesce(p.tka, 0.80)                                                         AS tka,
                     coalesce(p.tki, 1.6)                                                          AS tki,
                     coalesce(p.sm, 33)                                                            AS sm,
                     p.muud1,
                     p.muud2,
                     p.status,
                     (coalesce((p.properties::JSONB ->> 'mmk')::BOOLEAN, FALSE)::BOOLEAN)::INTEGER AS mmk
              FROM palk.palk_config p
              WHERE p.rekvid = $1
                AND p.status <> 'deleted'`,
        sqlAsNew: `SELECT
                      0 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                     'PALK_CONFIG' AS doc_type_id,
                      $1::integer as rekvid,
                      725::numeric(12,4) as minpalk,
                      654::numeric(12,4) as tulubaas,
                      704::numeric(12,4) as pensionari_tulubaas,
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
                      null::text as muud,
                      0::integer as mmk`,
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
    deleteDoc: `SELECT error_code, result, error_message
                FROM palk.sp_delete_palk_config($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [],
        sqlString: `SELECT *, $2::INTEGER AS userId
                    FROM palk.palk_config
                    WHERE rekvid = $1`, //$1 rekv_id, $2 - userid
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