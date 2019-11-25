module.exports = {
    grid: {
        gridConfiguration: [
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "20%"},
            {id: "number", name: "Arve nr", width: "10%"},
            {id: "kpv", name: "Kuupäev", width: "10%", type: "date"},
            {id: "summa", name: "Summa", width: "10%", type: "number"},
            {id: "jaak", name: "Jääk", width: "10%", type: "number"},
            {id: "maksja_nimi", name: "Maksja nimi", width: "20%", show: true},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "10%"},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `SELECT summa::NUMERIC(12, 2)               AS summa,
                           number::TEXT                        AS number,
                           to_char(kpv, 'DD.MM.YYYY')::TEXT    AS kpv,
                           jaak::NUMERIC(12, 2)                AS jaak,
                           lapse_nimi,
                           lapse_isikukood,
                           maksja_nimi,
                           maksja_isikukood,
                           r.nimetus                           AS asutus,
                           $2                                  AS user_id,
                           to_char(current_date, 'DD.MM.YYYY')::text AS print_date
                    FROM lapsed.child_summary($1::INTEGER, 1) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    WHERE qryReport.jaak <> 0
                    ORDER BY lapse_nimi, r.nimetus, kpv
        `,     // $1 - rekvid, $3 - kond
        params: '',
        alias: 'child_summary_report'
    },
    print: [
        {
            view: 'child_summary_register',
            params: 'sqlWhere'
        },
    ],

};
