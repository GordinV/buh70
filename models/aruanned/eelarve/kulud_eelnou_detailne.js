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
        sqlString: `WITH report AS (
                SELECT qryReport.idx,
                       qryReport.rekv_id,
                       qryReport.tunnus,
                       qryReport.tegev,
                       qryReport.artikkel,
                       qryReport.aasta_1_tekke_taitmine,
                       qryReport.eelarve_tekkepohine_kinnitatud,
                       qryReport.eelarve_tekkepohine_tapsustatud,
                       qryReport.aasta_2_tekke_taitmine,
                       qryReport.aasta_3_eelnou,
                       qryReport.aasta_3_prognoos,
                       qryReport.selg AS selg
                FROM eelarve.kulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER, $4::jsonb) qryReport
                WHERE artikkel <> ''
            ),
                 TegevKond AS (
                     SELECT 0                                        AS idx,
                            rekv_id                                  AS rekv_id,
                            ''                                       AS tunnus,
                            left(qry.tegev, 2)::VARCHAR(20)          AS tegev,
                            ''                                       AS artikkel,
                            sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                            sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                            sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                            sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                            sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                            sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                            ''                                       AS selg
                     FROM report qry
                     WHERE NOT empty(qry.tegev)
                     GROUP BY qry.rekv_id, left(qry.tegev, 2)
                 )
            
            SELECT    CASE WHEN r.parentid NOT IN (0, 63) THEN ltrim(rtrim(r.nimetus)) ELSE '' END ::VARCHAR(254) AS asutus,
                        CASE
                            WHEN r.parentid IN (0, 63) THEN coalesce(ltrim(rtrim(r.nimetus)), '')
                            WHEN r.parentid not IN (0, 63) THEN coalesce(ltrim(rtrim(p.nimetus)), '')
                            ELSE '' END::VARCHAR(254)                                                               AS parent_asutus,
                   qryReport.tunnus,
                   qryReport.tegev,
                   coalesce(t.nimetus, '')::VARCHAR(254)         AS tegev_nimetus,
                   coalesce(qryReport.artikkel, '')::VARCHAR(20) AS artikkel,
                   coalesce(a.nimetus, '')::VARCHAR(254)         AS nimetus,
                   qryReport.aasta_1_tekke_taitmine,
                   qryReport.eelarve_tekkepohine_kinnitatud,
                   qryReport.eelarve_tekkepohine_tapsustatud,
                   qryReport.aasta_2_tekke_taitmine,
                   0::numeric(12,2) as aasta_3_oodatav,
                   qryReport.aasta_3_eelnou,
                   qryReport.aasta_3_prognoos,
                   coalesce(qryReport.selg,' ')                                AS selg
            FROM (SELECT *
                  FROM report
                  UNION ALL
                  SELECT *
                  FROM TegevKond
                 ) qryReport
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
                             LEFT OUTER JOIN (
                        SELECT *
                        FROM ou.rekv
                        WHERE parentid < 999 AND id <> 63
                    ) p ON r.parentid = p.id
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
        alias: 'kulud_eelnou'
    }
};