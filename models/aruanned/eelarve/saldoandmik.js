module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `
            SELECT rekv_id,
                   sum(deebet)  AS deebet,
                   sum(kreedit) AS kreedit,
                   konto,
                   tp,
                   tegev,
                   allikas,
                   rahavoog,
                   artikkel
            FROM eelarve.saldoandmik_aruanne($1::DATE, $2::DATE, $3::INTEGER)
            GROUP BY rekv_id,
                     konto,
                     tp,
                     tegev,
                     allikas,
                     rahavoog,
                     artikkel
            ORDER BY konto, tp, tegev, allikas, rahavoog`,     // $1 - kpv1 $2 - kpv2, $3 - rekvid (svod)
        params: '',
        alias: 'saldoandmik_report'
    }
};
