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
        sqlString: `SELECT sum(summa)::numeric(12,2) AS summa,
                           lapse_nimi,
                           lapse_isikukood,
                           maksja_nimi,
                           maksja_isikukood,
                           aasta,
                           3          AS liik,
                           $2         AS user_id
                    FROM lapsed.inf3($1::INTEGER, 1) qryReport
                    GROUP BY lapse_nimi, lapse_isikukood, maksja_nimi, maksja_isikukood, aasta
                    ORDER BY lapse_nimi
        `,     // $1 - rekvid, $3 - kond
        params: '',
        alias: 'inf3_report'
    },
    print: [
        {
            view: 'inf3_register',
            params: 'sqlWhere'
        },
    ],

};
