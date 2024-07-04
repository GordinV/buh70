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
        sqlString: `  SELECT coalesce(sum(deebet)
                                      FILTER (WHERE kpv IS NULL) OVER (
                                          PARTITION BY rekv_id, asutus_id, konto ), 0)::NUMERIC(14, 2) AS alg_saldo,
                             CASE
                                 WHEN kpv IS NOT NULL
                                     THEN deebet
                                 ELSE 0 END                                                            AS deebet,
                             kreedit,
                             coalesce(sum(deebet - kreedit)
                                      OVER (
                                          PARTITION BY rekv_id, asutus_id, konto ), 0)::NUMERIC(14, 2) AS lopp_saldo,
                             qryReport.kpv,
                             qryReport.rekv_id,
                             qryReport.asutus_id,
                             qryReport.konto::VARCHAR(20),
                             qryReport.korr_konto::VARCHAR(20),
                             qryReport.dok::VARCHAR(120),
                             qryReport.number::VARCHAR(20),
                             qryReport.kood1::VARCHAR(20),
                             qryReport.kood2::VARCHAR(20),
                             qryReport.kood3::VARCHAR(20),
                             qryReport.kood4::VARCHAR(20),
                             qryReport.kood5::VARCHAR(20),
                             qryReport.proj::VARCHAR(20),
                             qryReport.tunnus::VARCHAR(20),
                             qryReport.objekt::VARCHAR(20),
                             a.regkood::VARCHAR(20),
                             a.nimetus::VARCHAR(254)                                                   AS asutus,
                             a.tp::VARCHAR(20),
                             a.aadress,
                             l.nimetus::VARCHAR(254),
                             r.nimetus::VARCHAR(254)                                                   AS rekv_nimetus,
                             r.parentid
                      FROM docs.kontoasutusandmik($1::TEXT, $2 :: INTEGER, $3::DATE, $4 :: DATE, $5::INTEGER,
                                                  $6::JSONB) qryReport
                               INNER JOIN libs.asutus a ON a.id = qryReport.asutus_id
                               INNER JOIN com_kontoplaan l ON l.kood = qryReport.konto
                               INNER JOIN com_rekv r ON r.id = qryReport.rekv_id
                      WHERE qryReport.konto IS NOT NULL
                        AND qryReport.asutus_id IS NOT NULL
                      ORDER BY qryReport.rekv_id, qryReport.konto, a.nimetus, qryReport.kpv`,     // $1- konto, $2 - asutus_id, $3 - kpv1, $4 - kpv2, $5 - rekvid (svod),$6 - доп. параметры
        params: '',
        alias: 'kontoasutusandmik_report'
    }
};
