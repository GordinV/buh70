DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine(l_aasta INTEGER, l_rekvid INTEGER, l_kond INTEGER );

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine(l_aasta INTEGER, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    rekv_id    INTEGER,
    tegev      VARCHAR(20),
    allikas    VARCHAR(20),
    artikkel   VARCHAR(20),
    eelarve_0  NUMERIC(14, 2),
    taitmine_0 NUMERIC(14, 2),
    eelarve_1  NUMERIC(14, 2),
    taitmine_1 NUMERIC(14, 2),
    eelarve_2  NUMERIC(14, 2),
    taitmine_2 NUMERIC(14, 2)

  ) AS
$BODY$
WITH qryEelarve AS (
    SELECT
      sum(eelarve)  AS eelarve,
      sum(taitmine) AS taitmine,
      rekvid,
      tegev,
      allikas,
      artikkel,
      aasta
    FROM (
           SELECT
             e.aasta,
             e.rekvid,
             e.summa      AS eelarve,
             0 :: NUMERIC AS taitmine,
             e.kood1      AS tegev,
             e.kood2      AS allikas,
             e.kood5      AS artikkel
           FROM eelarve.eelarve e
           WHERE aasta >= (l_aasta - 2)
                 AND e.rekvid = (CASE WHEN l_kond IS NULL OR empty(l_kond)
             THEN l_rekvid
                                 ELSE e.rekvid END)
                 AND e.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
             AND e.status <> 3           
           UNION ALL
           SELECT
             t.aasta,
             t.rekvid,
             0 :: NUMERIC AS eelare,
             t.summa      AS taitmine,
             t.kood1      AS tegev,
             t.kood2      AS allikas,
             t.kood5      AS artikkel
           FROM eelarve.eeltaitmine t
           WHERE aasta >= (l_aasta - 2)
                 AND t.rekvid = (CASE WHEN l_kond IS NULL OR empty(l_kond)
             THEN l_rekvid
                                 ELSE t.rekvid END)
                 AND t.rekvid IN (SELECT rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid))
         ) qry
    GROUP BY rekvid, aasta, tegev, allikas, artikkel
)
SELECT
  rekvid,
  tegev,
  allikas,
  artikkel,
  (CASE WHEN aasta = l_aasta
    THEN eelarve
   ELSE 0 END) AS eelarve_0,
  (CASE WHEN aasta = l_aasta
    THEN taitmine
   ELSE 0 END) AS taitmine_0,
  (CASE WHEN aasta = l_aasta - 1
    THEN eelarve
   ELSE 0 END) AS eelarve_1,
  (CASE WHEN aasta = l_aasta - 1
    THEN taitmine
   ELSE 0 END) AS taitmine_1,
  (CASE WHEN aasta = l_aasta - 2
    THEN eelarve
   ELSE 0 END) AS eelarve_2,
  (CASE WHEN aasta = l_aasta - 2
    THEN taitmine
   ELSE 0 END) AS taitmine_2
FROM qryEelarve
WHERE artikkel IS NOT NULL AND NOT empty(artikkel);
$BODY$
LANGUAGE SQL VOLATILE
COST 100;

/*
select *
from eelarve.eelarve_taitmine(2018, 63, 1)
*/