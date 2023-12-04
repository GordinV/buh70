module.exports = {
    grid: {
        gridConfiguration: [
            {id: "maksja_nimi", name: "Maksja nimi", width: "15%", show: true},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "asutus", name: "Asutus", width: "15%"},
            {id: "number", name: "Dok.number", width: "10%"},
            {id: "kpv", name: "Kuupäev", width: "8%", type: "date", interval: true},
            {id: "summa", name: "Summa", width: "7%", type: "number", interval: true},
            {id: "inf3_summa", name: "INF3 Summa", width: "7%", type: "number", interval: true},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer", show: false},
            {id: "markused", name: "Märkused", width: "10%"},
            {id: "kas_inf3", name: "Kas INF3 sisu", width: "10%", type: 'select', data: ['', 'JAH', 'EI']},
        ],
        sqlString: `SELECT summa::NUMERIC(12, 2)                                                     AS summa,
                           inf3_summa::NUMERIC(12, 2)                                                AS inf3_summa,
                           lapse_nimi,
                           lapse_isikukood,
                           maksja_nimi,
                           maksja_isikukood,
                           asutus,
                           CASE WHEN empty($3::TEXT) THEN year(current_date)::TEXT ELSE $3::TEXT END AS aasta,
                           number,
                           to_char(kpv, 'DD.MM.YYYY')                                                AS kpv,
                           markused,
                           $2                                                                        AS user_id,
                           CASE
                               WHEN qryReport.kas_inf3_liik IS NULL THEN NULL
                               WHEN qryReport.kas_inf3_liik IS NOT NULL AND qryReport.kas_inf3_liik::BOOLEAN THEN 'JAH'
                               ELSE 'EI' END::TEXT                                                   AS kas_inf3
                    FROM lapsed.inf3_analuus($1::INTEGER, $3::TEXT, $4::DATE, $5::DATE, $6::TEXT, $7::TEXT) qryReport
                    ORDER BY lapse_nimi, kpv, number
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'aasta', 'kpv_start', 'kpv_end', 'lapse_isikukood', 'maksja_isikukood'],
        min_params: 3,
        alias: 'inf3_report',
        notReloadWithoutParameters: true,
        totals: ` sum(summa) over() as summa_total`,
    },
    print: [
        {
            view: 'inf3_analuus',
            params: 'sqlWhere',

        }
    ],

};
