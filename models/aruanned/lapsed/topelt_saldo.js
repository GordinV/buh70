module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "1%", show: false, type: "date"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "20%"},
            {id: "lapse_isikukood", name: "Lapse IK", width: "10%", show: true},
            {id: "viitenumber", name: "Viitenumber", width: "10%", show: true},
            {id: "jaak", name: "Võlg", width: "5%", type: "number", interval: true},
            {id: "jaak", name: "Jääk", width: "5%", type: "number", show: false},
            {
                id: "lapse_asutused_count",
                name: "Asutuste arv ",
                width: "5%",
                type: "number",
                show: true,
                interval: true
            },
            {
                id: "lasteaja_asutuste_count",
                name: "Lasteaede arv (>1) ",
                width: "5%",
                type: "number",
                show: true,
                interval: true
            },
            {id: "asutus", name: "Asutus", width: "20%"},
        ],
        sqlString: `select *
                    from
                        (
                            with
                                lasteaeds as (
                                                 select
                                                     id,
                                                     coalesce((properties ->> 'liik')::TEXT, 'MUUD') as liik
                                                 from
                                                     ou.rekv
                                                 where
                                                     parentid = 119
                                             ),
                                qryReport as (
                                                 select *,
                                                        case
                                                            when r.rekvid in (
                                                                                 select
                                                                                     id
                                                                                 from
                                                                                     lasteaeds
                                                                                 where
                                                                                     liik = 'LASTEAED'
                                                                             ) and jaak <> 0 then 1
                                                            else 0 end as lasteaja_asutuste_count
                                                 FROM
                                                     lapsed.kaive_aruanne($1::INTEGER, $3::date, $3::date) r
                                             )
                            SELECT
                                sum(qryReport.jaak) OVER (PARTITION BY rekvid)                   AS jaak_group,
                                sum(qryReport.jaak_inf3) OVER (PARTITION BY rekvid)              AS jaak_inf3_group,
                                count(*) OVER ()                                                 AS rows_total,
                                sum(lasteaja_asutuste_count) OVER (PARTITION BY lapse_isikukood) AS lasteaja_asutuste_count,
                                count(1) OVER (PARTITION BY lapse_isikukood)                     AS lapse_asutused_count,
                                qryReport.id,
                                qryReport.period,
                                qryReport.lapse_nimi,
                                lapse_isikukood,
                                viitenumber,
                                coalesce(jaak, 0)::NUMERIC(14, 2)                                AS jaak,
                                coalesce(jaak_inf3, 0)::NUMERIC(14, 2)                           AS jaak_inf3,
                                rekvid,
                                $2                                                               AS user_id,
                                r.nimetus::TEXT                                                  AS asutus
                            FROM
                                qryReport
                                    INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                            where
                                  lasteaja_asutuste_count > 0
                              and qryReport.rekvid IN (
                                                          SELECT
                                                              rekv_id
                                                          FROM
                                                              get_asutuse_struktuur($1)
                                                      )

                            ORDER BY
                                lapse_isikukood,
                                r.nimetus
                        ) qry
                    where
                        qry.lapse_asutused_count > 1
        `,     // $1 - rekvid, $3 - seisuga
        params: ['rekvid', 'userid', 'period'],
        min_params: 2,
        totals: ` sum(jaak) over() as jaak_total `,
        alias: 'topelt_saldo_aruanne_report',
        notReloadWithoutParameters: true
    },
    print: [
        {
            view: 'topelt_saldo_register',
            params: 'sqlWhere'
        },
    ],

};
