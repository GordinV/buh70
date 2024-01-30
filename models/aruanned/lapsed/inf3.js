module.exports = {
    grid: {
        gridConfiguration: [
            {id: "maksja_nimi", name: "Maksja nimi", width: "20%", show: false, filter: "not"},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "15%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "20%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "15%"},
            {id: "summa", name: "Summa", width: "10%", type: "number", interval: true},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer"},
            {id: "liik_name", name: "Liik", width: "10%", type: 'select', data: ['', 'LASTEAED', 'HUVIKOOL']},
        ],
        sqlString: `SELECT sum(summa)::NUMERIC(12, 2) AS summa,
                           lapse_nimi,
                           lapse_isikukood,
--                           maksja_nimi,
                           maksja_isikukood,
                           aasta,
                           liik                       AS liik,
                           case when liik = 1 then 'LASTEAED' else 'HUVIKOOL' end as liik_name,
                           $2                         AS user_id
                    FROM lapsed.inf3($1::INTEGER, $3::TEXT) qryReport
                    GROUP BY lapse_nimi, lapse_isikukood, maksja_isikukood, aasta, liik
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
