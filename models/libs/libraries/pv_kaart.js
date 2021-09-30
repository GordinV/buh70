module.exports = {
    selectAsLibs: `SELECT *
                   FROM cur_pohivara l
                   WHERE (l.rekvId = $1 OR l.rekvid IS NULL)`,
    select: [{
        sql: `SELECT l.id,
                     l.rekvid,
                     (l.properties :: JSONB ->> 'parent_id') :: INTEGER                                    AS parent_id,
                     (SELECT kood
                      FROM libs.library
                      WHERE id = (l.properties :: JSONB ->> 'parent_id') :: INTEGER)::VARCHAR(20)          AS parent_kood,
                     (SELECT nimetus
                      FROM libs.library
                      WHERE id = (l.properties :: JSONB ->> 'parent_id') :: INTEGER)::VARCHAR(254)         AS parent_nimetus,
                     l.kood,
                     l.nimetus,
                     l.muud,
                     l.status,
                     l.library,
                     $2 :: INTEGER                                                                         AS userid,
                     'POHIVARA'                                                                            AS doc_type_id,
                     (l.properties :: JSONB ->> 'gruppid') :: INTEGER                                      AS gruppid,
                     (l.properties :: JSONB ->> 'konto') :: VARCHAR(20)                                    AS konto,
                     coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE, now() :: DATE)                AS soetkpv,
                     (l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 4)                                 AS kulum,
                     (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 4)                              AS algkulum,
                     coalesce(jaak.kulum, 0) :: NUMERIC(12, 4)                                             AS kulum_kokku,
                     (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2)                              AS soetmaks,
                     (jaak.soetmaks) :: NUMERIC(12, 2)                                                     AS parhind,
                     (jaak.jaak) :: NUMERIC(12, 2)                                                         AS jaak,
                     (l.properties :: JSONB ->> 'vastisikid') :: INTEGER                                   AS vastIsikId,
                     (l.properties :: JSONB ->> 'selg') :: TEXT                                            AS selg,
                     (l.properties :: JSONB ->> 'rentnik') :: TEXT                                         AS rentnik,
                     (l.properties :: JSONB ->> 'liik') :: TEXT                                            AS liik,
                     (l.properties :: JSONB ->> 'mahakantud') :: DATE                                      AS mahakantud,
                     coalesce((l.properties :: JSONB ->> 'pindala') :: NUMERIC(12, 4), 0):: NUMERIC(12, 4) AS pindala,
                     (l.properties :: JSONB ->> 'kinnitus_osa') ::NUMERIC(12, 4)                           AS kinnitus_osa,
                     (l.properties :: JSONB ->> 'kadastri_uksus') ::VARCHAR(254)                           AS kadastri_uksus,
                     (l.properties :: JSONB ->> 'motteline_osa') ::VARCHAR(254)                            AS motteline_osa,
                     (l.properties :: JSONB ->> 'ehituse_objekt') ::VARCHAR(254)                           AS ehituse_objekt,
                     (l.properties :: JSONB ->> 'aadress') ::TEXT                                          AS aadress,
                     jaak.turu_vaartsus:: NUMERIC(12, 4)                                                   AS turu_vaartsus,
                     jaak.eluiga :: NUMERIC(12, 2)                                                         AS eluiga,
                     'EUR' :: VARCHAR(20)                                                                  AS valuuta,
                     1 :: NUMERIC(12, 2)                                                                   AS kuurs,
                     g.kood                                                                                AS grupp,
                     a.nimetus                                                                             AS vastisik,
                     (SELECT sum(summa)
                      FROM docs.pv_oper po
                      WHERE po.pv_kaart_id = l.id
                        AND liik = 2)                                                                      AS arv_kulum
              FROM libs.library l
                       INNER JOIN libs.get_pv_kaart_jaak(l.id) jaak ON jaak.id = l.id
                       LEFT OUTER JOIN libs.library g ON g.id = (l.properties :: JSONB ->> 'gruppid') :: INTEGER
                       LEFT OUTER JOIN libs.asutus a ON a.id = (l.properties :: JSONB ->> 'vastisikid') :: INTEGER
              WHERE l.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER               AS id,
                      $2 :: INTEGER               AS userid,
                      NULL::INTEGER               as parent_id,
                      NULL::VARCHAR(20)           as parent_kood,
                      NULL::VARCHAR(254)         as parent_nimetus,
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
                      NULL::INTEGER              AS parent_id,
                      0:: NUMERIC(12, 2)         AS pindala,
                      0:: NUMERIC(12, 2)         AS turu_vaartsus,
                      0:: NUMERIC(12, 2)         AS eluiga,
                      0:: NUMERIC(12, 2)         AS kinnitus_osa,
                      ''::VARCHAR(254)           AS kadastri_uksus,
                      ''::VARCHAR(254)           AS motteline_osa,
                      ''::VARCHAR(254)           AS ehituse_objekt,
                      ''::TEXT                   AS aadress,
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
    },
        {
            sql: `SELECT $2::INTEGER AS user_id, $1 AS pv_id, po.*
                  FROM cur_pohivara po
                  WHERE parent_id IS NOT NULL
                    AND parent_id = $1`, //$1 - карта ОС, $2 - kasutaja id,
            multiple: true,
            alias: 'seotatud_kaardid',
            data: []
        },
        {
            sql: `SELECT $2 :: INTEGER AS userid, po.*
                  FROM libs.get_pv_kaart_jaak($1::INTEGER) po`, //$1 doc_id, $2 userId
            multiple: false,
            alias: 'pv_jaak',
            data: []
        }
    ],
    returnData: {
        row: {},
        details: [],
    },
    requiredFields: [
        {name: 'kood', type: 'C'},
        {name: 'nimetus', type: 'C'},
        {name: 'gruppid', type: 'I'}
    ],
    saveDoc: `select libs.sp_salvesta_pv_kaart($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM libs.sp_delete_library($1 :: INTEGER, $2 :: INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "pv_grupp", name: "Grupp", width: "35%"},
        ],
        sqlString: `SELECT l.id,
                           l.kood,
                           l.nimetus,
                           l.rekvid,
                           coalesce(a.nimetus, '') :: VARCHAR(254)                                               AS vastisik,
                           (l.properties :: JSONB ->> 'vastisikid') :: INTEGER                                   AS vastisikid,
                           (l.properties :: JSONB ->> 'algkulum') :: NUMERIC(12, 2)                              AS algkulum,
                           (l.properties :: JSONB ->> 'kulum') :: NUMERIC(12, 2)                                 AS kulum,
                           (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2)                              AS soetmaks,
                           coalesce((l.properties :: JSONB ->> 'parhind') :: NUMERIC(12, 2),
                                    (l.properties :: JSONB ->> 'soetmaks') :: NUMERIC(12, 2))                    AS parhind,
                           coalesce((l.properties :: JSONB ->> 'kulum_kokku') :: NUMERIC(12, 2),
                                    0) :: NUMERIC(12, 2)                                                         AS kulum_kokku,
                           coalesce((l.properties :: JSONB ->> 'jaak') :: NUMERIC(12, 2), 0) :: NUMERIC(12, 2)   AS jaak,
                           coalesce((l.properties :: JSONB ->> 'soetkpv') :: DATE,
                                    date(1900, 01, 01))                                                          AS soetkpv,
                           coalesce((l.properties :: JSONB ->> 'konto'), '') :: VARCHAR(20)                      AS konto,
                           coalesce((l.properties :: JSONB ->> 'tunnus'), '') :: VARCHAR(20)                     AS tunnus,
                           (l.properties :: JSONB ->> 'mahakantud') :: DATE                                      AS mahakantud,
                           coalesce((l.properties :: JSONB ->> 'rentnik'), '') :: VARCHAR(120)                   AS rentnik,
                           (l.properties :: JSONB ->> 'liik') :: VARCHAR(120)                                    AS liik,
                           coalesce((l.properties :: JSONB ->> 'selg'), '') :: VARCHAR(120)                      AS selgitus,
                           (l.properties :: JSONB ->> 'parent_id') :: INTEGER                                    AS parent_id,
                           coalesce((l.properties :: JSONB ->> 'pindala') :: NUMERIC(12, 4), 0):: NUMERIC(12, 4) AS pindala,
                           'EUR' :: CHARACTER VARYING                                                            AS valuuta,
                           1 :: NUMERIC                                                                          AS kuurs,
                           grupp.id                                                                              AS gruppid,
                           grupp.nimetus                                                                         AS grupp,
                           coalesce(p.kood, '')                                                                  AS parent_kood,
                           coalesce(p.nimetus, '')                                                               AS parent_nimetus,
                           coalesce((l.properties :: JSONB ->> 'aadress'), ''):: VARCHAR(254)                    AS aadress,
                           l.status,
                           $2                                                                                    AS user_id
                    FROM libs.library l
                             JOIN libs.library grupp ON (l.properties :: JSONB -> 'gruppid') = to_jsonb(grupp.id)
                             LEFT JOIN libs.asutus a ON (l.properties :: JSONB -> 'vastisikid') = to_jsonb(a.id)
                             LEFT JOIN libs.library p ON (l.properties :: JSONB -> 'parent_id') = to_jsonb(p.id)
                    WHERE l.status <> 3
                      AND l.rekvId = $1
                      AND ($3 IS NULL OR coalesce((l.properties :: JSONB ->> 'selg'), '') ILIKE $3) 
        `,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
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
