module.exports = {
    grid: {
        gridConfiguration: [
            {id: "maksja_nimi", name: "Maksja nimi", width: "25%", show: true},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "20%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "25%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "20%"},
            {id: "summa", name: "Summa", width: "10%", type: "number"},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
        ],
        sqlString: `SELECT sum(summa)::NUMERIC(12, 2) AS summa,
                           lapse_nimi,
                           lapse_isikukood,
                           maksja_nimi,
                           maksja_isikukood,
                           aasta,
                           3                          AS liik,
                           $2                         AS user_id
                    FROM lapsed.inf3($1::INTEGER, $3::INTEGER) qryReport
                    GROUP BY lapse_nimi, lapse_isikukood, maksja_nimi, maksja_isikukood, aasta
                    ORDER BY lapse_nimi
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'aasta'],
        min_params: 3,
        alias: 'inf3_report',
    },
    print: [
        {
            view: 'inf3_register',
            params: 'sqlWhere',
            converter: function (data) {
                let summa_kokku = 0;
                let row_id = 0;
                data.forEach(row => {
                    summa_kokku = summa_kokku + Number(row.summa);
                });

                return data.map(row => {
                    row_id++;
                    row.summa_kokku = summa_kokku;
                    row.row_id = row_id;
                    return row;
                })
            }

        }
    ],

};
