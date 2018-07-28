module.exports = {
    selectAsLibs: `select * from com_rekv`,
    select: [{
        sql: `SELECT
                  'USERID'                                                            AS doc_type_id,
                  $2 :: INTEGER                                                        AS userid,
                  u.id,
                  u.rekvid,
                  u.kasutaja,
                  u.ametnik,
                  u.muud,
                  coalesce((u.roles ->> 'is_kasutaja') :: BOOLEAN, FALSE)::boolean           AS is_kasutaja,
                  coalesce((u.roles ->> 'is_peakasutaja') :: BOOLEAN, FALSE)::boolean        AS is_peakasutaja,
                  coalesce((u.roles ->> 'is_admin') :: BOOLEAN, FALSE)::boolean              AS is_admin,
                  coalesce((u.roles ->> 'is_eel_koostaja') :: BOOLEAN, FALSE)::boolean        AS is_eel_koostaja,
                  coalesce((u.roles ->> 'is_eel_allkirjastaja') :: BOOLEAN, FALSE)::boolean   AS is_eel_allkirjastaja,
                  coalesce((u.roles ->> 'is_eel_esitaja') :: BOOLEAN, FALSE)::boolean         AS is_eel_esitaja,
                  coalesce((u.roles ->> 'is_eel_aAktsepterja') :: BOOLEAN, FALSE)::boolean     AS is_eel_aktsepterja,
                  coalesce((u.roles ->> 'is_asutuste_korraldaja') :: BOOLEAN, FALSE)::boolean AS is_asutuste_korraldaja,
                  coalesce((u.roles ->> 'is_rekl_administraator') :: BOOLEAN, FALSE)::boolean AS is_rekl_administraator,
                  coalesce((u.roles ->> 'is_rekl_maksuhaldur') :: BOOLEAN, FALSE)::boolean    AS is_rekl_maksuhaldur,
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
                      FALSE :: BOOLEAN     AS is_kasutaja,
                      FALSE :: BOOLEAN     AS is_peakasutaja,
                      FALSE :: BOOLEAN     AS is_admin,
                      FALSE :: BOOLEAN     AS is_eel_koostaja,
                      FALSE :: BOOLEAN     AS is_eel_allkirjastaja,
                      FALSE :: BOOLEAN     AS is_eel_esitaja,
                      FALSE :: BOOLEAN     AS is_eel_aktsepterja,
                      FALSE :: BOOLEAN     AS is_asutuste_korraldaja,
                      FALSE :: BOOLEAN     AS is_rekl_administrator,
                      FALSE :: BOOLEAN     AS is_rekl_maksuhaldur,
                      FALSE :: BOOLEAN     AS is_kasutaja,
                      NULL :: VARCHAR(254) AS email`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
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
