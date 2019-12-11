module.exports = {
    grid: {
        gridConfiguration: [
            {id: "period", name: "Period", width: "0%", type: "date", interval: true, show: false},
            {id: "kood", name: "Kood", width: "15%"},
            {id: "asutus", name: "Asutus", width: "30%"},
            {id: "konto", name: "Konto", width: "15%"},
            {id: "summa", name: "Summa", width: "15%"}
        ],
        sqlString: `SELECT row_number() OVER ()                         AS row_id,
                           d.rekvid,
                           d.period,
                           d.parameter,
                           d.kood::TEXT                                 AS kood,
                           d.summa::NUMERIC(12, 2)                      AS summa,
                           d.konto,
                           r.nimetus::TEXT                              AS asutus,
                           $2                                           AS user_id,
                           to_char(current_date, 'DD.MM.YYYY HH:MM:SS') AS print_aeg
                    FROM lapsed.kondarve($1::INTEGER, $3::DATE, $4::DATE) d
                             INNER JOIN ou.rekv r ON r.id = d.rekvid
                    ORDER BY r.nimetus, d.kood
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'period_start', 'period_end'],
        alias: 'kondarve_report'
    },
    print: [
        {
            view: 'kondarve_register',
            params: 'sqlWhere'
        },
    ],

};
