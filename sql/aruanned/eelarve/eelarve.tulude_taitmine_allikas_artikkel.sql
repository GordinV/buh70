DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, BOOLEAN, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tulude_taitmine_allikas_artikkel(l_aasta INTEGER,
                                                                    l_kpv DATE,
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
WITH cur_tulude_kassa_taitmine AS (
    SELECT * FROM eelarve.uus_kassa_tulu_taitmine(make_date(l_aasta, 01, 01), l_kpv, l_rekvid, l_kond)
),
     cur_tulude_taitmine AS (
         SELECT * FROM eelarve.tulu_taitmine(make_date(l_aasta, 01, 01), l_kpv, l_rekvid, l_kond)
     ),
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
                         summa        AS eelarve_kinni,
                         summa_kassa  AS eelarve_kassa_kinni,
                         0:: NUMERIC  AS eelarve_parandatud,
                         0:: NUMERIC  AS eelarve_kassa_parandatud,
                         0 :: NUMERIC AS tegelik,
                         0 :: NUMERIC AS kassa,
                         kood1        AS tegev,
                         kood2        AS allikas,
                         kood5        AS artikkel,
                         kood3        AS rahavoog,
                         COALESCE(tunnus,
                                  '') AS tunnus,
                         200          AS idx
                  FROM eelarve.tulud e
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND e.kpv IS NULL
                  UNION ALL
                  SELECT rekvid,
                         0 :: NUMERIC AS eelarve_kinni,
                         0 :: NUMERIC AS eelarve_kassa_kinni,
                         summa        AS eelarve_parandatud,
                         summa_kassa  AS eelarve_kassa_parandatud,
                         0 :: NUMERIC AS tegelik,
                         0 :: NUMERIC AS kassa,
                         kood1        AS tegev,
                         kood2        AS allikas,
                         kood5        AS artikkel,
                         kood3        AS rahavoog,
                         COALESCE(tunnus,
                                  '') AS tunnus,
                         200          AS idx
                  FROM eelarve.tulud e
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND (e.kpv IS NULL OR e.kpv <= COALESCE(l_kpv, CURRENT_DATE))
                  UNION ALL
                  SELECT rekv_id      AS rekvid,
                         0 :: NUMERIC AS eelarve_kinni,
                         0 :: NUMERIC AS eelarve_parandatud,
                         0 :: NUMERIC AS eelarve_kassa_kinni,
                         0 :: NUMERIC AS eelarve_kassa_parandatud,
                         summa        AS tegelik,
                         0 :: NUMERIC AS kassa,
                         COALESCE(tegev,
                                  '') AS tegev,
                         COALESCE(allikas,
                                  '') AS allikas,
                         COALESCE(artikkel,
                                  '') AS artikkel,
                         COALESCE(rahavoog,
                                  '') AS rahavoog,
                         COALESCE(tunnus,
                                  '') AS tunnus,
                         200          AS idx
                  FROM cur_tulude_taitmine ft
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
                         200  AS idx
                  FROM cur_tulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND NOT empty(kt.artikkel)
                  UNION ALL
                  -- Põhitegevuse tulud                  (здесь  art 2586 с RV 06, 4*, 5*, 6 )
                  SELECT kt.rekv_id   AS rekvid,
                         0 :: NUMERIC AS eelarve_kinni,
                         0 :: NUMERIC AS eelarve_parandatud,
                         0 :: NUMERIC AS eelarve_kassa_kinni,
                         0 :: NUMERIC AS eelarve_kassa_parandatud,
                         0 :: NUMERIC AS tegelik,
                         sum(summa)   AS kassa,
                         ''           AS tegev,
                         ''           AS allikas,
                         '3'          AS artikkel,
                         ''           AS rahavoog,
                         ''           AS tunnus,
                         200          AS idx
                  FROM cur_tulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND (artikkel LIKE '3%')
                  GROUP BY kt.rekv_id
                  UNION ALL
                  SELECT ft.rekv_id   AS rekvid,
                         0 :: NUMERIC AS eelarve_kinni,
                         0 :: NUMERIC AS eelarve_parandatud,
                         0 :: NUMERIC AS eelarve_kassa_kinni,
                         0 :: NUMERIC AS eelarve_kassa_parandatud,
                         sum(summa)   AS tegelik,
                         0 :: NUMERIC AS kassa,
                         ''           AS tegev,
                         ''           AS allikas,
                         '3'          AS artikkel,
                         ''           AS rahavoog,
                         ''           AS tunnus,
                         200          AS idx
                  FROM cur_tulude_taitmine ft
                  GROUP BY ft.rekv_id
                  UNION ALL
                  SELECT rekvid,
                         sum(summa)       AS eelarve_kinni,
                         sum(summa_kassa) AS eelarve_kassa_kinni,
                         0:: NUMERIC      AS eelarve_parandatud,
                         0:: NUMERIC      AS eelarve_kassa_parandatud,
                         0 :: NUMERIC     AS tegelik,
                         0 :: NUMERIC     AS kassa,
                         ''               AS tegev,
                         ''               AS allikas,
                         '3'              AS artikkel,
                         ''               AS rahavoog,
                         ''               AS tunnus,
                         200              AS idx
                  FROM eelarve.tulud e
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (
                      SELECT rekv_id
                      FROM get_asutuse_struktuur(l_rekvid
                               ))
                    AND aasta = l_aasta
                    AND e.kpv IS NULL
                  GROUP BY e.rekvid
                  UNION ALL
                  SELECT rekvid,
                         0 :: NUMERIC     AS eelarve_kinni,
                         0 :: NUMERIC     AS eelarve_kassa_kinni,
                         sum(summa)       AS eelarve_parandatud,
                         sum(summa_kassa) AS eelarve_kassa_parandatud,
                         0 :: NUMERIC     AS tegelik,
                         0 :: NUMERIC     AS kassa,
                         ''               AS tegev,
                         ''               AS allikas,
                         '3'              AS artikkel,
                         ''               AS rahavoog,
                         ''               AS tunnus,
                         200              AS idx
                  FROM eelarve.tulud e
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN
                        (SELECT rekv_id
                         FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND (e.kpv IS NULL OR e.kpv <= COALESCE(l_kpv, CURRENT_DATE))
                  GROUP BY e.rekvid
              ) qry
         GROUP BY rekvid,
                  tegev,
                  allikas,
                  artikkel,
                  rahavoog,
                  tunnus,
                  idx
     )
SELECT rekvid,
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
FROM qryReport
GROUP BY rekvid,
         tegev,
         allikas,
         artikkel,
         rahavoog,
         tunnus,
         idx
UNION ALL
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
FROM qryReport
WHERE l_kond > 0
GROUP BY tegev,
         allikas,
         artikkel,
         rahavoog,
         tunnus,
         idx;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER) TO dbvaatleja;


SELECT *
FROM eelarve.tulude_taitmine_allikas_artikkel(2020::INTEGER, '2020-03-31'::DATE, 119, 1)

