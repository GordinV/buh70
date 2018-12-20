module.exports = {
    select: [{
        sql: `SELECT
                  $2 :: INTEGER            AS userid,
                 'PALK_KAART' AS doc_type_id,
                  pk.id,
                  pk.parentid,
                  pk.lepingid,
                  pk.libid,
                  pk.summa,
                  pk.percent_,
                  pk.tulumaks,
                  pk.tulumaar,
                  pk.status,
                  pk.muud,
                  pk.alimentid,
                  pk.tunnus                                             AS tunnus,
                  pk.minsots,
                  osakond.kood                                          AS osakond,
                  osakond.id                                            AS osakondId,
                  amet.kood                                             AS amet,
                  l.kood,
                  l.nimetus,
                  (l.properties :: JSONB ->> 'liik') :: INTEGER         AS liik,
                  (l.properties :: JSONB ->> 'tund') :: INTEGER         AS tund,
                  (l.properties :: JSONB ->> 'maks') :: INTEGER         AS maks,
                  (l.properties :: JSONB ->> 'asutusest') :: INTEGER    AS asutusest,
                  (l.properties :: JSONB ->> 'tululiik') :: VARCHAR(20) AS tululiik,
                  'EUR' :: VARCHAR                                      AS valuuta,
                  1 :: NUMERIC                                          AS kuurs
                FROM libs.library l
                  INNER JOIN palk.palk_kaart pk ON pk.libId = l.id
                  INNER JOIN palk.tooleping t ON pk.lepingId = t.id
                  INNER JOIN libs.library amet ON amet.id = t.ametid
                  INNER JOIN libs.library osakond ON osakond.id = t.osakondid
                WHERE pk.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                      'PALK_KAART'        AS doc_type_id,
                      0 :: INTEGER        AS parentid,
                      0 :: INTEGER        AS lepingid,
                      0 :: INTEGER        AS libid,
                      0 :: NUMERIC(14, 4) AS summa,
                      0 :: INTEGER        AS percent_,
                      0 :: INTEGER        AS tulumaks,
                      0 :: NUMERIC        AS tulumaar,
                      1 :: INTEGER        AS status,
                      NULL :: TEXT        AS muud,
                      0 :: INTEGER        AS alimentid,
                      NULL :: VARCHAR(20) AS tunnus,
                      0 :: INTEGER        AS minsots,
                      'EUR' :: VARCHAR    AS valuuta,
                      1 :: NUMERIC        AS kuurs`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `select * from palk.com_palk_kaart a 
        where (rekvid = $1 or rekvid is null)`, //$1 - rekvId
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'libid', type: 'I'},
        {name: 'lepingid', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_palk_kaart($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from palk.sp_delete_palk_kaart($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "summa", name: "Summa", width: "35%"},
            {id: "liik_", name: "Liik", width: "5%"},
            {id: "osakond", name: "Osakond", width: "20%"},
            {id: "amet", name: "Amet", width: "25%"}
        ],
        sqlString: `select a.*, $2::integer as userId
            from palk.cur_palk_kaart a
            where (rekvid = $1 or rekvid is null)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkKaart'
    },
    executeCommand: {
        command: `select error_code, result, error_message from palk.change_kaart_status($1::integer, $2::integer)`, //$1 - palk_kaart.id, $2 - user_id
        type:'sql',
        alias:'changeStatus'
    },
};