DROP FUNCTION IF EXISTS eelarve.eelarve_andmik(DATE, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.eelarve_andmik(l_kpv DATE,
                                                 l_rekvid INTEGER,
                                                 l_kond   INTEGER)
  RETURNS TABLE(
    rekv_id  INTEGER,
    tegev    VARCHAR(20),
    artikkel VARCHAR(20),
    eelarve  NUMERIC(14, 2),
    taitmine  NUMERIC(14, 2),
    sa  NUMERIC(14,2)
    ) AS
$BODY$
SELECT
  rekvid,
  tegev,
  artikkel,
  sum(eelarve)                                               AS eelarve,
  sum(tegelik)                                               AS tegelik,
  sum(kassa)                                                 AS kassa
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
       FROM eelarve.kulud e
       WHERE
           rekvid = (CASE WHEN l_kond = 1
                            THEN rekvid
                          ELSE l_rekvid END)
         AND e.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
         AND aasta = year(l_kpv)
         AND (empty(is_parandus) OR (e.kpv IS NULL OR e.kpv <= l_kpv))
       UNION ALL
       SELECT
         rekvid,
         0 :: NUMERIC           AS eelarve,
         summa                  AS tegelik,
         0 :: NUMERIC           AS kassa,
         COALESCE(tegev, '')    AS tegev,
         COALESCE(allikas, '')  AS allikas,
         COALESCE(artikkel, '') AS artikkel,
         COALESCE(tunnus, '')   AS tunnus
       FROM cur_kulude_taitmine ft
       WHERE
           ft.rekvid = (CASE WHEN l_kond = 1
                               THEN rekvid
                             ELSE l_rekvid END)
         AND ft.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
         AND ft.kuu <= MONTH(l_kpv)
         AND ft.artikkel IS NOT NULL AND NOT empty(ft.artikkel)
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
       FROM cur_kulude_kassa_taitmine kt
       WHERE
           kt.rekvid = (CASE WHEN l_kond = 1
                               THEN rekvid
                             ELSE l_rekvid END)

         AND kt.rekvid IN (SELECT rekv_id
                           FROM get_asutuse_struktuur(l_rekvid))
         AND kt.kuu <= MONTH(l_kpv)
         AND kt.artikkel IS NOT NULL AND NOT empty(kt.artikkel)
     ) qry
GROUP BY rekvid, tegev, allikas, artikkel, tunnus;

$BODY$
  LANGUAGE SQL VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik(DATE, INTEGER, INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik(DATE, INTEGER, INTEGER ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik(DATE, INTEGER, INTEGER ) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_andmik(DATE, INTEGER, INTEGER ) TO dbvaatleja;
/*
selec

SELECT *
FROM eelarve.eelarve_andmik(DATE(), 1, 0)

*/