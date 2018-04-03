module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER            AS userid,
                 'PALK_TAABEL' AS doc_type_id,
                  p.id,
                  p.lepingid,
                  p.kuu,
                  p.aasta,
                  p.kokku,
                  p.too,
                  p.paev,
                  p.ohtu,
                  p.oo,
                  p.tahtpaev,
                  p.puhapaev,
                  p.uleajatoo,
                  p.status,
                  p.muud,
                  t.parentid
                FROM palk.palk_taabel1 p
                inner join palk.tooleping t on t.id = p.lepingid
                WHERE p.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                     'PALK_TAABEL' AS doc_type_id,
                      0 as id,
                      0::integer as lepingid,
                      month(current_date)::integer as kuu,
                      year(current_date)::integer as aasta,
                      0::numeric(12,4) as kokku,
                      0::numeric(12,4) as too,
                      0::numeric(12,4) as paev,
                      0::numeric(12,4) as ohtu,
                      0::numeric(12,4) as oo,
                      0::numeric(12,4) as tahtpaev,
                      0::numeric(12,4) as puhapaev,
                      0::numeric(12,4) as uleajatoo,
                      1 as status,
                      0::integer          as parentid,
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
        {name: 'lepingid', type: 'I'},
        {name: 'kuu', type: 'I'},
        {name: 'aasta', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_palk_taabel($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_palk_taabel($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "1%", show: false},
            {id: "isik", name: "Isik", width: "25%"},
            {id: "osakond", name: "Osakond", width: "15%"},
            {id: "amet", name: "Amet", width: "15%"},
            {id: "kokku", name: "Kokku", width: "15%"},
            {id: "paev", name: "Tööpäevas", width: "15%"},
            {id: "puhkus", name: "Pühapäevas", width: "10%"},
            {id: "kuu", name: "Kuu", width: "15%"},
            {id: "aasta", name: "Aasta", width: "15%"},
        ],
        sqlString: `select t.*, $2::integer as userId
            from palk.cur_palk_taabel t
            where (t.rekvid = $1 or rekvid is null)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTaabel1'
    },
/*
    executeCommand: {
        command: `select error_code, result, error_message from palk.sp_calc_puhkuse_paevad($1, $2)`, //$1 - user_id, $2 - params (lepingid, tyyp)
        type: 'sql',
        alias: 'calcPuhkusePaevad'
    },
*/
};