module.exports = {
    select: [{
        sql: `SELECT $2 :: INTEGER                                      AS userid,
                     t.id,
                     t.parentid,
                     'TOOLEPING'                                        AS doc_type_id,
                     t.osakondid,
                     t.ametid,
                     t.algab,
                     t.lopp,
                     t.palk,
                     t.palgamaar,
                     t.pohikoht,
                     t.ametnik,
                     t.tasuliik,
                     t.muud,
                     t.rekvid,
                     t.resident,
                     t.riik,
                     t.toend,
                     t.koormus,
                     t.toopaev,
                     t.pank,
                     coalesce((t.properties ->> 'kuupalk')::INTEGER, 0) AS kuupalk,
                     coalesce((t.properties ->> 'ameti_klassif')::varchar(20), '') AS ameti_klassif                     
              FROM palk.tooleping t
              WHERE t.id = $1`,
        sqlAsNew: `SELECT
                       $1::INTEGER           AS id,
                       $2 :: INTEGER         AS userid,
                       0::INTEGER            AS parentid,
                       'TOOLEPING'           AS doc_type_id,
                       0 :: INTEGER          AS osakondid,
                       0 :: INTEGER          AS ametid,
                       now() :: DATE         AS algab,
                       NULL :: DATE          AS lopp,
                       0 :: NUMERIC(12, 4)   AS palk,
                       0 :: INTEGER          AS palgamaar,
                       1                     AS pohikoht,
                       0                     AS ametnik,
                       1                     AS tasuliik,
                       --astmepalk
                       NULL :: TEXT          AS muud,
                       (
                           SELECT
                               rekvid
                           FROM
                               ou.userid
                           WHERE
                               id = $2
                       )                     AS rekvid,
                       1                     AS resident,
                       NULL :: VARCHAR(2)    AS riik,
                       NULL :: DATE          AS toend,
                       100 :: NUMERIC(12, 4) AS koormus,
                       'EUR'::VARCHAR(20)    AS valuuta,
                       1::NUMERIC(12, 4)     AS kuurs,
                       0::INTEGER            AS pank,
                       0::INTEGER            AS kuupalk,
                       ''::varchar(20)       as ameti_klassif,
                       8 :: NUMERIC(12, 4)   AS toopaev`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    selectAsLibs: `SELECT *
                   FROM palk.com_toolepingud a
                   WHERE rekvid = $1 `, //$1 - rekvId
    returnData: {
        row: {}
    },
    requiredFields: [
        {name: 'osakondid', type: 'I'},
        {name: 'tasuliik', type: 'I'},
        {name: 'palk', type: 'N'},
        {name: 'algab', type: 'D'},
        {name: 'ametid', type: 'I'}
    ],
    saveDoc: `select palk.sp_salvesta_tooleping($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM palk.sp_delete_tooleping($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Isikukood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "osakond", name: "Osakond", width: "20%"},
            {id: "amet", name: "Amet", width: "25%"}
        ],
        sqlString: `SELECT a.*, $2::INTEGER AS userId
                    FROM palk.cur_toolepingud a
                    WHERE (rekvid = $1 OR rekvid IS NULL)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curToolepingud'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()                  AS id,
                         (qry.ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((qry.ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)             AS koostatud,
                         coalesce(to_char((qry.ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)             AS muudatud,
                         coalesce(to_char((qry.ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)             AS prinditud,
                         coalesce(to_char((qry.ajalugu ->> 'email')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)             AS
                                                                  email,
                         coalesce(to_char((qry.ajalugu ->> 'earve')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)             AS earve,
                         coalesce(to_char((qry.ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)             AS kustutatud
                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu) AS ajalugu, d.id
                           FROM palk.tooleping d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (qry.ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },

};