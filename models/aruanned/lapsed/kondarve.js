module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "0%", type: "date", interval: true, show: false},
            {id: "asutus", name: "Asutus", width: "30%"},
            {id: "konto", name: "Konto", width: "15%"},
            {id: "summa", name: "Summa", width: "15%", type: "number", interval: true}
        ],
        sqlString: `
            with report as (
                                    SELECT row_number() OVER ()                         AS row_id,
                                       d.rekvid,
                                       d.period,
                                       d.parameter,
                                       d.summa::NUMERIC(12, 2)                      AS summa,
                                       coalesce(d.summa_322000,0)::NUMERIC(12, 2)                      AS summa_322000,
                                       coalesce(d.summa_322020,0)::NUMERIC(12, 2)                      AS summa_322020,
                                       coalesce(d.summa_322030,0)::NUMERIC(12, 2)                      AS summa_322030,
                                       coalesce(d.summa_322040,0)::NUMERIC(12, 2)                      AS summa_322040,
                                       d.konto,
                                       d.nimetus::TEXT                              AS asutus,
                                       $2                                           AS user_id,
                                       to_char(current_date, 'DD.MM.YYYY HH:MI:SS') AS print_aeg
                                FROM lapsed.kondarve($1::INTEGER, $3::DATE, $4::DATE) d
                                ),
                         kond AS (
                             SELECT json_agg(kontod) AS kontod
                             FROM (
                                      SELECT jsonb_build_object('konto', konto, 'summa', sum(summa)) AS kontod
                                      FROM report
                                      GROUP BY konto) qry
                         )
                    SELECT report.*, kond.kontod
                    FROM report,
                         kond`,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        totals: ` sum(summa) over() as summa_total, 
        sum(summa_322000) over() as summa_322000_total,
        sum(summa_322020) over() as summa_322020_total,
        sum(summa_322030) over() as summa_322030_total,
        sum(summa_322040) over() as summa_322040_total`,
        notReloadWithoutParameters: true,
        alias: 'kondarve_report'
    },
    print: [
        {
            view: 'kondarve_register',
            params: 'sqlWhere'
        },
    ],

};
