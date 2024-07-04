--DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, BOOLEAN, INTEGER, INTEGER);
--DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(l_aasta INTEGER,
                                                                     l_kpv_1 DATE,
                                                                     l_kpv_2 DATE,
                                                                     l_rekvid INTEGER,
                                                                     l_kond INTEGER,
                                                                     l_params JSONB DEFAULT NULL)
    RETURNS TABLE (
        rekv_id                  INTEGER,
        eelarve_kinni            NUMERIC(14, 2),
        eelarve_parandatud       NUMERIC(14, 2),
        eelarve_kassa_kinni      NUMERIC(14, 2),
        eelarve_kassa_parandatud NUMERIC(14, 2),
        tegelik                  NUMERIC(14, 2),
        kassa                    NUMERIC(14, 2),
        tegev                    VARCHAR(20),
        allikas                  VARCHAR(20),
        artikkel                 VARCHAR(20),
        rahavoog                 VARCHAR(20),
        tunnus                   VARCHAR(20),
        idx                      INTEGER
    )
AS
$BODY$
WITH rekv_ids AS (
    SELECT rekv_id
    FROM get_asutuse_struktuur(l_rekvid)
    WHERE rekv_id = CASE
                        WHEN l_kond = 1
                            -- kond
                            THEN rekv_id
                        ELSE l_rekvid END
),
     cur_kulude_kassa_taitmine AS (
         SELECT *
         FROM eelarve.uus_kassa_taitmine(l_kpv_1, l_kpv_2, l_rekvid, l_kond) qry
         WHERE (l_params IS NULL OR coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.artikkel, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.allikas, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.rahavoog, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
--      AND qry.rekv_id <> 9 -- TP18510139, VB убрать из отчетов
     ),
     cur_kulude_taitmine AS (
         SELECT *
         FROM eelarve.tekke_taitmine(l_kpv_1, l_kpv_2, l_rekvid, l_kond) qry
         WHERE (l_params IS NULL OR
                coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.artikkel, '') ILIKE
                                    coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.allikas, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.rahavoog, '') ILIKE
                                    coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
/*         -- kontod
         WITH qryKontodKulud AS (
             SELECT l.kood, l.tun5
             FROM libs.library l
                      INNER JOIN
                  eelarve.fakt_kulud fakt_kulud
                  ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((fakt_kulud.kood) :: TEXT))))
             WHERE l.library = 'KONTOD'
               AND L.status <> 3
         ),
              qryArt AS (SELECT kood
                         FROM libs.library l
                         WHERE l.tun5 = 2 --kulud
                           AND l.library = 'TULUDEALLIKAD'
                           AND status < 3)

         SELECT rekvid     AS rekv_id,
                sum(summa) AS summa,
                tegev,
                allikas,
                artikkel,
                rahavoog,
                tunnus
         FROM (
                  -- расходы
                  SELECT sum(CASE
                                 WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01')
                                     THEN 0
                                 ELSE j1.summa END) AS summa,
                         j1.kood1                   AS tegev,
                         j1.kood2                   AS allikas,
                         j1.kood3                   AS rahavoog,
                         j1.kood5                   AS artikkel,
                         j1.tunnus,
                         j.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN qryKontodKulud k ON k.kood = j1.deebet
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id

                  WHERE coalesce(a.kpv, j.kpv) >= l_kpv_1
                    AND coalesce(a.kpv, j.kpv) <= l_kpv_2
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND j1.kood5 IN (SELECT kood FROM qryArt)
                    AND NOT empty(j1.kood5)
                  GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid

                  UNION ALL
                  -- востановление расходов
                  SELECT sum(-1 * (CASE
                                       WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01')
                                           THEN 0
                                       ELSE j1.summa END)) AS summa,
                         j1.kood1                          AS tegev,
                         j1.kood2                          AS allikas,
                         j1.kood3                          AS rahavoog,
                         j1.kood5                          AS artikkel,
                         j1.tunnus,
                         j.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN qryKontodKulud k ON k.kood = j1.kreedit
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                  WHERE coalesce(a.kpv, j.kpv) >= l_kpv_1
                    AND coalesce(a.kpv, j.kpv) <= l_kpv_2
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND j1.kood5 IN (SELECT kood FROM qryArt)
                    AND NOT empty(j1.kood5)
                  GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood5, j1.tunnus, j.rekvid
              ) qry
         WHERE NOT empty(artikkel)
           AND summa <> 0
           AND (l_params IS NULL OR
                coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.artikkel, '') ILIKE
                                    coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.allikas, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.rahavoog, '') ILIKE
                                    coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')

         GROUP BY rekvid, tegev, allikas, artikkel, tunnus, rahavoog
*/ ),
     qryReport AS (
         SELECT rekvid,
                sum(eelarve_kinni)            AS eelarve_kinni,
                sum(eelarve_parandatud)       AS eelarve_parandatud,
                sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                sum(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                sum(tegelik)                  AS tegelik,
                sum(kassa)                    AS kassa,
                COALESCE(tegev, '')           AS tegev,
                coalesce(allikas, '')         AS allikas,
                coalesce(artikkel, '')        AS artikkel,
                coalesce(rahavoog, '')        AS rahavoog,
                tunnus,
                idx
         FROM (
                  SELECT rekvid,
                         summa                           AS eelarve_kinni,
                         summa_kassa                     AS eelarve_kassa_kinni,
                         0:: NUMERIC                     AS eelarve_parandatud,
                         0:: NUMERIC                     AS eelarve_kassa_parandatud,
                         0 :: NUMERIC                    AS tegelik,
                         0 :: NUMERIC                    AS kassa,
                         kood1                           AS tegev,
                         kood2                           AS allikas,
                         kood5                           AS artikkel,
                         CASE
                             WHEN kood5 = '2586'
                                 AND kood2 LIKE 'LE%' THEN '06'
                             ELSE kood3 END::VARCHAR(20) AS rahavoog,
                         COALESCE(tunnus,
                                  '')                    AS tunnus,
                         210                             AS idx
                  FROM eelarve.kulud e
                  WHERE e.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND aasta = l_aasta
                    AND e.kpv IS NULL
                    AND kood5 NOT LIKE '3%'
                    AND e.status <> 3
                    AND (l_params IS NULL OR
                         coalesce(e.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood1, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood5, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood2, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                    AND (l_params IS NULL OR coalesce((CASE
                                                           WHEN kood5 = '2586'
                                                               AND kood2 LIKE 'LE%' THEN '06'
                                                           ELSE kood3 END::VARCHAR(20)), '') ILIKE
                                             coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')

                  UNION ALL
                  SELECT rekvid,
                         0 :: NUMERIC                    AS eelarve_kinni,
                         0 :: NUMERIC                    AS eelarve_kassa_kinni,
                         summa                           AS eelarve_parandatud,
                         summa_kassa                     AS eelarve_kassa_parandatud,
                         0 :: NUMERIC                    AS tegelik,
                         0 :: NUMERIC                    AS kassa,
                         kood1                           AS tegev,
                         kood2                           AS allikas,
                         kood5                           AS artikkel,
                         CASE
                             WHEN kood5 =
                                  '2586' AND kood2 LIKE
                                             'LE%' THEN
                                 '06'
                             ELSE kood3 END::VARCHAR(20) AS rahavoog,
                         COALESCE(tunnus,
                                  '')                    AS tunnus,
                         210                             AS idx
                  FROM eelarve.kulud e
                  WHERE e.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND aasta = l_aasta
                    AND kood5 NOT LIKE '3%'
                    AND (e.kpv IS NULL OR e.kpv <= COALESCE(l_kpv_2, CURRENT_DATE))
                    AND e.status <> 3
                    AND (l_params IS NULL OR
                         coalesce(e.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood1, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood5, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood2, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                    AND (l_params IS NULL OR coalesce((CASE
                                                           WHEN kood5 = '2586'
                                                               AND kood2 LIKE 'LE%' THEN '06'
                                                           ELSE kood3 END::VARCHAR(20)), '') ILIKE
                                             coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')

                  UNION ALL
                  SELECT rekv_id          AS rekvid,
                         0 :: NUMERIC     AS eelarve_kinni,
                         0 :: NUMERIC     AS eelarve_parandatud,
                         0 :: NUMERIC     AS eelarve_kassa_kinni,
                         0 :: NUMERIC     AS eelarve_kassa_parandatud,
                         summa            AS tegelik,
                         0 :: NUMERIC     AS kassa,
                         COALESCE(tegev,
                                  '')     AS tegev,
                         COALESCE(allikas,
                                  '')     AS allikas,
                         COALESCE(artikkel,
                                  '')     AS artikkel,
                         COALESCE(rahavoog,
                                  '')     AS rahavoog,
                         COALESCE(tunnus,
                                  '')     AS tunnus,
                         CASE
                             WHEN (artikkel LIKE
                                   '3%' OR artikkel LIKE
                                           '655%') THEN 110
                             WHEN artikkel LIKE
                                  '4%' OR artikkel LIKE
                                          '5%' OR
                                  (artikkel LIKE
                                   '6%' AND artikkel NOT LIKE
                                            '655%') OR
                                  artikkel LIKE
                                  '15%' THEN 210
                             ELSE 200 END AS idx
                  FROM cur_kulude_taitmine ft
                  WHERE ft.artikkel <>
                        '2586'
                        -- Valentina B 24.10.2022
--                    AND CASE WHEN ft.artikkel = '4502' AND coalesce(ft.rahavoog = '24') THEN FALSE ELSE TRUE END
                  UNION ALL
                  SELECT kt.rekv_id       AS rekvid,
                         0 :: NUMERIC     AS eelarve_kinni,
                         0 :: NUMERIC     AS eelarve_parandatud,
                         0 :: NUMERIC     AS eelarve_kassa_kinni,
                         0 :: NUMERIC     AS eelarve_kassa_parandatud,
                         0 :: NUMERIC     AS tegelik,
                         summa            AS kassa,
                         tegev,
                         allikas,
                         artikkel,
                         rahavoog,
                         COALESCE(tunnus,
                                  '')     AS tunnus,
                         CASE
                             WHEN (artikkel LIKE
                                   '3%' OR artikkel LIKE
                                           '655%' OR ltrim(rtrim(artikkel)) = '2585') THEN 110
                             WHEN artikkel LIKE
                                  '4%' OR artikkel LIKE
                                          '5%' OR
                                  (artikkel LIKE
                                   '6%' AND artikkel NOT LIKE
                                            '655%') OR
                                  artikkel LIKE
                                  '15%' THEN 210
                             ELSE 200 END AS idx
                  FROM cur_kulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND NOT empty(kt.artikkel)
                    AND artikkel <> '2586'
                  UNION ALL
                  SELECT kt.rekv_id       AS rekvid,
                         0 :: NUMERIC     AS eelarve_kinni,
                         0 :: NUMERIC     AS eelarve_parandatud,
                         0 :: NUMERIC     AS eelarve_kassa_kinni,
                         0 :: NUMERIC     AS eelarve_kassa_parandatud,
                         0 :: NUMERIC     AS tegelik,
                         summa            AS kassa,
                         tegev,
                         allikas,
                         artikkel,
                         rahavoog,
                         COALESCE(tunnus,
                                  '')     AS tunnus,
                         CASE
                             WHEN (artikkel LIKE
                                   '3%' OR artikkel LIKE
                                           '655%' OR ltrim(rtrim(artikkel)) = '2585') THEN 110
                             WHEN artikkel LIKE
                                  '4%' OR artikkel LIKE
                                          '5%' OR
                                  (artikkel LIKE
                                   '6%' AND artikkel NOT LIKE
                                            '655%') OR
                                  artikkel LIKE
                                  '15%' THEN 210
                             ELSE 210 END AS idx
                  FROM cur_kulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND artikkel = '2586'
                    AND rahavoog = '06'
                  UNION ALL
                  SELECT kt.rekv_id   AS rekvid,
                         0 :: NUMERIC AS eelarve_kinni,
                         0 :: NUMERIC AS eelarve_parandatud,
                         0 :: NUMERIC AS eelarve_kassa_kinni,
                         0 :: NUMERIC AS eelarve_kassa_parandatud,
                         0 :: NUMERIC AS tegelik,
                         sum(summa)   AS kassa,
                         tegev,
                         allikas,
                         '2586',
                         rahavoog,
                         COALESCE(tunnus,
                                  '') AS tunnus,
                         100          AS idx
                  FROM cur_kulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND artikkel = '2586'
                    AND allikas = '80'
                  GROUP BY rekvid,
                           tegev,
                           allikas,
                           artikkel,
                           rahavoog,
                           tunnus
                  UNION ALL
                  SELECT d.rekvid,
                         0 :: NUMERIC            AS eelarve_kinni,
                         0 :: NUMERIC            AS eelarve_parandatud,
                         0 :: NUMERIC            AS eelarve_kassa_kinni,
                         0 :: NUMERIC            AS eelarve_kassa_parandatud,
                         sum(summa)              AS tegelik,
                         0 :: NUMERIC            AS kassa,
                         COALESCE(j1.kood1, '')  AS tegev,
                         COALESCE(j1.kood2, '')  AS allikas,
                         COALESCE('2586 ', '')   AS artikkel,
                         COALESCE(j1.kood3, '')  AS rahavoog,
                         COALESCE(j1.tunnus, '') AS tunnus,
                         210                     AS idx
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON D.id = j.parentid
                           INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                  WHERE d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status < 3
                    AND d.doc_type_id IN
                        (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
                        )
                    AND j.kpv < gomonth(make_date(l_aasta, MONTH(l_kpv_2), 1), 1)
                    AND j.kpv >= make_date(l_aasta, month(l_kpv_1), 1)
--                    AND YEAR(j.kpv) = l_aasta
                    AND j1.kood5 IS NOT NULL
                    AND NOT empty(j1.kood5)
                    AND ((LEFT(j1.deebet, 3) = '208' AND j1.kood3 = '06')
                      OR (LEFT(j1.deebet, 3) = '258' AND j1.kood3 = '06'))
                    AND (l_params IS NULL OR
                         coalesce(j1.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(j1.kood1, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(j1.kood5, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(j1.kood2, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(j1.kood3, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
                  GROUP BY d.rekvid, COALESCE(j1.kood1, ''),
                           COALESCE(j1.kood2, ''),
                           COALESCE(j1.kood3, ''),
                           COALESCE(j1.tunnus, '')
              ) qry
--         WHERE rekvid <> 9
         GROUP BY rekvid,
                  tegev,
                  allikas,
                  artikkel,
                  rahavoog,
                  tunnus,
                  idx
     ),

     preReport AS (SELECT rekvid,
                          sum(eelarve_kinni)                                AS eelarve_kinni,
                          sum(eelarve_parandatud)                           AS eelarve_parandatud,
                          sum(eelarve_kassa_kinni)                          AS eelarve_kassa_kinni,
                          SUM(eelarve_kassa_parandatud)                     AS eelarve_kassa_parandatud,
                          sum(tegelik)                                      AS tegelik,
                          sum(kassa)                                        AS kassa,
                          tegev,
                          allikas,
                          artikkel,
                          rahavoog,
                          tunnus,
                          CASE WHEN artikkel = '1532' THEN 110 ELSE idx END AS idx
                   FROM qryReport
                   GROUP BY rekvid,
                            tegev,
                            allikas,
                            artikkel,
                            rahavoog,
                            tunnus,
                            idx
                   UNION ALL
-- 2586 свод
                   SELECT rekvid,
                          sum(eelarve_kinni)            AS eelarve_kinni,
                          sum(eelarve_parandatud)       AS eelarve_parandatud,
                          sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                          SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                          sum(tegelik)                  AS tegelik,
                          sum(kassa)                    AS kassa,
                          ''                            AS tegev,
                          '80'                          AS allikas,
                          '2586(A80)'                   AS artikkel,
                          ''                            AS rahavoog,
                          ''                            AS tunnus,
                          095                           AS idx
                   FROM qryReport
                   WHERE artikkel = '2586'
                     AND allikas = '80'
                   GROUP BY rekvid
                   UNION ALL
                   -- Põhitegevuse kulud                  (здесь  art 2586 с RV 06, 4*, 5*, 6 )
                   SELECT rekvid,
                          sum(eelarve_kinni)            AS eelarve_kinni,
                          sum(eelarve_parandatud)       AS eelarve_parandatud,
                          sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                          SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                          sum(tegelik)                  AS tegelik,
                          sum(kassa)                    AS kassa,
                          ''                            AS tegev,
                          ''                            AS allikas,
                          '15,2586,4,5,6'               AS artikkel,
                          ''                            AS rahavoog,
                          ''                            AS tunnus,
                          200                           AS idx
                   FROM qryReport
                   WHERE idx >= 200
                     AND qryReport.artikkel NOT IN ('2585', '1532')
                   GROUP BY rekvid
                   UNION ALL
                   SELECT kt.rekvid    AS rekvid,
                          0 :: NUMERIC AS eelarve_kinni,
                          0 :: NUMERIC AS eelarve_parandatud,
                          0 :: NUMERIC AS eelarve_kassa_kinni,
                          0 :: NUMERIC AS eelarve_kassa_parandatud,
                          0 :: NUMERIC AS tegelik,
                          sum(kassa)   AS kassa,
                          ''           AS tegev,
                          ''           AS allikas,
                          '15, 3, 655' AS artikkel,
                          ''           AS rahavoog,
                          ''           AS tunnus,
                          110          AS idx
                   FROM qryReport kt
                   WHERE kt.artikkel IS NOT NULL
                     AND (artikkel LIKE '3%' OR artikkel LIKE '655%'
                       OR artikkel = '1532'
                       OR artikkel = '2585'
                       )
                   GROUP BY rekvid
     )
SELECT *
FROM (
         SELECT *
         FROM preReport
         UNION ALL
-- kond
         SELECT 999999,
                sum(eelarve_kinni)            AS eelarve_kinni,
                sum(eelarve_parandatud)       AS eelarve_parandatud,
                sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                sum(tegelik)                  AS tegelik,
                sum(kassa)                    AS kassa,
                tegev,
                allikas,
                artikkel,
                rahavoog,
                tunnus,
                idx
         FROM preReport
         WHERE l_kond > 0
         GROUP BY tegev,
                  allikas,
                  artikkel,
                  rahavoog,
                  tunnus,
                  idx
     ) qry
WHERE (eelarve_kinni <> 0 OR eelarve_parandatud <> 0 OR eelarve_kassa_kinni <> 0 OR
       eelarve_kassa_parandatud <> 0 OR tegelik <> 0 OR kassa <> 0)
  AND (CASE
           WHEN artikkel = '2586' AND allikas = '80' THEN TRUE
           WHEN artikkel = '2586' AND empty(rahavoog) THEN TRUE
           WHEN artikkel = '2586' AND rahavoog <> '06' THEN FALSE
           ELSE TRUE END) -- V.B. 13.02.2024


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER,JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB) TO dbvaatleja;

/*
--artikkel like
SELECT *
FROM (
         SELECT sum(kassa) over() as kassa_kokku,
*
         FROM eelarve.eelarve_taitmine_allikas_artikkel(2023::INTEGER,'2024-01-01'::date, '2024-03-31'::DATE, 119, 1)
where artikkel = '4500'
and tegev = '08203'

where rekv_id < 999
and artikkel in (select kood from com_artikkel where is_kulud)

     ) qry
WHERE artikkel = '4502'
'15,2586,4,5,6%'
*/