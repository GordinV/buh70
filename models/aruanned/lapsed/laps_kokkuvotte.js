module.exports = {
    grid: {
        gridConfiguration: [
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%", filterValidation: true},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%", filterValidation: true},
            {id: "viitenumber", name: "Viitenumber", width: "10%"},
            {id: "number", name: "Arve nr", width: "10%"},
            {id: "kpv", name: "Kuupäev", width: "10%", type: "date", interval: true, filterValidation: true},
            {id: "summa", name: "Arve summa", width: "10%", type: "number", interval: true},
            {id: "tasutud", name: "Tasutud", width: "10%", type: "number", interval: true},
            {id: "maksesumma", name: "Maksesumma", width: "10%", type: "number", interval: true},
            {id: "maksekpv", name: "Maksekuupäev", width: "10%", type: "date", interval: true},
            {id: "mahakandmine", name: "Mahakantud", width: "10%", type: "number", interval: true},
            {id: "jaak", name: "Jääk", width: "10%", type: "number", interval: true},
            {id: "maksja_nimi", name: "Maksja nimi", width: "15%", show: true},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "10%"},
            {id: "asutus", name: "Asutus", width: "10%"},
        ],
        sqlString: `SELECT summa::NUMERIC(12, 2)                     AS summa,
                           number::TEXT                              AS number,
                           to_char(kpv, 'DD.MM.YYYY')::TEXT          AS kpv,
                           jaak::NUMERIC(12, 2)                      AS jaak,
                           tasutud::NUMERIC(12, 2)                   AS tasutud,
                           mahakandmine::NUMERIC(12, 2)              AS mahakandmine,
                           lapse_nimi,
                           lapse_isikukood,
                           viitenumber,
                           maksja_nimi,
                           maksja_isikukood,
                           r.nimetus                                 AS asutus,
                           to_char(current_date, 'DD.MM.YYYY')::TEXT AS print_date,
                           to_char(qryReport.maksekpv, 'DD.MM.YYYY') AS maksekpv,
                           qryReport.maksesumma
                    FROM lapsed.child_summary($1::INTEGER, 1, $2::TEXT, $3::TEXT, $4::DATE, $5::DATE) qryReport
                             INNER JOIN ou.rekv r ON r.id = qryReport.rekvid
                    ORDER BY lapse_nimi, r.nimetus, (kpv::DATE)
        `,     // $1 - rekvid, $3 - kond? removed jaak = 0
        params: ['rekvid', 'lapse_isikukood', 'lapse_nimi', 'kpv_start', 'kpv_end'],
        min_params: 3,
        notReloadWithoutParameters: true,
        alias: 'child_summary_report',
        subtotals: ['summa', 'jaak', 'tasutud', 'mahakandmine','maksesumma']

    },
    print: [
        {
            view: 'child_summary_register',
            params: 'sqlWhere',
            converter: function (data) {
                let summa_kokku = 0;
                let jaak_kokku = 0;
                let tasutud_kokku = 0;
                let mahakandmine_kokku = 0;
                let maksesumma_kokku = 0;
                let row_id = 0;
                data.forEach(row => {
                    summa_kokku = summa_kokku + Number(row.summa);
                    jaak_kokku = jaak_kokku + Number(row.jaak);
                    tasutud_kokku = tasutud_kokku + Number(row.tasutud);
                    mahakandmine_kokku = mahakandmine_kokku + Number(row.mahakandmine);
                    maksesumma_kokku = maksesumma_kokku + Number(row.maksesumma);
                });

                return data.map(row => {
                    row_id++;
                    row.summa_kokku = summa_kokku;
                    row.jaak_kokku = jaak_kokku;
                    row.tasutud_kokku = tasutud_kokku;
                    row.mahakandmine_kokku = mahakandmine_kokku;
                    row.maksesumma_kokku = maksesumma_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }
        },
    ],

};
