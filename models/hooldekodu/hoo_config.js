module.exports = {
    select: [{
        sql: `SELECT $2 :: INTEGER AS userid,
                     id,
                     kpv::DATE,
                     summa::NUMERIC(12, 2),
                     library::VARCHAR(20),
                     muud
              FROM hooldekodu.hoo_config H
              WHERE H.id = $1`,
        sqlAsNew: `SELECT 0 as id,
                      $1::integer as id_,
                      $2 :: INTEGER        AS userid,
                     'LIBNAME' AS library,
                      0::numeric(12,4) as summa,
                      current_date as kpv,
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
        {name: 'summa', type: 'N'}, {name: 'kpv', type: 'D'}
    ],
    saveDoc: `select hooldekodu.sp_salvesta_hoo_config($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM hooldekodu.sp_delete_hoo_config($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [],
        sqlString: `SELECT id,
                           summa,
                           kpv,
                           left(coalesce(muud, ''), 254)::VARCHAR(254) AS muud,
                           library,
                           $2::INTEGER                                 AS userId,
                           $1                                          AS rekv_id
                    FROM hooldekodu.hoo_config
                    WHERE status < 3`, //$1 rekv_id, $2 - userid
        params: '',
        alias: 'curHooConfig'
    },
    /*
        executeCommand: {
            command: `select error_code, result, error_message from palk.gen_taabel1($1, $2::json)`, //$1 - user_id, $2 - params
            type: 'sql',
            alias: 'genTaabel'
        },
    */
};