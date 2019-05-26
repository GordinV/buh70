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
        sqlString: `SELECT aasta,
                           kuu,
                           konto,
                           tp,
                           tegev,
                           allikas,
                           rahavoo,
                           db,
                           kr,
                           saldoandmik.nimetus,
                           rekv.nimetus AS asutus
                    FROM eelarve.saldoandmik saldoandmik
                             INNER JOIN ou.rekv rekv ON saldoandmik.rekvid = rekv.id
                    WHERE rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur($1))
                    AND aasta = $2 
                    AND kuu = $3
                    AND (1 = $4 or rekvid = $1)
                    ORDER BY konto, tp, tegev, allikas, rahavoo`,     // $1 - rekvid , $2 - aasta $3 - kuu, $4 kond (1)
        params: '',
        alias: 'paring_report'
    }
};
