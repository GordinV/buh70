module.exports = {
    selectAsLibs: `SELECT id, nimetus::VARCHAR(254), regkood::VARCHAR(20), parentid
                   FROM com_rekv
                   ORDER BY nimetus`,
    select: [{
        sql: `SELECT 'REKV'                                                           AS doc_type_id,
                     $2::INTEGER                                                      AS userid,
                     r.id,
                     r.parentid,
                     r.nimetus::VARCHAR(254),
                     coalesce(r.muud, nimetus)::VARCHAR(254)                          AS taisnimetus,
                     r.aadress,
                     r.email::VARCHAR(254),
                     r.faks::VARCHAR(254),
                     r.haldus::VARCHAR(254),
                     r.juht::VARCHAR(254),
                     r.raama::VARCHAR(254),
                     r.kbmkood::VARCHAR(20),
                     r.muud,
                     r.regkood::VARCHAR(20),
                     r.tel::VARCHAR(254),
                     ((r.properties ->> 'arved')::JSONB ->> 'tahtpaev')::INTEGER      AS tahtpaev,
                     ((r.properties ->> 'reklftp')::JSONB ->> 'ftp')::VARCHAR(120)    AS ftp,
                     ((r.properties ->> 'reklftp')::JSONB ->> 'login')::VARCHAR(120)  AS login,
                     ((r.properties ->> 'reklftp')::JSONB ->> 'parool')::VARCHAR(120) AS parool,
                     (r.properties ->> 'earved') ::VARCHAR(254)                       AS earved,
                     (u.properties ->> 'earved')::VARCHAR(254)                        AS earved_omniva,
                     (r.properties ->> 'earve_asutuse_nimi')::VARCHAR(254)            AS earve_asutuse_nimi,
                     (r.properties ->> 'earve_regkood')::VARCHAR(254)                 AS earve_regkood,
                     coalesce((r.properties ->> 'seb_earve'), '')::VARCHAR(254)       AS seb_earve,
                     coalesce((r.properties ->> 'swed_earve'), '')::VARCHAR(254)      AS swed_earve,
                     (r.properties ->> 'liik') :: VARCHAR(20)                         AS liik,
                     (r.properties ->> 'swed') ::VARCHAR(254)                         AS swed,
                     (r.properties ->> 'seb') ::VARCHAR(254)                          AS seb,
                     (SELECT tp
                      FROM ou.aa
                      WHERE parentid = $1
                        AND kassa = 2
                          LIMIT 1)::VARCHAR(20)                                       AS oma_tp

              FROM ou.rekv r,
                   ou.userid u
              WHERE r.id = $1
                AND u.id = $2`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER        AS id,
                      $2 :: INTEGER        AS userid,
                      'REKV'               AS doc_type_id,
                      NULL :: INTEGER      AS parentid,
                      NULL :: VARCHAR(20)  AS regkood,
                      NULL :: VARCHAR(254) AS nimetus,
                      NULL :: VARCHAR(20)  AS kbmkood,
                      NULL :: TEXT         AS aadress,
                      NULL :: TEXT         AS haldus,
                      NULL :: VARCHAR(254) AS tel,
                      NULL :: VARCHAR(254) AS faks,
                      NULL :: VARCHAR(254) AS email,
                      NULL :: VARCHAR(254) AS juht,
                      NULL :: VARCHAR(254) AS raama,
                      NULL :: TEXT         AS muud,
                      null::integer as tahtpaev,
                     NULL :: VARCHAR(120) AS ftp,
                     NULL :: VARCHAR(120) AS login,
                     NULL :: VARCHAR(254) AS earved,
                     NULL::TEXT                    AS earve_asutuse_nimi,
                     NULL::TEXT                         AS earve_regkood,
                     NULL::TEXT                       AS seb_earve,
                     NULL::TEXT                      AS swed_earve,
                     NULL ::VARCHAR(254)                         AS swed,
                     NULL ::VARCHAR(254)                          AS seb,

                     NULL :: VARCHAR(20) AS liik,
                     NULL :: VARCHAR(120) AS parool`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
            sql: `SELECT aa.id,
                         aa.arve,
                         aa.nimetus,
                         aa.default_,
                         aa.kassa,
                         aa.pank,
                         aa.konto::VARCHAR(20),
                         aa.tp,
                         kassa AS kassapank,
                         $2    AS userId
                  FROM ou.Aa aa
                  WHERE Aa.parentid = $1`,
            query: null,
            multiple: true,
            alias: 'details',
            data: []
        },
        {
            sql: `SELECT c.id,
                         c.number,
                         c.rekvid,
                         c.toolbar1,
                         c.toolbar2,
                         c.toolbar3,
                         c.tahtpaev,
                         coalesce((u.properties ->> 'keel')::INTEGER, 2)::INTEGER          AS keel,
                         coalesce((u.properties ->> 'port')::VARCHAR(100))::VARCHAR(254)   AS port,
                         coalesce((u.properties ->> 'smtp')::VARCHAR(100))::VARCHAR(254)   AS smtp,
                         coalesce((u.properties ->> 'user')::VARCHAR(100))::VARCHAR(254)   AS user,
                         coalesce((u.properties ->> 'pass')::VARCHAR(100))::VARCHAR(254)   AS pass,
                         coalesce((u.properties ->> 'email')::VARCHAR(100))::VARCHAR(254)  AS email,
                         coalesce((c.properties ->> 'earved')::VARCHAR(254))::VARCHAR(254) AS earved,
                         coalesce((c.properties ->> 'liik')::VARCHAR(20))::VARCHAR(20)     AS liik

                  FROM ou.config c,
                       ou.userid u
                  WHERE c.rekvid = $1
                    AND u.id = $2`,
            query: null,
            multiple: false,
            alias: 'config',
            data: []
        },

    ],
    returnData: {
        row: {},
        details: [],
        gridConfig: [
            {id: 'id', name: 'id', width: '0px', show: false, type: 'text', readOnly: true},
            {id: 'arve', name: 'Arve', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'nimetus', name: 'Nimetus', width: '300px', show: true, readOnly: true},
            {id: 'konto', name: 'Konto', width: '100px', show: true, type: 'text', readOnly: false},
            {id: 'tp', name: 'TP', width: '100px', show: true, type: 'text', readOnly: false},
        ]

    },
    requiredFields: [
        {name: 'regkood', type: 'C'},
        {name: 'nimetus', type: 'C'}
    ],
    saveDoc: `select ou.sp_salvesta_rekv($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM ou.sp_delete_rekv($1::INTEGER, $2::INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Kood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"}
        ],
        sqlString: `SELECT $2 AS user_id,
                           r.*
                    FROM cur_rekv r
                    WHERE r.status <> 3
                      AND r.id IN (SELECT rekv_id
                                   FROM get_asutuse_struktuur($1::INTEGER))`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curRekv'
    },
    print: [
        {
            view: 'rekv_kaart',
            params: 'id'
        },
    ]

};
