DROP FUNCTION IF EXISTS eelarve.eelarve_tulud( INTEGER, DATE, BOOLEAN, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.eelarve_tulud(l_aasta INTEGER, l_kpv DATE, is_parandus BOOLEAN, l_rekvid INTEGER)
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
  sum(tegelik) AS tegelik,
  sum(kassa)   AS kassa,
  tegev,
  allikas,
  artikkel,
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
       WHERE e.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
             AND aasta = l_aasta
             AND (empty(is_parandus) OR (e.kpv IS NULL OR e.kpv <= l_kpv))
       UNION ALL
       SELECT
         rekvid,
         0 :: NUMERIC AS eelarve,
         summa        AS tegelik,
         0 :: NUMERIC AS kassa ,
         tegev,
         allikas,
         artikkel,
         tunnus
       FROM cur_tulude_taitmine ft
       WHERE ft.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
             AND ft.aasta = l_aasta
             AND ft.kuu <= month(l_kpv)
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
       WHERE kt.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
             AND kt.aasta = l_aasta
             AND kt.kuu <= month(l_kpv)) qry
GROUP BY rekvid, tegev, allikas, artikkel, tunnus;

$BODY$
LANGUAGE SQL VOLATILE
COST 100;

SELECT *
FROM eelarve.eelarve_tulud(2018, '2018-01-01', TRUE, 1)

