module.exports = {
    select: [{
        sql: `SELECT $2 :: INTEGER                                         AS userid,
                     'PALK_KAART'                                          AS doc_type_id,
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
                     pk.tunnus::VARCHAR(20)                                AS tunnus,
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
                      1 :: INTEGER        AS percent_,
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
    selectAsLibs: `SELECT *
                   FROM palk.com_palk_kaart a
                   WHERE (rekvid = $1 OR rekvid IS NULL)`, //$1 - rekvId
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'libid', type: 'I'},
        {name: 'lepingid', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_palk_kaart($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM palk.sp_delete_palk_kaart($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
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
        sqlString: `SELECT a.*, $2::INTEGER AS userId
                    FROM palk.cur_palk_kaart a
                    WHERE (rekvid = $1 OR rekvid IS NULL)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curPalkKaart'
    },
    executeCommand: {
        command: `SELECT error_code, result, error_message
                  FROM palk.change_kaart_status($1::INTEGER, $2::INTEGER)`, //$1 - palk_kaart.id, $2 - user_id
        type: 'sql',
        alias: 'changeStatus'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                                                                        AS id,
                         (qry.ajalugu ->> 'user')::VARCHAR(20)                                                           AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS prinditud,
                         coalesce(to_char((ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'), '')::VARCHAR(20) AS
                                                                                                                        email,
                         coalesce(to_char((ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS earve,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)                                                                   AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements('[]'::jsonb || d.ajalugu) AS ajalugu, d.id
                           FROM palk.palk_kaart d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (qry.ajalugu ->> 'user') IS NOT NULL
        `,
        type: "sql",
        alias: "getLogs"
    },

};