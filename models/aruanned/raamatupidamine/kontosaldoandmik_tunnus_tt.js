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
        sqlString: `SELECT qry.rekv_id,
                           qry.asutus_id,
                           qry.konto,
                           qry.tunnus,
                           qry.tegev,
                           l.nimetus,
                           qry.saldo,
                           a.regkood,
                           a.nimetus                                 AS asutus,
                           a.tp,
                           a.aadress,
                           sum(saldo) OVER ( PARTITION BY asutus_id) AS kond_saldo
                    FROM docs.kontosaldoandmik_tunnus_tt($1::TEXT, $2::INTEGER, $3::DATE, $4::INTEGER) qry
                             INNER JOIN libs.asutus a ON a.id = qry.asutus_id
                             INNER JOIN com_kontoplaan l ON l.kood = qry.konto
                    WHERE qry.saldo <> 0
                    ORDER BY qry.konto, a.nimetus`,     // $1 - konto, $2 - asutus_id,$3 - kpv, $4- rekvid (svod)
        params: '',
        alias: 'kontosaldoandmik_report'
    }
};
