module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER            AS userid,
                 'PALK_TMPL' AS doc_type_id,
                  pk.id,
                  pk.parentid,
                  pk.libid,
                  pk.summa,
                  pk.percent_,
                  pk.tulumaks,
                  pk.tulumaar,
                  pk.status,
                  pk.muud,
                  pk.tunnus   AS tunnus
                FROM libs.library l
                  INNER JOIN palk.palk_tmpl pk ON pk.libId = l.id
                WHERE pk.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                      'PALK_TMPL'        AS doc_type_id,
                      0 :: INTEGER        AS parentid,
                      0 :: INTEGER        AS libid,
                      0 :: NUMERIC(14, 4) AS summa,
                      0 :: INTEGER        AS percent_,
                      0 :: INTEGER        AS tulumaks,
                      0 :: NUMERIC        AS tulumaar,
                      1::integer        AS status,
                      NULL :: TEXT        AS muud,
                      0 :: INTEGER        AS alimentid,
                      NULL :: VARCHAR(20) AS tunnus,
                      0 :: INTEGER        AS minsots`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'libid', type: 'I'},
        {name: 'parentid', type: 'I'},
        {name: 'summa', type: 'N'}
    ],
    saveDoc: `select palk.sp_salvesta_palk_tmpl($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_palk_tmpl($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "summa", name: "Summa", width: "35%"},
            {id: "liik_", name: "Liik", width: "5%"},
            {id: "amet", name: "Amet", width: "25%"}
        ],
        sqlString: `select a.*, $2::integer as userId
            from palk.cur_palk_tmpl a
            where (rekvid = $1 or rekvid is null)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkTmpl'
    },
    executeCommand: {
        command: `select error_code, result, error_message from palk.palk_kaart_from_tmpl($1, $2)`,
        type:'sql',
        alias:'importTmpl'
    },

};