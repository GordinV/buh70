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
            SELECT qry.rekv_id,
                   qry.idx,
                   qry.artikkel,
                   sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                   sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                   sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                   sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                   sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                   sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                   sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
            FROM eelarve.kulud_eelnou($1::DATE, $2::INTEGER, $3::INTEGER, $4::JSONB) qry
            where artikkel <> ''
            GROUP BY qry.rekv_id, qry.idx, qry.artikkel
        ),        
        preReport AS (
         SELECT qry.rekv_id,
                qry.idx,
                qry.artikkel,
                qry.aasta_1_tekke_taitmine          AS aasta_1_tekke_taitmine,
                qry.aasta_2_tekke_taitmine          AS aasta_2_tekke_taitmine,
                qry.aasta_2_oodatav_taitmine        AS aasta_2_oodatav_taitmine,
                qry.aasta_3_eelnou                  AS aasta_3_eelnou,
                qry.aasta_3_prognoos                AS aasta_3_prognoos,
                qry.eelarve_tekkepohine_kinnitatud  AS eelarve_tekkepohine_kinnitatud,
                qry.eelarve_tekkepohine_tapsustatud AS eelarve_tekkepohine_tapsustatud
         FROM report qry
         UNION ALL
           SELECT qry.rekv_id,
                  80                                       AS idx,
                  'ANTUD TOETUSED'                                     AS artikkel,
                  sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                  sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                  sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                  sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                  sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                  sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                  sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
           FROM Report qry
           WHERE (idx = 100) or artikkel in ('4500','452')
           GROUP BY qry.rekv_id
           UNION ALL
         SELECT qry.rekv_id,
                90                                       AS idx,
                '41'                                     AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM Report qry
         WHERE idx = 100
         GROUP BY qry.rekv_id
           UNION ALL
           SELECT qry.rekv_id,
                  380                                      AS idx,
                  'MUUD TEGEVUSKULUD'                      AS artikkel,
                  sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                  sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                  sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                  sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                  sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                  sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                  sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
           FROM Report qry
           WHERE idx IN (400, 500, 600)
           GROUP BY qry.rekv_id
         UNION ALL         
         SELECT qry.rekv_id,
                390                                      AS idx,
                '50'                                     AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM Report qry
         WHERE idx = 400
         GROUP BY qry.rekv_id
         UNION ALL
         SELECT qry.rekv_id,
                490                                      AS idx,
                '55'                                     AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM Report qry
         WHERE idx = 500
         GROUP BY qry.rekv_id
         UNION ALL
         SELECT qry.rekv_id,
                590                                      AS idx,
                '60'                                     AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM Report qry
         WHERE idx = 600
         GROUP BY qry.rekv_id
         UNION ALL
         SELECT qry.rekv_id,
                690                                      AS idx,
                '15'                                     AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM Report qry
         WHERE idx = 700
           AND artikkel LIKE '15%'         
         GROUP BY qry.rekv_id
         UNION ALL
         SELECT qry.rekv_id,
                680                                      AS idx,
                'INVESTEERIMISTEGEVUS'                   AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM Report qry
         WHERE (idx = 700)
            OR artikkel IN ('4502', '1501', '1511', '1531', '650')
         GROUP BY qry.rekv_id
         
     ),
     kokkuvotted as (
         SELECT qry.rekv_id,
                70                                      AS idx,
                'TEGEVUSKULUD KOKKU'                   AS artikkel,
                sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
         FROM preReport qry
         WHERE idx in (80, 380)
         GROUP BY qry.rekv_id
          UNION ALL
          SELECT qry.rekv_id,
                 60                                       AS idx,
                 'VÄLJAMINEKUD KOKKU'                     AS artikkel,
                 sum(qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                 sum(qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                 sum(qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                 sum(qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                 sum(qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                 sum(qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                 sum(qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud
          FROM preReport qry
          WHERE idx IN (80, 380, 680, 790)
          GROUP BY qry.rekv_id
        
     )
        SELECT qryReport.rekv_id,
               qryReport.idx,
               case when a.nimetus is null then '' else artikkel end as artikkel,
               aasta_1_tekke_taitmine                             AS aasta_1_tekke_taitmine,
               aasta_2_tekke_taitmine                             AS aasta_2_tekke_taitmine,
               aasta_2_oodatav_taitmine                           AS aasta_2_oodatav_taitmine,
               aasta_3_eelnou                                     AS aasta_3_eelnou,
               aasta_3_prognoos                                   AS aasta_3_prognoos,
               eelarve_tekkepohine_kinnitatud                     AS eelarve_tekkepohine_kinnitatud,
               eelarve_tekkepohine_tapsustatud                    AS eelarve_tekkepohine_tapsustatud,
               coalesce(a.nimetus, qryReport.artikkel)            AS nimetus,
                CASE WHEN r.parentid NOT IN (0, 63) THEN ltrim(rtrim(r.nimetus)) ELSE '' END ::VARCHAR(254) AS asutus,
                        CASE
                            WHEN r.parentid IN (0, 63) THEN coalesce(ltrim(rtrim(r.nimetus)), '')
                            WHEN r.parentid not IN (0, 63) THEN coalesce(ltrim(rtrim(p.nimetus)), '')
                            ELSE '' END::VARCHAR(254)                                                               AS parent_asutus
                   
        FROM (
             SELECT *
             FROM preReport
             UNION ALL
             SELECT *
             FROM kokkuvotted
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
                 LEFT OUTER JOIN ou.rekv p ON p.id = r.parentid
                  LEFT OUTER JOIN libs.library a
                            ON a.kood = qryReport.artikkel
                                AND a.library = 'TULUDEALLIKAD' AND a.status < 3
        ORDER BY CASE WHEN r.id > 999 THEN 0 WHEN r.id = $2 THEN 1 ELSE r.id END, r.parentid, r.nimetus, qryReport.idx,
                 qryReport.artikkel`,     // $1 - kpv $2 - rekvid, $3 - kond
        params: '',
        alias: 'kulud_eelnou'
    }
};