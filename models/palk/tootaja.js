module.exports = {
    select: [{
        sql: `SELECT a.id,
                     a.regkood,
                     a.nimetus,
                     a.omvorm,
                     a.aadress,
                     a.kontakt,
                     a.aadress,
                     a.tel,
                     a.faks,
                     a.email,
                     a.muud,
                     a.tp,
                     a.staatus,
                     TRUE::BOOLEAN                                AS is_tootaja,
                     a.mark,
                     $2:: INTEGER                                 AS userid,
                     'TOOTAJA'                                    AS doc_type_id,
                     (properties ->> 'pank'):: TEXT               AS pank,
                     (properties ->> 'palk_email'):: VARCHAR(254) AS palk_email,
                     a.tp
              FROM libs.asutus a
              WHERE id = $1`,
        sqlAsNew: `SELECT
                  $1 :: INTEGER            AS id,
                  $2 :: INTEGER            AS userid,
                  'TOOTAJA'               AS doc_type_id,
                  '' :: VARCHAR(20)     AS regkood,
                  '' :: VARCHAR(254)    AS nimetus,
                  'ISIK' :: VARCHAR(20)   AS omvorm,
                  NULL :: TEXT            AS aadress,
                  NULL :: TEXT            AS kontakt,
                  NULL :: VARCHAR(254)    AS tel,
                  NULL :: VARCHAR(254)    AS faks,
                  NULL :: VARCHAR(254)    AS email,
                  NULL :: TEXT            AS muud,
                  '800699' :: VARCHAR(20) AS tp,
                  0 :: INTEGER            AS staatus,
                  NULL :: TEXT            AS pank,
                  NULL :: VARCHAR(254)    AS palk_email,
                  true::boolean           AS is_tootaja,
                  NULL :: TEXT            AS mark`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT (e.element ->> 'aa') :: VARCHAR(20) AS aa,
                         $2 :: INTEGER                       AS userid
                  FROM libs.asutus a,
                       json_array_elements((a.properties -> 'asutus_aa') :: JSON) AS e(element)
                  WHERE a.id = $1`, //$1 - doc_id, $2 0 userId
            query: null,
            multiple: true,
            alias: 'asutus_aa',
            data: []

        },
        {
            sql: `SELECT *
                  FROM palk.cur_toolepingud t
                  WHERE t.parentid = $1
                    AND rekvid IN (SELECT rekvid FROM ou.userid WHERE id = $2)`,
            query: null,
            multiple: true,
            alias: 'tooleping',
            data: []

        },
        {
            sql: `SELECT liik_::VARCHAR(20),
                         tund_::VARCHAR(20),
                         maks_::VARCHAR(20),
                         id,
                         parentid,
                         lepingid,
                         libid,
                         summa,
                         CASE
                             WHEN NOT empty(percent_::INTEGER)
                                 THEN 'JAH'
                             ELSE 'EI' END :: VARCHAR(5) AS percent_,
                         CASE
                             WHEN empty(tulumaks::INTEGER)
                                 THEN 'JAH'
                             ELSE 'EI' END :: VARCHAR(5) AS tulumaks_,
                         tulumaks,
                         tulumaar,
                         status,
                         muud,
                         alimentid,
                         tunnus,
                         amet::VARCHAR(20),
                         osakond::VARCHAR(20),
                         osakondid,
                         tund,
                         liik,
                         maks,
                         asutusest,
                         round,
                         tululiik,
                         minsots,
                         rekvid,
                         kood::VARCHAR(20)               AS kood,
                         nimetus::VARCHAR(254)           AS nimetus
                  FROM palk.cur_palk_kaart pk
                  WHERE pk.parentid = $1 --asutus_id
                    AND pk.rekvid IN (SELECT rekvid
                                      FROM ou.userid u
                                      WHERE u.id = $2)`,  //$1 --asutus_id, $2 - user_id
            query: null,
            multiple: true,
            alias: 'palk_kaart',
            data: []

        },
        {
            sql: `SELECT *
                  FROM palk.get_taotlus_mvt_data($1::INTEGER, (SELECT rekvid FROM ou.userid WHERE id = $2)::INTEGER)`, //$1 asutus_id, $2 - userid
            query: null,
            multiple: true,
            alias: 'taotlus_mvt',
            data: []
        },
        {
            sql: `SELECT sum(p.summa) AS summa,
                         p.isik,
                         p.amet
                  FROM palk.cur_used_mvt p
                  WHERE p.isikid = $1
                    AND month(alg_kpv) <= $2
                    AND month(lopp_kpv) >= $2
                    AND year(alg_kpv) = $3
                  GROUP BY isik, amet`, //$1 - isik_id, $2 - kuu, $3 - aasta
            query: null,
            multiple: true,
            alias: 'curUsed_mvt',
            data: []
        },
        {
            sql: `SELECT a.id
                  FROM libs.asutus a
                  WHERE RTRIM(LTRIM(a.regkood)) = RTRIM(LTRIM($1))
                    AND a.staatus < 3
                  ORDER BY id DESC
                  LIMIT 1`, //isikukood
            query: null,
            multiple: true,
            alias: 'validate_asutus',
            data: []
        }

    ],
    selectAsLibs: `SELECT *
                   FROM palk.com_tootajad a
                   WHERE rekvid = $1`, //$1 - rekvId
    returnData: {
        row: {},
        asutus_aa: [],
        tooleping: [],
        palk_kaart: [],
        taotlus_mvt: []


    },
    requiredFields: [
        {name: 'regkood', type: 'C'},
        {name: 'nimetus', type: 'C'}
    ],
    saveDoc: `select libs.sp_salvesta_asutus($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_asutus($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Isikukood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "osakond", name: "Osakond", width: "20%"},
            {id: "amet", name: "Amet", width: "25%"}
        ],
        sqlString: `SELECT a.*, $2::INTEGER AS userId
                    FROM palk.cur_tootajad a
                    WHERE rekvid = $1`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTootajad'
    },
    getLog: {
        command: `SELECT ROW_NUMBER() OVER ()              AS id,
                         (ajalugu ->> 'user')::VARCHAR(20) AS kasutaja,
                         coalesce(to_char((ajalugu ->> 'created')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS koostatud,
                         coalesce(to_char((ajalugu ->> 'updated')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS muudatud,
                         coalesce(to_char((ajalugu ->> 'print')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS prinditud,
                         coalesce(to_char((ajalugu ->> 'deleted')::TIMESTAMP, 'DD.MM.YYYY HH.MM.SS'),
                                  '')::VARCHAR(20)         AS kustutatud

                  FROM (
                           SELECT jsonb_array_elements('[]'::JSONB || d.ajalugu::JSONB) AS ajalugu, d.id
                           FROM libs.asutus d,
                                ou.userid u
                           WHERE d.id = $1
                             AND u.id = $2
                       ) qry
                  WHERE (ajalugu ->> 'user') IS NOT NULL`,
        type: "sql",
        alias: "getLogs"
    },

};