module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "alopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `SELECT *
                    FROM eelarve.eelarve_andmik_lisa_1_5($1::DATE, $2::INTEGER,
                                                         $3::INTEGER) where (not EMPTY(tegev) OR NOT empty(artikkel))
                        AND NOT (tegev IN (
                         '01800',
                         '09800') AND EMPTY(saldoandmik))
                    ORDER BY tegev, artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_andmik_lisa_1_5_report'
    },
    select: [
        {
            sql: `SELECT eelarve::text, eelarve_taps::text, selg::text
                  FROM eelarve.lisa1_lisa5_kontrol($1::TEXT, $2::JSON, $3::JSON)`,
            query: null,
            multiple: true,
            alias: 'kontrol',
            data: []

        }]
};
