module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_saldo", name: "Alg. saldo", width: "100px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp saldo", width: "100px"},
            {id: "asutus", name: "Asutus", width: "200px"}
        ],
        sqlString: `SELECT
                      qry.rekv_id,
                      qry.asutus_id,
                      qry.konto,
                      l.nimetus,
                      qry.alg_saldo,
                      qry.deebet,
                      qry.kreedit,
                      (qry.alg_saldo + qry.deebet - qry.kreedit) as lopp_saldo,
                      a.regkood,
                      a.nimetus as asutus,
                      a.tp
                    FROM docs.kaibeasutusandmik($1::text, $2::integer, $3::date, $4::date, $5::integer, $6::text) qry
                      INNER JOIN com_asutused a on a.id = qry.asutus_id  
                      INNER JOIN com_kontoplaan l ON l.kood = qry.konto
                      WHERE (qry.alg_saldo <> 0 or qry.deebet <> 0 or qry.kreedit <> 0)
                      ORDER BY a.nimetus, qry.konto`,     // $1 - konto, $2 - asutus_id,$3 - kpv, $4- kpv2, $5 rekvid (svod), $6 tunnus
        params: '',
        alias: 'kaibeasutusandmik_report'
    }
};
