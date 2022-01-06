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
                            ltrim(rtrim(r.nimetus)))::VARCHAR(254)       AS asutus,
                           qryReport.tunnus,
                           qryReport.tegev,
                           coalesce(t.nimetus, '')::VARCHAR(254)         AS tegev_nimetus,
                           coalesce(qryReport.artikkel, '')::VARCHAR(20) AS artikkel,
                           coalesce(a.nimetus, '')::VARCHAR(254)         AS nimetus,
                           qryReport.aasta_1_tekke_taitmine,
                           qryReport.eelarve_tekkepohine_kinnitatud,
                           qryReport.eelarve_tekkepohine_tapsustatud,
                           qryReport.aasta_2_tekke_taitmine,
                           qryReport.aasta_3_eelnou,
                           qryReport.aasta_3_prognoos,
                           qryReport.selg                                AS selg
                    FROM eelarve.tulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER) qryReport
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus
                                         WHERE $3::INTEGER = 1
                                         UNION ALL
                                         SELECT 0 AS id, 0 AS parentid, r.regkood, r.nimetus
                                         FROM ou.rekv r
                                         WHERE r.id = $2
                                           AND $3::INTEGER = 1
                    ) r
                                        ON r.id = qryReport.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON r.parentid = p.id
                             LEFT OUTER JOIN (SELECT id, kood, nimetus
                                              FROM libs.library a
                                              WHERE library = 'TULUDEALLIKAD'
                                                AND status < 3) a
                                             ON a.kood = qryReport.artikkel
                             LEFT OUTER JOIN (SELECT id, kood, nimetus
                                              FROM libs.library
                                              WHERE library = 'TEGEV'
                                                AND status < 3
                                              UNION ALL
                                              SELECT id, kood, nimetus
                                              FROM cur_tegev_kond
                    ) t
                                             ON trim(t.kood)::TEXT = trim(qryReport.tegev)::TEXT


                    ORDER BY CASE WHEN r.id > 999 THEN 0 WHEN r.id = $2 THEN 1 ELSE r.id END, r.parentid,
                             qryReport.rekv_id, qryReport.tegev, qryReport.tunnus, qryReport.artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'tulud_eelnou'
    }
};
