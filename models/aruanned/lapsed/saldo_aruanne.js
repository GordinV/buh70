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

            {id: "lapse_nimi", name: "Lapse nimi", width: "20%"},
            {id: "lapse_isikukood", name: "Lapse IK", width: "10%", show: true},
            {id: "viitenumber", name: "Viitenumber", width: "7%", show: true},
            {id: "isiku_nimi", name: "Vastutava isiku nimi", width: "20%"},
            {id: "isiku_ik", name: "Vastutava IK", width: "10%", show: true},
            {id: "jaak", name: "Jääk", width: "7%", type: "number", interval: true},
            {id: "raamatu_jaak", name: "Vastutava isiku jääk", width: "7%", type: "number", interval: true},
            {id: "vanemate_jaak_kogus", name: "Vastutav isikute arv", width: "5%", type: "number", interval: true},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `SELECT
                        sum(qryReport.jaak) OVER (PARTITION BY qryReport.rekvid) AS jaak_group,
                        count(*) OVER ()                                         AS rows_total,
                        qryReport.id,
                        qryReport.period,
                        qryReport.lapse_nimi,
                        qryReport.lapse_isikukood,
                        qryReport.viitenumber,
                        qryReport.isiku_nimi,
                        qryReport.isiku_ik,
                        coalesce(qryReport.jaak, 0)::NUMERIC(14, 2)              AS jaak,
                        coalesce(qryReport.raamatu_jaak, 0)::NUMERIC(14, 2)      as raamatu_jaak,
                        qryReport.vanemate_jaak_kogus                            as vanemate_jaak_kogus,
                        qryReport.rekvid,
                        $2                                                       AS user_id,
                        r.nimetus::TEXT                                          AS asutus
                    FROM
                        lapsed.saldo_aruanne($1::INTEGER, $3::DATE) qryReport
                            INNER JOIN ou.rekv                      r ON r.id = qryReport.rekvid
                    ORDER BY
                        r.nimetus, lapse_isikukood, lapse_nimi, isiku_nimi
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
