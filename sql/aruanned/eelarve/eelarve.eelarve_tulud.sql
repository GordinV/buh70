DROP FUNCTION IF EXISTS eelarve.eelarve_tulud( INTEGER, DATE, BOOLEAN, INTEGER );
DROP FUNCTION IF EXISTS eelarve.eelarve_tulud( INTEGER, DATE, DATE, BOOLEAN, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.eelarve_tulud(l_aasta  INTEGER, l_kpv1 DATE, l_kpv2 DATE, is_parandus BOOLEAN,
                                                 l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    rekv_id  INTEGER,
    eelarve  NUMERIC(14, 2),
    kassa    NUMERIC(14, 2),
    tegelik  NUMERIC(14, 2),
    artikkel VARCHAR(20),
    allikas  VARCHAR(20),
    tegev    VARCHAR(20),
    tunnus   VARCHAR(20)
  ) AS
$BODY$
SELECT
  rekvid,
  sum(eelarve) AS eelarve,
  sum(kassa)   AS kassa,
  sum(tegelik) AS tegelik,
  artikkel,
  allikas,
  tegev,
  tunnus
FROM (
       SELECT
         rekvid,
         summa        AS eelarve,
         0 :: NUMERIC AS tegelik,
         0 :: NUMERIC AS kassa,
         kood1        AS tegev,
         kood2        AS allikas,
         kood5        AS artikkel,
         tunnus
       FROM eelarve.tulud e
       WHERE
         rekvid = (CASE WHEN l_kond = 1
           THEN rekvid
                   ELSE l_rekvid END)
         AND e.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
         AND aasta = l_aasta
         AND (empty(is_parandus) OR (e.kpv IS NULL OR e.kpv <= l_kpv2))
       UNION ALL
       SELECT
         rekvid,
         0 :: NUMERIC AS eelarve,
         summa        AS tegelik,
         0 :: NUMERIC AS kassa,
         tegev,
         allikas,
         artikkel,
         tunnus
       FROM cur_tulude_taitmine ft
       WHERE
         rekvid = (CASE WHEN l_kond = 1
           THEN rekvid
                   ELSE l_rekvid END)
         AND ft.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
         AND ft.aasta = l_aasta
         AND ft.kuu >= MONTH(l_kpv1)
         AND ft.kuu <= MONTH(l_kpv2)
       UNION ALL
       SELECT
         rekvid,
         0 :: NUMERIC AS eelarve,
         0 :: NUMERIC AS tegelik,
         summa        AS kassa,
         tegev,
         allikas,
         artikkel,
         tunnus
       FROM cur_tulude_kassa_taitmine kt
       WHERE
         rekvid = (CASE WHEN l_kond = 1
           THEN rekvid
                   ELSE l_rekvid END)
         AND kt.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
         AND kt.aasta = l_aasta
         AND kt.kuu >= MONTH(l_kpv1)
         AND kt.kuu <= MONTH(l_kpv2)
     ) qry
GROUP BY rekvid, tegev, allikas, artikkel, tunnus;

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

SELECT *
FROM eelarve.eelarve_tulud(2018, '2018-01-01', '2018-09-01', TRUE, 1, 0)

