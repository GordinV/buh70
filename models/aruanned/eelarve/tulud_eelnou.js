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
                    SELECT qryReport.rekv_id,
                           qryReport.idx,
                           qryReport.artikkel,
                           sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                           sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                           sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                           sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                           sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                           sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                           sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                    FROM eelarve.tulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER) qryReport
                                where artikkel <> ''
                    GROUP BY qryReport.rekv_id, qryReport.idx, qryReport.artikkel
                ),
              preReport AS (
                  SELECT qry.rekv_id,
                         qry.idx,
                         qry.artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  union all
                  SELECT qry.rekv_id,
                         90                                   AS idx,
                         upper('Maksud')                             AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 100
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  
                  UNION ALL
                  SELECT qry.rekv_id,
                         190                                  AS idx,
                         upper('Tulud kaupade ja teenuste müügist')  AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 200
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  UNION ALL
                  SELECT qry.rekv_id,
                         290                                  AS idx,
                         upper('Saadud toetused')                    AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 300
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  UNION ALL
                  SELECT qry.rekv_id,
                         390                                  AS idx,
                         upper('Muud tegevustulud')                  AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 400
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  UNION ALL
                  SELECT qry.rekv_id,
                         490                                  AS idx,
                         upper('Tulud investeerimistegevusest')      AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 500
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  UNION ALL
                  SELECT qry.rekv_id,
                         590                                  AS idx,
                         upper('Finanseerimistegevus')               AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 600
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel                                    
                  UNION ALL
                  SELECT qry.rekv_id,
                         690                                  AS idx,
                         upper('Likviidsete varade muutus')          AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM report qry
                  WHERE idx = 700
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  
              ),
                kokkuvotted AS (
                  SELECT qry.rekv_id,
                         80                                   AS idx,
                         upper('Põhitegevuse tulud kokku')           AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM prereport qry
                  WHERE idx IN (90, 190, 290, 390)
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
                  UNION ALL
                  SELECT qry.rekv_id,
                         710                                   AS idx,
                         'Omatulud'           AS artikkel,
                         sum(aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                         sum(aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                         sum(aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                         sum(aasta_3_eelnou)                  AS aasta_3_eelnou,
                         sum(aasta_3_prognoos)                AS aasta_3_prognoos,
                         sum(eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                         sum(eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
                  FROM prereport qry
                  WHERE artikkel IN ('3034','3044','3045','3047','3220','3221','3222','3224','3229','3232','3233','3237','3238','3880','3823','3818','3888','381','655')
                  GROUP BY qry.rekv_id, qry.idx, qry.artikkel
              )              
            SELECT qryReport.rekv_id,
                   qryReport.idx,
                   coalesce(a.kood, '')::VARCHAR(20)                  AS artikkel,
                   sum(aasta_1_tekke_taitmine)                        AS aasta_1_tekke_taitmine,
                   sum(aasta_2_tekke_taitmine)                        AS aasta_2_tekke_taitmine,
                   sum(aasta_2_oodatav_taitmine)                      AS aasta_2_oodatav_taitmine,
                   sum(aasta_3_eelnou)                                AS aasta_3_eelnou,
                   sum(aasta_3_prognoos)                              AS aasta_3_prognoos,
                   sum(eelarve_tekkepohine_kinnitatud)                AS eelarve_tekkepohine_kinnitatud,
                   sum(eelarve_tekkepohine_tapsustatud)               AS eelarve_tekkepohine_tapsustatud,
                   coalesce(a.nimetus, qryReport.artikkel)            AS nimetus,
                   r.regkood::VARCHAR(20),
                   coalesce(r.nimetus, '')::VARCHAR(254)              AS asutus,
                   CASE
                       WHEN p.id = r.id THEN ''
                       WHEN r.id = 999999 THEN ''
                       ELSE coalesce(p.nimetus, '') END::VARCHAR(254) AS parent_asutus
            FROM (SELECT *
               FROM preReport
               UNION ALL
               SELECT *
               FROM kokkuvotted) qryReport
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
                                ) r ON r.id = qryReport.rekv_id
                     LEFT OUTER JOIN ou.rekv p ON p.id = r.parentid
                     left outer JOIN libs.library a
                                ON a.kood = qryReport.artikkel
                                    AND a.library = 'TULUDEALLIKAD' AND a.status < 3
         GROUP BY r.id, r.parentid, r.regkood, r.nimetus, p.id, p.nimetus, qryReport.rekv_id, qryReport.idx,
                  coalesce(a.kood, ''), coalesce(a.nimetus, qryReport.artikkel)
            ORDER BY CASE WHEN r.id > 999 THEN 0 WHEN r.id = $2 THEN 1 ELSE r.id END, r.parentid, r.nimetus, qryReport.idx,coalesce(a.kood, '')`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'tulud_eelnou'
    }
};