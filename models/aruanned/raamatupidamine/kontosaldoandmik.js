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
                           l.nimetus,
                           qry.saldo,
                           a.regkood,
                           a.nimetus                             AS asutus,
                           a.tp,
                           a.aadress,
                           ltrim(rtrim(r.nimetus))::VARCHAR(254) AS rekv_nimetus
                    FROM docs.kontosaldoandmik($1::TEXT, $2::INTEGER, $3::DATE, $4::INTEGER, $5::INTEGER, $6::jsonb) qry
                             INNER JOIN libs.asutus a ON a.id = qry.asutus_id
                             INNER JOIN com_kontoplaan l ON ltrim(rtrim(l.kood)) = ltrim(rtrim(qry.konto))
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus) r
                                        ON r.id = qry.rekv_id

                    WHERE qry.saldo <> 0
                    ORDER BY r.parentid, r.id DESC, qry.konto, a.nimetus`,     // $1 - konto, $2 - asutus_id,$3 - kpv, $4- rekvid, $5 - kond, $6 lisa params
        params: '',
        alias: 'kontosaldoandmik_report'
    }
};
