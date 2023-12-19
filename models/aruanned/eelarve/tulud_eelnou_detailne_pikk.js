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
        sqlString: `WITH preReport AS (
                        SELECT * FROM eelarve.tulud_eelnou_pikk($1::DATE, $2::INTEGER, $3::INTEGER, $4::jsonb)
                    ),
         qryKond AS (
             SELECT rekv_id,
                ''                                   AS tunnus,
                '' as proj,
                '' as uritus,
                '01-10'                              AS tegev,
                ''                                   AS allikas,
                ''                                   AS artikkel,
                ''                                   as objekt,
                sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(aasta_2_oodatav_taitmine) as aasta_2_oodatav_taitmine,
                ''                                   AS selg
         FROM preReport
         WHERE left(tegev, 2) IN ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10')
         and len(ltrim(rtrim(tegev))) = 5         
         GROUP BY rekv_id
     ),
     qryReport AS (
         SELECT rekv_id,
                tunnus,
                proj,
                uritus,
                objekt,
                allikas,
                artikkel,
                tegev,
                aasta_1_tekke_taitmine,
                eelarve_tekkepohine_kinnitatud,
                eelarve_tekkepohine_tapsustatud,
                aasta_2_tekke_taitmine,
                aasta_3_eelnou,
                aasta_3_prognoos,
                aasta_2_oodatav_taitmine,
                coalesce(selg,'') as selg
         FROM preReport
             UNION ALL
         SELECT rekv_id,
                tunnus,
                proj,
                uritus,
                objekt,
                allikas,
                artikkel,
                tegev,
                aasta_1_tekke_taitmine,
                eelarve_tekkepohine_kinnitatud,
                eelarve_tekkepohine_tapsustatud,
                aasta_2_tekke_taitmine,
                aasta_3_eelnou,
                aasta_3_prognoos,
                aasta_2_oodatav_taitmine,
                selg
         FROM qryKond
     )

SELECT CASE WHEN r.parentid NOT IN (0, 63) THEN ltrim(rtrim(r.nimetus)) ELSE '' END ::VARCHAR(254) AS asutus,
       CASE
           WHEN r.parentid IN (0, 63) THEN coalesce(ltrim(rtrim(r.nimetus)), '')
           WHEN r.parentid NOT IN (0, 63) THEN coalesce(ltrim(rtrim(p.nimetus)), '')
           ELSE '' END::VARCHAR(254)                                                               AS parent_asutus,
           coalesce(qryReport.tunnus, '')::VARCHAR(20)                                                 AS tunnus,
           coalesce(qryReport.proj, '')::VARCHAR(20)                                                 AS proj,
           coalesce(qryReport.uritus, '')::VARCHAR(20)                                                 AS uritus,           
           coalesce(qryReport.objekt, '')::VARCHAR(20)                                                 AS objekt,           
           coalesce(qryReport.tegev, '')::VARCHAR(20)                                                  AS tegev,
           coalesce(t.nimetus, '')::VARCHAR(254)                                                       AS tegev_nimetus,
           coalesce(qryReport.allikas, '')::VARCHAR(20)                                                AS allikas,
           coalesce(qryReport.artikkel, '')::VARCHAR(20)                                               AS artikkel,
           coalesce(a.nimetus, '')::VARCHAR(254)                                                       AS nimetus,
           qryReport.aasta_1_tekke_taitmine,
           qryReport.eelarve_tekkepohine_kinnitatud,
           qryReport.eelarve_tekkepohine_tapsustatud,
           qryReport.aasta_2_tekke_taitmine,
           qryReport.aasta_3_eelnou,
           qryReport.aasta_3_prognoos,
           qryReport.aasta_2_oodatav_taitmine,
           qryReport.selg                                                                              AS selg
            FROM qryReport
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
                    ) r  ON r.id = qryReport.rekv_id
         LEFT OUTER JOIN (  SELECT *
                            FROM ou.rekv
                            WHERE parentid < 999
                              AND id <> 63
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

        WHERE CASE
                  WHEN qryReport.rekv_id > 999
                      AND (tegev IS NULL
                          OR empty(tegev)) THEN FALSE
                  ELSE TRUE END
        ORDER BY CASE WHEN r.id > 999 THEN 0 ELSE 1 END, 
            CASE WHEN r.parentid > 0 AND r.parentid <> 63 THEN '63-' else '' end + r.parentid::text + '-' + qryReport.rekv_id::TEXT, 
            CASE WHEN tegev = '01-10' then '0' ELSE qryReport.tegev END, qryReport.tunnus, qryReport.artikkel`,
        params: '',
        alias: 'tulud_eelnou'
    }
};
