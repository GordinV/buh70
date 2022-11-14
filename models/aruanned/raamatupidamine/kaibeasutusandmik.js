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
        sqlString: `SELECT qry.rekv_id,
                           qry.asutus_id,
                           qry.konto,
                           l.nimetus,
                           qry.alg_saldo,
                           qry.deebet,
                           qry.kreedit,
                           (qry.alg_saldo + qry.deebet - qry.kreedit) AS lopp_saldo,
                           coalesce(a.regkood, ''):: VARCHAR(20)      AS regkood,
                           coalesce(a.nimetus, '')::VARCHAR(254)      AS asutus,
                           coalesce(a.tp, '')::VARCHAR(20)            AS tp
                    FROM docs.kaibeasutusandmik($1::TEXT, $2::INTEGER, $3::DATE, $4::DATE, $5::INTEGER, $6::TEXT,
                                                $7::INTEGER, $8::jsonb) qry
                             LEFT OUTER JOIN com_asutused a ON a.id = qry.asutus_id
                             INNER JOIN com_kontoplaan l ON l.kood = qry.konto
                    WHERE (qry.alg_saldo <> 0 OR qry.deebet <> 0 OR qry.kreedit <> 0)
                    ORDER BY a.nimetus, qry.konto`,     // $1 - konto, $2 - asutus_id,$3 - kpv, $4- kpv2, $5 rekvid (svod), $6 tunnus, $7 kond, $8 params
        params: '',
        alias: 'kaibeasutusandmik_report'
    }
};
