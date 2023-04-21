module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "1%", show: false, type: "date", interval: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "7%"},
            {id: "lapse_isikukood", name: "Lapse IK", width: "0%", show: false},
            {id: "viitenumber", name: "Viitenumber", width: "7%", show: true},
            {id: "jaak", name: "Võlg", width: "5%", type: "number", interval: true},
            {id: "jaak", name: "Jääk", width: "5%", type: "number", show: false},
            {
                id: "asutuste_count",
                name: "Asutuste arv(jääk<>0) ",
                width: "5%",
                type: "number",
                show: true,
                interval: true
            },
            {
                id: "lasteaed_count",
                name: "Lasteaede arv(jääk<>0) ",
                width: "5%",
                type: "number",
                show: true,
                interval: true
            },
            {id: "asutus", name: "Asutus", width: "8%"},
        ],
        sqlString: `select * from (
                    with lasteaeds as (
                        select id, coalesce((properties->>'liik')::TEXT,'MUUD') as liik from ou.rekv where parentid = 119 
                    ),
                    qryReport as (
                        select * ,
                            case when r.rekvid in  (select id from lasteaeds WHERE liik = 'LASTEAED') and jaak <> 0 then 1 else 0 end as lasteaed_count,
                            case when r.rekvid in  (select id from lasteaeds) and jaak <> 0 then 1 else 0 end as asutuste_count
                            FROM lapsed.kaive_aruanne($1::INTEGER, $3, $4) r
                    )
                    SELECT sum(qryReport.jaak) OVER (PARTITION BY lapse_isikukood)            AS jaak_group,
                           count(*) OVER ()                                                   AS rows_total,
                           sum(lasteaed_count) OVER (PARTITION BY lapse_isikukood)            AS lasteaed_count,
                           sum(asutuste_count) OVER (PARTITION BY lapse_isikukood)            AS asutuste_count,
                           qryReport.id,
                           qryReport.period,
                           qryReport.lapse_nimi,
                           qryReport.lapse_isikukood,
                           qryReport.viitenumber,
                           coalesce(qryReport.jaak, 0)::NUMERIC(14, 2)                                  AS jaak,
                           qryReport.rekvid,
                           $2                                                                 AS user_id,
                           r.nimetus::TEXT                                                    AS asutus
                    FROM qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    ) rep
                    where rep.asutuste_count > 1
                    ORDER BY rep.lapse_isikukood, rep.asutus            
        `,     // $1 - rekvid, $3 - alg_kpv, $4 - lopp_kpv
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        min_params: 2,
        totals: `sum(jaak) over() as jaak_total `,
        alias: 'saldod_asutustes',
        notReloadWithoutParameters: true
    },
    print: [
        {
            view: 'saldod_asutustes',
            params: 'sqlWhere',
            group: 'lapse_isikukood',
            converter: function (data) {
                let row_id = 0;

                return data.map(row => {
                    row_id++;
                    row.row_id = row_id;
                    return row;
                })
            }
        },
    ],

};
