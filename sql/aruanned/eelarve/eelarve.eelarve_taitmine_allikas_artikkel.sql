--DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, BOOLEAN, INTEGER, INTEGER);
--DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(l_aasta INTEGER,
                                                                      l_kpv_1 DATE,
                                                                      l_kpv_2 DATE,
                                                                      l_rekvid INTEGER,
                                                                      l_kond INTEGER)
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
    ) AS
$BODY$
WITH cur_kulude_kassa_taitmine AS (
    SELECT * FROM eelarve.uus_kassa_taitmine(l_kpv_1, l_kpv_2, l_rekvid, l_kond)
),
     cur_kulude_taitmine AS (SELECT *
                             FROM eelarve.tekke_taitmine(l_kpv_1, l_kpv_2, l_rekvid, l_kond)),
     qryReport AS (
         SELECT rekvid,
                sum(eelarve_kinni)            AS eelarve_kinni,
                sum(eelarve_parandatud)       AS eelarve_parandatud,
                sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                sum(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                sum(tegelik)                  AS tegelik,
                sum(kassa)                    AS kassa,
                tegev,
                allikas,
                artikkel,
                rahavoog,
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
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND e.kpv IS NULL
                    AND kood5 NOT LIKE '3%'
                    AND e.status <> 3
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
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND kood5 NOT LIKE '3%'
                    AND (e.kpv IS NULL OR e.kpv <= COALESCE(l_kpv_2, CURRENT_DATE))
                    AND e.status <> 3

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
                                           '655%') THEN 110
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
                  SELECT rekvid,
                         0 :: NUMERIC           AS eelarve_kinni,
                         0 :: NUMERIC           AS eelarve_parandatud,
                         0 :: NUMERIC           AS eelarve_kassa_kinni,
                         0 :: NUMERIC           AS eelarve_kassa_parandatud,
                         summa                  AS tegelik,
                         0 :: NUMERIC           AS kassa,
                         COALESCE(j.kood1, '')  AS tegev,
                         COALESCE(j.kood2, '')  AS allikas,
                         COALESCE('2586 ', '')  AS artikkel,
                         COALESCE(j.kood3, '')  AS rahavoog,
                         COALESCE(j.tunnus, '') AS tunnus,
                         210                    AS idx
                  FROM cur_journal j
                  WHERE j.rekvid = (CASE
                                        WHEN l_kond = 1
                                            THEN rekvid
                                        ELSE l_rekvid END)
                    AND j.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur(l_rekvid))
                    AND YEAR(j.kpv) = l_aasta
                    AND MONTH(j.kpv) <= MONTH(l_kpv_2)
                    AND j.kood5 IS NOT NULL
                    AND NOT empty(j.kood5)
                    AND ((LEFT(j.deebet, 3) = '208' AND j.kood3 = '06')
                      OR (LEFT(j.deebet, 3) = '258' AND j.kood3 = '06')
--             OR (left(j.deebet, 6) IN ('203620', '203630'))
                      )
              ) qry
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
                          '2586x'                       AS artikkel,
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
                   WHERE
                       /*((artikkel LIKE
                               '4%' OR artikkel LIKE
                                       '5%' OR (artikkel LIKE
                                                '6%' AND artikkel NOT LIKE
                                                         '655%') OR
                               artikkel LIKE
                               '15%')
                           OR (artikkel =
                               '2586' AND rahavoog =
                                          '06')
                           )
                         AND artikkel <> '1532'*/
                       idx >= 200
                     AND qryReport.artikkel <> '1532'
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
                       )
                   GROUP BY rekvid
     )
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

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER) TO dbvaatleja;

/*
SELECT *
FROM (
         SELECT *
         FROM eelarve.eelarve_taitmine_allikas_artikkel(2021::INTEGER, '2021-01-31'::DATE, 63, 1)
     ) qry
WHERE artikkel like '15,2586,4,5,6%'
or artikkel = '1532'
order by idx, artikkel
*/