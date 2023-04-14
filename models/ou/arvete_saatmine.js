module.exports = {
    selectAsLibs: `SELECT null`,
    select: [{
        sql: `SELECT am.id,
                     to_char(am.alg_kpv, 'YYYY-MM-DD')  AS alg_kpv,
                     to_char(am.lopp_kpv, 'YYYY-MM-DD') AS lopp_kpv,
                     am.kas_alusta::BOOLEAN,
                     am.muud,
                     CASE
                         WHEN am.kas_alusta
                             THEN 'Jah'
                         ELSE 'Ei' END :: TEXT          AS alustatud,
                     u.ametnik

              FROM ou.arvete_meil am,
                   ou.userid u
              WHERE am.id = $1
                AND u.id = $2`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER         AS id,
                      $2 :: INTEGER         AS userid,
                       gomonth(make_date(date_part('year', current_date)::INTEGER, date_part('month', current_date)::INTEGER, 1),
                               -1)                                                                                                    AS alg_kpv,
                       make_date(date_part('year', current_date)::INTEGER, date_part('month', current_date)::INTEGER, 1) -
                       1                                                                                                              AS lopp_kpv,
                       FALSE                                                                                                          AS kas_alusta,
                       NULL::TEXT                                                                                                     AS muud                      `,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    returnData: {
        row: {},
        details: []
    },
    requiredFields: [],
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "period", name: "Period", width: "40%"},
            {id: "alustatud", name: "Kas alustatud", width: "10%"},
            {id: "ametnik", name: "Kasutaja", width: "40%"},
        ],

        sqlString: `SELECT am.id,
                           to_char(am.alg_kpv,'DD.MM.YYYY') as alg_kpv,
                           to_char(am.lopp_kpv,'DD.MM.YYYY') as lopp_kpv,
                           to_char(am.alg_kpv, 'DD.MM.YYYY') || '-' || to_char(am.lopp_kpv, 'DD.MM.YYYY') AS period,
                           CASE
                               WHEN am.kas_alusta
                                   THEN 'Jah'
                               ELSE 'Ei' END :: TEXT                                                      AS alustatud,
                           am.muud,
                           u.ametnik,
                           $2                                                                             AS userid
                    FROM ou.arvete_meil am
                             INNER JOIN ou.userid u ON u.id = am.user_id
                    WHERE am.rekvid = $1
                    ORDER BY alg_kpv, lopp_kpv`, //$1 rekvid
        alias: 'curArveteSaatmine',
        params: '',
    },
    returnData: null,
    saveDoc: `select ou.sp_salvesta_arvete_meil($1::json, $2::integer, $3::integer) as id`, // $1 - data json, $2 - userid, $3 - rekvid
    deleteDoc: null,
    requiredFields: [
        {name: 'alg_kpv', type: 'D'},
        {name: 'lopp_kpv', type: 'D'},
    ],
    print: [
        {
            view: 'arvete_saatmine',
            params: 'id',
        },
        {
            view: 'arvete_saatmine',
            params: 'sqlWhere'
        },
    ],

};
