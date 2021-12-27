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
        sqlString: `SELECT (ltrim(rtrim(CASE
                                            WHEN p.id = r.id THEN ''
                                            WHEN r.id = 999999 THEN ''
                                            ELSE coalesce(p.nimetus, '') END)) || ' ' ||
                            ltrim(rtrim(r.nimetus)))::VARCHAR(254) AS asutus,
                           qryReport.tunnus,
                           qryReport.tegev,
                           coalesce(t.nimetus, '')::VARCHAR(254)   AS tegev_nimetus,
                           qryReport.artikkel,
                           a.nimetus,
                           qryReport.aasta_1_tekke_taitmine,
                           qryReport.eelarve_tekkepohine_kinnitatud,
                           qryReport.eelarve_tekkepohine_tapsustatud,
                           qryReport.aasta_2_tekke_taitmine,
                           qryReport.aasta_3_eelnou,
                           qryReport.aasta_3_prognoos,
                           qryReport.selg::VARCHAR(254)
                    FROM eelarve.tulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER) qryReport
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus
                                         WHERE $3::INTEGER = 1
                    ) r
                                        ON r.id = qryReport.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id
                             INNER JOIN libs.library a
                                        ON a.kood = qryReport.artikkel
                                            AND a.library = 'TULUDEALLIKAD' AND a.status < 3
                             LEFT OUTER JOIN libs.library t ON t.kood = qryReport.tegev
                        AND t.library = 'TEGEV' AND a.status < 3

                    ORDER BY r.id DESC, r.parentid, qryReport.rekv_id, qryReport.idx,
                             qryReport.tegev, qryReport.artikkel, qryReport.tunnus`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'tulud_eelnou'
    }
};
