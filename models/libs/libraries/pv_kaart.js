module.exports = {
    selectAsLibs: `SELECT *
                   FROM cur_pohivara l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     l.kood,
                     l.nimetus,
                     l.muud,
                     l.status,
                     l.library,
                     $2 :: INTEGER                                                                              AS userid,
                     'POHIVARA'                                                                                 AS doc_type_id,
                     (l.properties :: JSONB ->> 'gruppid') :: INTEGER                                           AS gruppid,
                     (l.properties :: JSONB ->> 'konto') :: VARCHAR(20)                                         AS konto,
                     coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, now() :: DATE)                     AS soetkpv,
                     (l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 4)                                      AS kulum,
                     (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)                                   AS algkulum,
                     coalesce((l.properties :: JSONB ->> 'kulum_kokku') :: NUMERIC(12, 4),
                              0 :: NUMERIC(12, 4))                                                              AS kulum_kokku,
                     (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2)                                   AS soetmaks,
                     (l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2)                                    AS parhind,
                     (l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2)                                       AS jaak,
                     (l.properties :: JSONB ->> 'vastisikid') :: INTEGER                                        AS vastIsikId,
                     (l.properties :: JSONB ->> 'selg') :: TEXT                                                 AS selg,
                     (l.properties :: JSONB ->> 'rentnik') :: TEXT                                              AS rentnik,
                     (l.properties :: JSONB ->> 'liik') :: TEXT                                                 AS liik,
                     (l.properties :: JSONB ->> 'mahakantud') :: DATE                                           AS mahakantud,
                     'EUR' :: VARCHAR(20)                                                                       AS valuuta,
                     1 :: NUMERIC(12, 2)                                                                        AS kuurs,
                     g.kood                                                                                     AS grupp,
                     a.nimetus                                                                                  AS vastisik,
                     (SELECT sum(summa)
                      FROM docs.pv_oper po
                      WHERE po.pv_kaart_id = l.id
                        AND liik = 2)                                                                           AS arv_kulum
              FROM libs.library l
                     LEFT OUTER JOIN libs.library g ON g.id = (l.properties :: JSONB ->> 'gruppid') :: INTEGER
                     LEFT OUTER JOIN libs.asutus a ON a.id = (l.properties :: JSONB ->> 'vastisikid') :: INTEGER
              WHERE l.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER               AS id,
                      $2 :: INTEGER               AS userid,
                      'POHIVARA'                 AS doc_type_id,
                      NULL :: TEXT               AS kood,
                      NULL :: INTEGER            AS rekvid,
                      NULL :: TEXT               AS nimetus,
                      'POHIVARA' :: TEXT         AS library,
                      0 :: INTEGER               AS status,
                      NULL :: TEXT               AS muud,
                      NULL :: INTEGER            AS gruppid,
                      NULL :: VARCHAR(20)        AS konto,
                      now() :: DATE              AS soetkpv,
                      0 :: NUMERIC(12, 4)        AS kulum,
                      0 :: NUMERIC(12, 2)        AS algkulum,
                      0 :: NUMERIC(12, 2)        AS kulum_kokku,
                      0 :: NUMERIC(12, 2)        AS soetmaks,
                      0 :: NUMERIC(12, 2)        AS parhind,
                      0 :: NUMERIC(12, 2)        AS jaak,
                      NULL :: INTEGER            AS vastisikid,
                      NULL :: TEXT               AS selg,
                      'põhivara' :: VARCHAR(100) AS liik,
                      NULL :: DATE               AS mahakantud,
                      'EUR' :: VARCHAR(20)       AS valuuta,
                      1 :: NUMERIC(12, 2)        AS kuurs,
                      NULL :: TEXT               AS grupp,
                      NULL :: TEXT               AS vastisik,
                      0 :: NUMERIC               AS arv_kulum,
                      NULL :: TEXT               AS rentnik`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }, {
        sql: `SELECT $2 :: INTEGER AS userid, $1 AS pv_id, po.*
              FROM cur_pv_oper po
              WHERE po.pv_kaart_id = $1`, //$1 doc_id, $2 userId
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
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1 :: INTEGER, $2 :: INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "pv_grupp", name: "Grupp", width: "35%"},
        ],
        sqlString: `SELECT *
                    FROM cur_pohivara l
                    WHERE l.rekvId = $1`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPohivara'
    },
    executeCommand: {
        command: `SELECT *
                  FROM sp_execute_task($1 :: INTEGER, $2 :: JSON, $3 :: TEXT)`, //$1- userId, $2 - params, $3 - task
        type: 'sql',
        alias: 'executeTask'
    },

};
