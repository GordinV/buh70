let now = new Date();

module.exports = {
    selectAsLibs: `SELECT null`,
    select: [{
        sql: `SELECT am.id,
                     to_char(am.alg_kpv, 'YYYY-MM-DD')                 AS alg_kpv,
                     to_char(am.lopp_kpv, 'YYYY-MM-DD')                AS lopp_kpv,
                     am.kas_alusta::BOOLEAN,
                     am.kas_alusta                                     AS eelmise_alus_status,
                     am.muud,
                     CASE
                         WHEN gomonth(make_date(date_part('year', am.lopp_kpv)::INTEGER,
                                                date_part('month', am.lopp_kpv)::INTEGER, 01),
                                      1)::DATE < am.kas_alusta_timestamp::DATE
                             THEN
                             to_char(am.kas_alusta_timestamp::TIMESTAMP, 'DD.MM.YYYY HH24:MI:SS')
                         ELSE
                             to_char(gomonth(make_date(date_part('year', am.lopp_kpv)::INTEGER,
                                                       date_part('month', am.lopp_kpv)::INTEGER, 01),
                                             1)::DATE, 'DD.MM.YYYY HH24:MI:SS')::TEXT
                         END
                                                                       AS saatmine_alustatakse,
                     CASE
                         WHEN am.kas_alusta
                             THEN 'Jah'
                         ELSE 'Ei' END :: TEXT                         AS alustatud,
                     am.kas_alusta_timestamp                           AS kas_alusta_timestamp,
                     coalesce(u_al.ametnik, '')::TEXT                  AS al_ametnik,
                     CASE
                         WHEN am.paus
                             THEN 'Jah'
                         ELSE 'Ei' END :: TEXT                         AS kas_paus,
                     am.paus,
                     to_char(am.paus_timestamp, 'DD.MM.YYYY HH24-MI-SS') AS paus_timestamp,
                     coalesce(u_p.ametnik, '')                         AS p_ametnik,
                     u.ametnik                                         AS kasutaja
              FROM ou.arvete_meil am
                       INNER JOIN ou.userid u ON u.id = $2
                       LEFT OUTER JOIN ou.userid u_al ON u_al.id = am.alusta_ametnik
                       LEFT OUTER JOIN ou.userid u_p ON u_p.id = am.alusta_ametnik
              WHERE am.id = $1`,
        sqlAsNew: `SELECT
                      $1 :: INTEGER         AS id,
                      $2 :: INTEGER         AS userid,
                       to_char(gomonth(make_date(date_part('year', current_date)::INTEGER, date_part('month', current_date)::INTEGER, 1),
                               -1),'YYYY-MM-DD')                                                                                                    AS alg_kpv,
                       to_char(make_date(date_part('year', current_date)::INTEGER, date_part('month', current_date)::INTEGER, 1) -
                       1,'YYYY-MM-DD')                                                                                                              AS lopp_kpv,
                       FALSE                                                                                                          AS kas_alusta,
                       NULL::TEXT                                                                                                     AS muud                      `,
        query: null,
        multiple: false,
        alias: 'row',
        data: []
    }],
    requiredFields: [
        {
            name: 'alg_kpv', type: 'D',
            min: now.setMonth(now.getMonth() - 1),
            max: now.setMonth(now.getMonth() + 1)
        },
        {
            name: 'lopp_kpv', type: 'D',
            min: now.setMonth(now.getMonth()),
            max: now.setMonth(now.getMonth() + 2)
        },
    ],
    returnData: {
        row: {},
        details: []
    },
    grid: {
        gridConfiguration: [
            {id: "id", name: "id", width: "10%", show: false},
            {id: "period", name: "Period", width: "20%"},
            {id: "alustatud", name: "Kas alustatud", width: "10%"},
            {id: "ametnik", name: "Kasutaja", width: "40%"},
            {id: "paus", name: "Paus", width: "10%"},
            {id: "paus_timestamp", name: "Paus alates", width: "20%"},
        ],

        sqlString: `SELECT am.id,
                           to_char(am.alg_kpv, 'DD.MM.YYYY')                                              AS alg_kpv,
                           to_char(am.lopp_kpv, 'DD.MM.YYYY')                                             AS lopp_kpv,
                           to_char(am.alg_kpv, 'DD.MM.YYYY') || '-' || to_char(am.lopp_kpv, 'DD.MM.YYYY') AS period,
                           CASE
                               WHEN am.kas_alusta
                                   THEN 'Jah'
                               ELSE 'Ei' END :: TEXT                                                      AS alustatud,
                           am.muud,
                           u.ametnik,
                           $2                                                                             AS userid,
                           CASE
                               WHEN NOT coalesce(am.kas_alusta, FALSE) THEN ''
                               WHEN am.paus
                                   THEN 'Jah'
                               ELSE 'Ei' END :: TEXT                                                      AS paus,
                           to_char(am.paus_timestamp, 'DD.MM.YYYY HH-MI-SS')                              AS paus_timestamp
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
