module.exports = {
    selectAsLibs: `select * from ou.cur_userid where rekvid = $1`, //$1 - asutuse id
    select: [{
        sql: `SELECT
                  'USERID'                                                            AS doc_type_id,
                  $2 :: INTEGER                                                        AS userid,
                  u.id,
                  u.rekvid,
                  u.kasutaja,
                  u.ametnik,
                  u.muud,
                  coalesce((u.roles ->> 'is_kasutaja') :: BOOLEAN, FALSE)::integer           AS is_kasutaja,
                  coalesce((u.roles ->> 'is_peakasutaja') :: BOOLEAN, FALSE)::integer        AS is_peakasutaja,
                  coalesce((u.roles ->> 'is_admin') :: BOOLEAN, FALSE)::integer              AS is_admin,
                  coalesce((u.roles ->> 'is_vaatleja') :: BOOLEAN, FALSE)::integer              AS is_vaatleja,
                  coalesce((u.roles ->> 'is_eel_koostaja') :: BOOLEAN, FALSE)::integer        AS is_eel_koostaja,
                  coalesce((u.roles ->> 'is_eel_allkirjastaja') :: BOOLEAN, FALSE)::integer   AS is_eel_allkirjastaja,
                  coalesce((u.roles ->> 'is_eel_esitaja') :: BOOLEAN, FALSE)::integer         AS is_eel_esitaja,
                  coalesce((u.roles ->> 'is_eel_aktsepterja') :: BOOLEAN, FALSE)::integer     AS is_eel_aktsepterja,
                  coalesce((u.roles ->> 'is_asutuste_korraldaja') :: BOOLEAN, FALSE)::integer AS is_asutuste_korraldaja,
                  coalesce((u.roles ->> 'is_rekl_administraator') :: BOOLEAN, FALSE)::integer AS is_rekl_administraator,
                  coalesce((u.roles ->> 'is_rekl_maksuhaldur') :: BOOLEAN, FALSE)::integer    AS is_rekl_maksuhaldur,
                  (u.properties ->> 'email') :: VARCHAR(254)                          AS email
                FROM ou.userid u
                where id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER         AS id,
                      $2 :: INTEGER         AS userid,
                      'USERID'             AS doc_type_id,
                      NULL :: INTEGER      AS rekvid,
                      NULL :: VARCHAR(20)  AS kasutaja,
                      NULL :: VARCHAR(254) AS ametnik,
                      NULL :: TEXT         AS muud,
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
                      0 :: INTEGER     AS is_kasutaja,
                      NULL :: VARCHAR(254) AS email`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },{
        sql: `select distinct rekvid from ou.userid where kasutaja = $1`,
        query: null,
        multiple: true,
        alias:'com_user_rekv',
        data:[]
    }],
    returnData: {
        row: {},
        details:[]
    },
    requiredFields: [
        {name: 'regkood', type: 'C'},
        {name: 'nimetus', type: 'C'}
    ],
    saveDoc: `select ou.sp_salvesta_userid($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from ou.sp_delete_userid($1::integer, $2::integer)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "kasutaja", name: "Kasutaja tunnus", width: "25%"},
            {id: "ametnik", name: "Ametnik", width: "35%"},
            {id: "email", name: "Email", width: "35%"}
        ],
        sqlString: `SELECT
                      $2 AS user_id,
                      u.*
                    FROM ou.cur_userid u
                    WHERE u.id IN (SELECT rekv_id
                                       FROM get_asutuse_struktuur($1))`,     //  $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curUserid'
    },

};
