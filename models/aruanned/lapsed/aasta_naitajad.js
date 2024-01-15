module.exports = {
    grid: {
        gridConfiguration: [
            {
                id: "period",
                name: "Seisuga",
                width: "0%",
                type: "date",
                interval: false,
                show: false,
                filterValidation: true
            },
            {id: "grupp_liik", name: "Grupi liik", width: "0%", show: false, toolTip: 'LASTEAED,HUVIKOOL,KOOL'},
            {
                id: "koolituse_tyyp",
                name: "Koolituse tüüp",
                width: "0%",
                show: false,
                toolTip: 'LASTEAJARÜHM,AED,SPORT,HUVIRING'
            },
            {id: "liik", name: "Liik", width: "10%"},
            {id: "asutus", name: "Asutus", width: "15%"},
            {id: "jaanuar", name: "Jaanuar", width: "5%", type: "integer", filter: "not"},
            {id: "veebruar", name: "Veebruar", width: "5%", type: "integer", filter: "not"},
            {id: "marts", name: "Märts", width: "5%", type: "integer", filter: "not"},
            {id: "apriil", name: "Apriil", width: "5%", type: "integer", filter: "not"},
            {id: "mai", name: "Mai", width: "5%", type: "integer", filter: "not"},
            {id: "juuni", name: "Juuni", width: "5%", type: "integer", filter: "not"},
            {id: "juuli", name: "Juuli", width: "5%", type: "integer", filter: "not"},
            {id: "august", name: "August", width: "5%", type: "integer", filter: "not"},
            {id: "september", name: "September", width: "5%", type: "integer", filter: "not"},
            {id: "oktoober", name: "Oktoober", width: "5%", type: "integer", filter: "not"},
            {id: "november", name: "November", width: "5%", type: "integer", filter: "not"},
            {id: "detsember", name: "Detsember", width: "5%", type: "integer", filter: "not"},
        ],
        sqlString: `with report as (
                        select 
                           d.rekvid,
                           d.period,
                           d.liik,
                           sum(d.lapsed_kokku)                         AS lapsed_kokku,
                           sum(d.jaanuar)                              AS jaanuar,
                           sum(d.veebruar)                             AS veebruar,
                           sum(d.marts)                                AS marts,
                           sum(d.apriil)                               AS apriil,
                           sum(d.mai)                                  AS mai,
                           sum(d.juuni)                                AS juuni,
                           sum(d.juuli)                                AS juuli,
                           sum(d.august)                               AS august,
                           sum(d.september)                            AS september,
                           sum(d.oktoober)                             AS oktoober,
                           sum(d.november)                             AS november,
                           sum(d.detsember)                            AS detsember,
                           r.nimetus::TEXT                             AS asutus
                    FROM lapsed.aasta_naitajad($1::INTEGER, $3::DATE, $4::TEXT, $5::TEXT, 1) d
                             INNER JOIN ou.rekv r ON r.id = d.rekvid
                    GROUP BY d.rekvid, d.period, d.liik, r.nimetus                        
                        )
                        
                    SELECT row_number() OVER ()                        AS row_id,
                           sum(d.jaanuar) OVER (PARTITION BY rekvid)   AS jaanuar_group,
                           sum(d.veebruar) OVER (PARTITION BY rekvid)  AS veebruar_group,
                           sum(d.marts) OVER (PARTITION BY rekvid)     AS marts_group,
                           sum(d.apriil) OVER (PARTITION BY rekvid)    AS apriil_group,
                           sum(d.mai) OVER (PARTITION BY rekvid)       AS mai_group,
                           sum(d.juuni) OVER (PARTITION BY rekvid)     AS juuni_group,
                           sum(d.juuli) OVER (PARTITION BY rekvid)     AS juuli_group,
                           sum(d.august) OVER (PARTITION BY rekvid)    AS august_group,
                           sum(d.september) OVER (PARTITION BY rekvid) AS september_group,
                           sum(d.oktoober) OVER (PARTITION BY rekvid)  AS oktoober_group,
                           sum(d.november) OVER (PARTITION BY rekvid)  AS november_group,
                           sum(d.detsember) OVER (PARTITION BY rekvid) AS detsember_group,
                           $4::TEXT                                    AS grupp_liik,
                           $5::TEXT                                    AS koolituse_tyyp,
                           d.rekvid,
                           d.period,
                           d.liik,
                           (d.lapsed_kokku)                         AS lapsed_kokku,
                           (d.jaanuar)                              AS jaanuar,
                           (d.veebruar)                             AS veebruar,
                           (d.marts)                                AS marts,
                           (d.apriil)                               AS apriil,
                           (d.mai)                                  AS mai,
                           (d.juuni)                                AS juuni,
                           (d.juuli)                                AS juuli,
                           (d.august)                               AS august,
                           (d.september)                            AS september,
                           (d.oktoober)                             AS oktoober,
                           (d.november)                             AS november,
                           (d.detsember)                            AS detsember,
                           d.asutus::TEXT                           AS asutus,
                           $2                                       AS user_id
                    FROM report d
                    ORDER BY d.asutus, d.liik
        `,     // $1 - rekvid, $2 - user_id, $3 - seisuga, $4 - grupp_liik, $5 - koolituse_tyyp
        params: ['rekvid', 'userid', 'period', 'grupp_liik', 'koolituse_tyyp'],
        min_params: 3,
        alias: 'aasta_naitajad_report',
        notReloadWithoutParameters: true
    },
    print: [
        {
            view: 'aasta_naitajad_register',
            params: 'sqlWhere',
            group: 'asutus'
        },
    ],

};
