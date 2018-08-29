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
        sqlString: `SELECT
                      qry.rekv_id,
                      qry.asutus_id,
                      qry.konto,
                      l.nimetus,
                      qry.saldo,
                      a.regkood,
                      a.nimetus as asutus,
                      a.tp
                    FROM docs.kontosaldoandmik($1::text, $2::integer, $3::date, $4::integer) qry
                      INNER JOIN com_asutused a on a.id = qry.asutus_id  
                      INNER JOIN com_kontoplaan l ON l.kood = qry.konto
                      WHERE qry.saldo <> 0`,     // $1 - konto, $2 - asutus_id,$3 - kpv, $4- rekvid (svod)
        params: '',
        alias: 'kontosaldoandmik_report'
    }
};
