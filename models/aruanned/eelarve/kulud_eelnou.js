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
        sqlString: `with preReport as (
                    SELECT qry.rekv_id,
                           qry.idx,
                           qry.artikkel,
                           sum(qry.aasta_1_tekke_taitmine)                        AS aasta_1_tekke_taitmine,
                           sum(qry.aasta_2_tekke_taitmine)                        AS aasta_2_tekke_taitmine,
                           sum(qry.aasta_2_oodatav_taitmine)                      AS aasta_2_oodatav_taitmine,
                           sum(qry.aasta_3_eelnou)                                AS aasta_3_eelnou,
                           sum(qry.aasta_3_prognoos)                              AS aasta_3_prognoos,
                           sum(qry.eelarve_tekkepohine_kinnitatud)                AS eelarve_tekkepohine_kinnitatud,
                           sum(qry.eelarve_tekkepohine_tapsustatud)               AS eelarve_tekkepohine_tapsustatud
                    FROM eelarve.kulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER, $4::JSONB) qry
                    group by qry.rekv_id, qry.idx, qry.artikkel
                    
                     ) 
                    SELECT qryReport.rekv_id,
                           qryReport.idx,
                           artikkel,
                           aasta_1_tekke_taitmine                        AS aasta_1_tekke_taitmine,
                           aasta_2_tekke_taitmine                        AS aasta_2_tekke_taitmine,
                           aasta_2_oodatav_taitmine                      AS aasta_2_oodatav_taitmine,
                           aasta_3_eelnou                                AS aasta_3_eelnou,
                           aasta_3_prognoos                              AS aasta_3_prognoos,
                           eelarve_tekkepohine_kinnitatud                AS eelarve_tekkepohine_kinnitatud,
                           eelarve_tekkepohine_tapsustatud               AS eelarve_tekkepohine_tapsustatud,
                           a.nimetus,
                           r.regkood::VARCHAR(20),
                           coalesce(r.nimetus, '')::VARCHAR(254)              AS asutus,
                           CASE
                               WHEN p.id = r.id THEN ''
                               WHEN r.id = 999999 THEN ''
                               ELSE coalesce(p.nimetus, '') END::VARCHAR(254) AS parent_asutus
                    FROM preReport as qryReport                                         
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
                             LEFT OUTER JOIN ou.rekv p ON p.id = r.parentid
                             INNER JOIN libs.library a
                                        ON a.kood = qryReport.artikkel
                                            AND a.library = 'TULUDEALLIKAD' AND a.status < 3
                    ORDER BY CASE WHEN r.id > 999 THEN 0 WHEN r.id = $2 THEN 1 ELSE r.id END, r.parentid, r.nimetus, qryReport.idx,
                             qryReport.artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'kulud_eelnou'
    }
};
