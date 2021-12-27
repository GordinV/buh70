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
        sqlString: `SELECT qryReport.rekv_id,
                           qryReport.idx,
                           artikkel,
                           sum(aasta_1_tekke_taitmine)                        AS aasta_1_tekke_taitmine,
                           sum(aasta_2_tekke_taitmine)                        AS aasta_2_tekke_taitmine,
                           sum(aasta_2_oodatav_taitmine)                      AS aasta_2_oodatav_taitmine,
                           sum(aasta_3_eelnou)                                AS aasta_3_eelnou,
                           sum(aasta_3_prognoos)                              AS aasta_3_prognoos,
                           sum(eelarve_tekkepohine_kinnitatud)                AS eelarve_tekkepohine_kinnitatud,
                           sum(eelarve_tekkepohine_tapsustatud)               AS eelarve_tekkepohine_tapsustatud,
                           a.nimetus,
                           r.regkood::VARCHAR(20),
                           coalesce(r.nimetus, '')::VARCHAR(254)              AS asutus,
                           CASE
                               WHEN p.id = r.id THEN ''
                               WHEN r.id = 999999 THEN ''
                               ELSE coalesce(p.nimetus, '') END::VARCHAR(254) AS parent_asutus
                    FROM eelarve.tulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER) qryReport
                             INNER JOIN (SELECT id, parentid, regkood, nimetus
                                         FROM ou.rekv
                                         WHERE parentid < 999
                                         UNION ALL
                                         SELECT 999999, 0, '' AS regkood, 'Kond' AS nimetus
                                         WHERE $3::INTEGER = 1
                    ) r
                                        ON r.id = qryReport.rekv_id
                             LEFT OUTER JOIN ou.rekv p ON p.id = r.parentid
                             INNER JOIN libs.library a
                                        ON a.kood = qryReport.artikkel
                                            AND a.library = 'TULUDEALLIKAD' AND a.status < 3
                    GROUP BY r.id, r.parentid, r.regkood, r.nimetus, p.id, p.nimetus, qryReport.rekv_id, qryReport.idx,
                             qryReport.artikkel, a.nimetus
                    ORDER BY CASE WHEN r.id = 999999 THEN 0 ELSE 1 END, r.parentid, r.nimetus, qryReport.idx,
                             qryReport.artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'tulud_eelnou'
    }
};
