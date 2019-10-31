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
                FROM eelarve.eelarve_andmik_lisa_1_5($1::date, $2::integer, $3::integer)
                where (not empty(tegev) or not empty(artikkel))
                and not (tegev in ('01800', '09800') and EMPTY(saldoandmik))
                order by tegev, artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'eelarve_andmik_lisa_1_5_report'
    }
};
