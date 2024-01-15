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
                id: "tyyp_nimi",
                name: "Koolituse nimetus",
                width: "15%",
                show: true
            },
            {
                id: "tyyp",
                name: "Koolituse tüüp",
                width: "5%",
                show: true
            },
            {id: "liik", name: "Liik", width: "5%"},
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
        sqlString: `SELECT row_number() OVER ()                        AS row_id,
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
                           d.tyyp,
                           d.tyyp_nimi,
                           d.lapsed_kokku,
                           d.jaanuar,
                           d.veebruar,
                           d.marts,
                           d.apriil,
                           d.mai,
                           d.juuni,
                           d.juuli,
                           d.august,
                           d.september,
                           d.oktoober,
                           d.november,
                           d.detsember,
                           r.nimetus::TEXT                             AS asutus,
                           $2                                          AS user_id
                    FROM lapsed.aasta_naitajad($1::INTEGER, $3::DATE, $4::TEXT, $5::TEXT, 0) d
                             INNER JOIN ou.rekv r ON r.id = d.rekvid
                    ORDER BY r.nimetus, d.liik, d.tyyp
        `,     // $1 - rekvid, $2 - user_id, $3 - seisuga, $4 - grupp_liik, $5 - koolituse_tyyp
        params: ['rekvid', 'userid', 'period', 'grupp_liik', 'tyyp'],
        min_params: 3,
        alias: 'aasta_naitajad_report',
        notReloadWithoutParameters: true
    },
    print: [
        {
            view: 'aasta_naitajad_tyyp_register',
            params: 'sqlWhere',
            group: 'asutus'
        },
    ],

};
