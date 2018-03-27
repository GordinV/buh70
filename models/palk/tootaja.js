module.exports = {
    select: [{
        sql: `SELECT
                  a.id,
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
                  true::boolean as is_tootaja,
                  a.mark,
                    1:: INTEGER AS userid,
                'TOOTAJA' AS doc_type_id,
                (properties->>'pank'):: TEXT AS pank,
                a.tp
                FROM libs.asutus a 
                where id = $1`,
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
                  true::boolean           AS is_tootaja,
                  NULL :: TEXT            AS mark`,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    },
        {
        sql: `SELECT (e.element ->> 'aa') :: varchar(20) AS aa,
                $2 :: INTEGER            AS userid
                FROM libs.asutus a,
                      json_array_elements((a.properties -> 'asutus_aa') :: JSON) AS e(element)
                WHERE a.id = $1`, //$1 - doc_id, $2 0 userId
        query: null,
        multiple: true,
        alias: 'asutus_aa',
        data: []

    },
        {
        sql: `SELECT
                  t.id,
                  t.lopp,
                  t.ametid,
                  t.osakondid,
                  t.muud,
                  t.parentid,
                  t.rekvid,
                  t.algab,
                  t.ametnik,
                  t.koormus,
                  t.palgamaar,
                  t.palk,
                  t.pohikoht,
                  t.resident,
                  t.riik,
                  t.toend,
                  t.toopaev,
                  t.tasuliik,
                  osakond.kood                          AS osakond,
                  amet.kood                             AS amet,
                  coalesce(v.valuuta, 'EUR') :: VARCHAR AS valuuta,
                  coalesce(v.kuurs, 1) :: NUMERIC       AS kuurs,
                  $2 :: INTEGER            AS userid
                FROM palk.tooleping t
                  INNER JOIN libs.library osakond ON osakond.id = t.osakondid
                  INNER JOIN libs.library amet ON amet.id = t.ametid
                  LEFT OUTER JOIN docs.dokvaluuta1 v
                    ON (v.dokid = t.id AND v.dokliik = array_position((enum_range(NULL :: DOK_VALUUTA)), 'tooleping'))
                WHERE t.parentid = $1`,
        query: null,
        multiple: true,
        alias: 'tooleping',
        data: []

    },
        {
            sql: `select * from palk.cur_palk_kaart pk
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
            sql: `select * from palk.get_taotlus_mvt_data($1, (select rekvid from ou.userid where id = $2)::integer)`, //$1 asutus_id, $2 - userid
            query: null,
            multiple: true,
            alias: 'taotlus_mvt',
            data: []
        }],
    selectAsLibs: `select * from palk.com_tootajad a 
        where (rekvid = $1 or rekvid is null)`, //$1 - rekvId
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
    saveDoc: `select libs.sp_salvesta_asutus($1, $2, $3) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: `select error_code, result, error_message from libs.sp_delete_asutus($1, $2)`, // $1 - userId, $2 - docId
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "regkood", name: "Isikukood", width: "25%"},
            {id: "nimetus", name: "Nimetus", width: "35%"},
            {id: "osakond", name: "Osakond", width: "20%"},
            {id: "amet", name: "Amet", width: "25%"}
        ],
        sqlString: `select a.*, $2::integer as userId
            from palk.cur_tootajad a
            where (rekvid = $1 or rekvid is null)`,     // проверка на права. $1 всегда ид учреждения $2 - всегда ид пользователя
        params: '',
        alias: 'curTootajad'
    },
};