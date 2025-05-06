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

            {id: "lapse_nimi", name: "Lapse nimi", width: "30%"},
            {id: "lapse_isikukood", name: "Lapse IK", width: "20%", show: false},
            {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
            {id: "jaak", name: "Jääk", width: "10%", type: "number", interval: true},
            {id: "vanemate_jaak_kogus", name: "Vastutav isikute arv", width: "10%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "20%"},
        ],
        sqlString: `SELECT sum(qryReport.jaak) OVER (PARTITION BY qryReport.rekvid)                    AS jaak_group,
                           count(*) OVER ()                                                            AS rows_total,
                           qryReport.id,
                           qryReport.period,
                           qryReport.lapse_nimi,
                           qryReport.lapse_isikukood,
                           qryReport.viitenumber,
                           coalesce(qryReport.jaak, 0)::NUMERIC(14, 2)                                           AS jaak,
                           qryReport.vanemate_jaak_kogus as vanemate_jaak_kogus,
                           qryReport.rekvid,
                           $2                                                                          AS user_id,
                           r.nimetus::TEXT                                                             AS asutus
                    FROM lapsed.saldo_aruanne($1::INTEGER, $3::DATE) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    ORDER BY r.nimetus, lapse_nimi
        `,     // $1 - rekvid, $3 - kpv
        params: ['rekvid', 'userid', 'period'],
        min_params: 3,
        notReloadWithoutParameters: true,
        totals: ` sum(jaak) over() as jaak_total `,
        alias: 'saldo_aruanne'
    },
    print: [
        {
            view: 'saldo_aruanne_register',
            params: 'sqlWhere'
        },
    ],

};
