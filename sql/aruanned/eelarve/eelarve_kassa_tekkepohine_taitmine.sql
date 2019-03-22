DROP FUNCTION IF EXISTS eelarve.eelarve_kassa_tekkepohine_taitmine(DATE, l_rekvid INTEGER, l_kond INTEGER);

CREATE OR REPLACE FUNCTION eelarve.eelarve_kassa_tekkepohine_taitmine(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    rekv_id INTEGER,
    tunnus VARCHAR(20),
    tegev VARCHAR(20),
    allikas VARCHAR(20),
    artikkel VARCHAR(20),
    eelarve_kinnitatud NUMERIC(14, 2),
    eelarve_tapsustatud NUMERIC(14, 2),
    taitmine_kassa NUMERIC(14, 2),
    taitmine_tekke NUMERIC(14, 2),
    is_kulud INTEGER
    ) AS
$BODY$
WITH qryEelarve AS (
  SELECT
    sum(eelarve_kinnitatud)  AS eelarve_kinnitatud,
    sum(eelarve_tapsustatud) AS eelarve_tapsustatud,
    sum(taitmine_kassa)      AS taitmine_kassa,
    sum(taitmine_tekke)      AS taitmine_tekke,
    rekvid,
    (tegev)                  AS tegev,
    (allikas)                AS allikas,
    (artikkel)               AS artikkel,
    (tunnus)                 AS tunnus,
    is_kulud
  FROM (
         SELECT
           e.rekvid,
           CASE WHEN empty(e.is_parandus) THEN e.summa ELSE 0 END AS eelarve_kinnitatud,
           e.summa                                                AS eelarve_tapsustatud,
           0 :: NUMERIC                                           AS taitmine_kassa,
           0 :: NUMERIC                                           AS taitmine_tekke,
           trim(e.kood1)                                          AS tegev,
           trim(e.kood2)                                          AS allikas,
           trim(e.kood5)                                          AS artikkel,
           trim(e.tunnus)                                         AS tunnus,
           e.is_kulud
         FROM eelarve.eelarve e
         WHERE aasta = year(l_kpv)
           AND e.rekvid = (CASE
                             WHEN l_kond IS NULL OR empty(l_kond)
                               THEN l_rekvid
                             ELSE e.rekvid END)
           AND e.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND empty(e.is_parandus)
         UNION ALL
           -- kassa tulud
         SELECT
           t.rekvid,
           0 :: NUMERIC     AS eelarve_kinnitatud,
           0 :: NUMERIC     AS eelarve_tapsustatud,
           t.summa          AS taitmine_kassa,
           0 :: NUMERIC     AS taitmine_tekke,
           trim(t.tegev)    AS tegev,
           trim(t.allikas)  AS allikas,
           trim(t.artikkel) AS artikkel,
           trim(t.tunnus)   AS tunnus,
           0                AS is_kulud
         FROM cur_tulude_kassa_taitmine t
         WHERE t.aasta = year(l_kpv)
           AND kuu <= month(l_kpv)
           AND t.rekvid = (CASE
                             WHEN l_kond IS NULL OR empty(l_kond)
                               THEN l_rekvid
                             ELSE t.rekvid END)
           AND t.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
         UNION ALL
           -- kassa kulud
         SELECT
           t.rekvid,
           0 :: NUMERIC     AS eelarve_kinnitatud,
           0 :: NUMERIC     AS eelarve_tapsustatud,
           t.summa          AS taitmine_kassa,
           0 :: NUMERIC     AS taitmine_tekke,
           trim(t.tegev)    AS tegev,
           trim(t.allikas)  AS allikas,
           trim(t.artikkel) AS artikkel,
           trim(t.tunnus)   AS tunnus,
           1                AS is_kulud
         FROM cur_kulude_kassa_taitmine t
         WHERE t.aasta = year(l_kpv)
           AND kuu <= month(l_kpv)
           AND t.rekvid = (CASE
                             WHEN l_kond IS NULL OR empty(l_kond)
                               THEN l_rekvid
                             ELSE t.rekvid END)
           AND t.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
         UNION ALL
           -- tekke tulud
         SELECT
           t.rekvid,
           0 :: NUMERIC     AS eelarve_kinnitatud,
           0 :: NUMERIC     AS eelarve_tapsustatud,
           0 :: NUMERIC     AS taitmine_kassa,
           t.summa          AS taitmine_tekke,
           trim(t.tegev)    AS tegev,
           trim(t.allikas)  AS allikas,
           trim(t.artikkel) AS artikkel,
           trim(t.tunnus)   AS tunnus,
           0                AS is_kulud
         FROM cur_tulude_taitmine t
         WHERE t.aasta = year(l_kpv)
           AND kuu <= month(l_kpv)
           AND t.rekvid = (CASE
                             WHEN l_kond IS NULL OR empty(l_kond)
                               THEN l_rekvid
                             ELSE t.rekvid END)
           AND t.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
         UNION ALL
           -- tekke kulud
         SELECT
           t.rekvid,
           0 :: NUMERIC     AS eelarve_kinnitatud,
           0 :: NUMERIC     AS eelarve_tapsustatud,
           0 :: NUMERIC     AS taitmine_kassa,
           t.summa          AS taitmine_tekke,
           trim(t.tegev)    AS tegev,
           trim(t.allikas)  AS allikas,
           trim(t.artikkel) AS artikkel,
           trim(t.tunnus)   AS tunnus,
           1                AS is_kulud
         FROM cur_kulude_taitmine t
         WHERE t.aasta = year(l_kpv)
           AND kuu <= month(l_kpv)
           AND t.rekvid = (CASE
                             WHEN l_kond IS NULL OR empty(l_kond)
                               THEN l_rekvid
                             ELSE t.rekvid END)
           AND t.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
       ) qry
  GROUP BY rekvid, tegev, allikas, artikkel, tunnus, is_kulud
)
SELECT
  rekvid,
  coalesce(tunnus, '')::VARCHAR(20)  AS tunnus,
  coalesce(tegev, '')::VARCHAR(20)   AS tegev,
  coalesce(allikas, '')::VARCHAR(20) AS allikas,
  artikkel,
  eelarve_kinnitatud::NUMERIC(14,2),
  eelarve_tapsustatud::NUMERIC(14,2),
  taitmine_kassa::NUMERIC(14,2),
  taitmine_tekke::NUMERIC(14,2),
  is_kulud
FROM qryEelarve
WHERE artikkel IS NOT NULL
  AND NOT empty(artikkel);
$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION eelarve.eelarve_kassa_tekkepohine_taitmine(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kassa_tekkepohine_taitmine(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kassa_tekkepohine_taitmine(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.eelarve_kassa_tekkepohine_taitmine(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;


/*
select *
from eelarve.eelarve_kassa_tekkepohine_taitmine('2018-12-31', 1, 1)
*/