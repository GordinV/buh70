module.exports = {
    selectAsLibs: `SELECT *
                   FROM ou.cur_userid
                   WHERE rekvid = $1`, //$1 - asutuse id
    select: [
        {
            sql: `SELECT 'USERID'                                                                      AS doc_type_id,
                         $2 :: INTEGER                                                                 AS userid,
                         u.id,
                         u.rekvid,
                         u.kasutaja,
                         u.ametnik,
                         u.muud,
                         coalesce((u.roles ->> 'is_kasutaja') :: BOOLEAN, FALSE) :: INTEGER            AS is_kasutaja,
                         coalesce((u.roles ->> 'is_peakasutaja') :: BOOLEAN, FALSE) :: INTEGER         AS is_peakasutaja,
                         coalesce((u.roles ->> 'is_admin') :: BOOLEAN, FALSE) :: INTEGER               AS is_admin,
                         coalesce((u.roles ->> 'is_vaatleja') :: BOOLEAN, FALSE) :: INTEGER            AS is_vaatleja,
                         coalesce((u.roles ->> 'is_eel_koostaja') :: BOOLEAN, FALSE) :: INTEGER        AS is_eel_koostaja,
                         coalesce((u.roles ->> 'is_eel_allkirjastaja') :: BOOLEAN, FALSE) :: INTEGER   AS is_eel_allkirjastaja,
                         coalesce((u.roles ->> 'is_eel_esitaja') :: BOOLEAN, FALSE) :: INTEGER         AS is_eel_esitaja,
                         coalesce((u.roles ->> 'is_eel_aktsepterja') :: BOOLEAN, FALSE) :: INTEGER     AS is_eel_aktsepterja,
                         coalesce((u.roles ->> 'is_asutuste_korraldaja') :: BOOLEAN, FALSE) :: INTEGER AS is_asutuste_korraldaja,
                         coalesce((u.roles ->> 'is_rekl_administraator') :: BOOLEAN, FALSE) :: INTEGER AS is_rekl_administraator,
                         coalesce((u.roles ->> 'is_rekl_maksuhaldur') :: BOOLEAN, FALSE) :: INTEGER    AS is_rekl_maksuhaldur,
                         coalesce((u.roles ->> 'is_ladu_kasutaja') :: BOOLEAN, FALSE) :: INTEGER       AS is_ladu_kasutaja,
                         coalesce((u.roles ->> 'is_arvestaja') :: BOOLEAN, FALSE) :: INTEGER           AS is_arvestaja,
                         (u.properties ->> 'email') :: VARCHAR(254)                                    AS email,
                         (u.properties ->> 'port') :: TEXT                                             AS port,
                         (u.properties ->> 'user') :: TEXT                                             AS user,
                         (u.properties ->> 'pass') :: TEXT                                             AS pass,
                         (u.properties ->> 'smtp') :: TEXT                                             AS smtp,
                         (u.properties ->> 'earved') :: TEXT                                           AS earved
                  FROM ou.userid u
                  WHERE id = $1`,
            sqlAsNew: `SELECT
                      $1 :: INTEGER         AS id,
                      $2 :: INTEGER         AS userid,
                      'USERID'             AS doc_type_id,
                      0 :: INTEGER      AS rekvid,
                      '' :: VARCHAR(20)  AS kasutaja,
                      '' :: VARCHAR(254) AS ametnik,
                      '' :: TEXT         AS muud,
                      0 :: INTEGER     AS is_kasutaja,
                      0 :: INTEGER     AS is_peakasutaja,
                      0 :: INTEGER     AS is_admin,
                      1 :: INTEGER     AS is_vaatleja,
                      0 :: INTEGER     AS is_eel_koostaja,
                      0 :: INTEGER     AS is_eel_allkirjastaja,
                      0 :: INTEGER     AS is_eel_esitaja,
                      0 :: INTEGER     AS is_eel_aktsepterja,
                      0 :: INTEGER     AS is_asutuste_korraldaja,
                      0 :: INTEGER     AS is_rekl_administrator,
                      0 :: INTEGER     AS is_rekl_maksuhaldur,
                      0 :: INTEGER     AS is_ladu_kasutaja,
                      0 :: INTEGER     AS is_kasutaja,
                      0:: integer as is_arvestaja,
                      '' :: VARCHAR(254) AS email`,
            query: null,
            multiple: false,
            alias: 'row',
            data: []
        },
        {
            sql: `SELECT r.id, r.regkood, r.nimetus:: VARCHAR(254), r.parentid, u.id AS user_id
                  FROM ou.userid u
                           INNER JOIN ou.rekv r ON r.id = u.rekvid
                  WHERE kasutaja = $1
                    AND r.status <> 3`,
            query: null,
            multiple: true,
            alias: 'com_user_rekv',
            data: []
        },
        {
            sql: `SELECT r.nimetus AS asutus, u.*
                  FROM ou.userid u
                           INNER JOIN ou.rekv r ON r.id = u.rekvid
                  WHERE ($1 = 0
                      OR u.id = $1)
                    AND r.status <> 3
                      ORDER BY u.last_login DESC
                      , u.id DESC;`,
            query: null,
            multiple: true,
            alias: 'get_all_users',
            data: []
        },
        {
            sql: `SELECT *
                  FROM ou.get_user_data($1::TEXT, (SELECT rekvid FROM ou.userid WHERE id = $1)::INTEGER, NULL::TEXT)`, //$1 - login, $2 - rekv or null, $3 - module or null
            query: null,
            multiple: true,
            alias: 'get_last_login',
            data: []
        },
    ],
    returnData: {
        row: {},
        details: []
    },
    requiredFields: [
        {name: 'regkood', type: 'C'},
        {name: 'nimetus', type: 'C'}
    ],
    saveDoc: `select ou.sp_salvesta_userid($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `SELECT error_code, result, error_message
                FROM ou.sp_delete_userid($1 :: INTEGER, $2 :: INTEGER)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kasutaja", name: "Kasutaja tunnus", width: "25%"},
            {id: "ametnik", name: "Ametnik", width: "35%"},
            {id: "email", name: "Email", width: "35%"}
        ],
        sqlString: `SELECT $2 AS user_id,
                           u.id,
                           u.asutus::VARCHAR(254),
                           u.kasutaja::VARCHAR(254),
                           u.ametnik::VARCHAR(254),
                           u.is_admin::INTEGER,
                           u.is_kasutaja::INTEGER,
                           u.is_peakasutaja::INTEGER
                    FROM ou.cur_userid u
                    WHERE u.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur($1::INTEGER))`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curUserid'
    },
    executeSql: [
        {
            sql: `UPDATE ou.userid
                  SET parool = $2
                  WHERE upper(kasutaja) = upper($1);`, //$1- login, $2 - password hash
            type: 'sql',
            alias: 'update_hash'
        },
        {
            sql: `UPDATE ou.userid
                  SET last_login =now()
                  WHERE id = $1;`, //$1- userId
            type: 'sql',
            alias: 'update_last_login'
        },

    ],

};
