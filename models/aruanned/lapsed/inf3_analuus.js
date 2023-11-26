module.exports = {
    grid: {
        gridConfiguration: [
            {id: "maksja_nimi", name: "Maksja nimi", width: "15%", show: true},
            {id: "maksja_isikukood", name: "Maksja isikukood", width: "10%"},
            {id: "lapse_nimi", name: "Lapse nimi", width: "15%"},
            {id: "lapse_isikukood", name: "Lapse isikukood", width: "10%"},
            {id: "asutus", name: "Asutus", width: "15%"},
            {id: "number", name: "Dok.number", width: "10%"},
            {id: "kpv", name: "Kuupäev", width: "10%", type: "date"},
            {id: "summa", name: "Summa", width: "10%", type: "number"},
            {id: "aasta", name: "Aasta", width: "5%", type: "integer", show: false},
            {id: "markused", name: "Märkused", width: "10%"},
        ],
        sqlString: `SELECT summa::NUMERIC(12, 2) AS summa,
                           lapse_nimi,
                           lapse_isikukood,
                           maksja_nimi,
                           maksja_isikukood,
                           asutus,
                           case when empty($3::TEXT) then year(current_date)::text else $3::text end              AS aasta,
                           number,
                           to_char(kpv,'DD.MM.YYYY') as kpv,
                           summa,
                           markused,
                           $2                    AS user_id
                    FROM lapsed.inf3_analuus($1::INTEGER, $3::TEXT) qryReport
                    ORDER BY lapse_nimi, kpv, number
        `,     // $1 - rekvid, $3 - kond
        params: ['rekvid', 'userid', 'aasta'],
        min_params: 3,
        alias: 'inf3_report',
    },
    print: [
        {
            view: 'inf3_analuus',
            params: 'sqlWhere',

        }
    ],

};
