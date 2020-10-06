DROP FUNCTION IF EXISTS eelarve.lisa_2(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.lisa_2(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    rekv_id INTEGER,
    asutus VARCHAR(254),
    pohi_eelarve NUMERIC(14, 2),
    laen NUMERIC(14, 2),
    riigi_eelarve NUMERIC(14, 2),
    siht NUMERIC(14, 2),
    kokku NUMERIC(14, 2),
    taitmine NUMERIC(14, 2)
    ) AS
$BODY$

WITH qryTaitmine AS (
  SELECT
    sum(summa) AS summa,
    t.rekvid
  FROM cur_kulude_kassa_taitmine t
  WHERE t.rekvid = (CASE
                      WHEN l_kond = 1
                        THEN t.rekvid
                      ELSE l_rekvid END)
    AND t.rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid))
    AND t.allikas <> 'LE-RF'
    AND t.kuu <= month(l_kpv)
    AND t.aasta = year(l_kpv)
  GROUP BY t.rekvid
  UNION ALL
  SELECT
    sum(summa) AS summa,
    9999       AS rekvid
  FROM cur_kulude_kassa_taitmine t
  WHERE t.rekvid = (CASE
                      WHEN l_kond = 1
                        THEN t.rekvid
                      ELSE l_rekvid END)
    AND t.rekvid IN (SELECT rekv_id
                     FROM get_asutuse_struktuur(l_rekvid))
    AND t.allikas = 'LE-RF'
    AND t.kuu <= month(l_kpv)
    AND t.aasta = year(l_kpv)
)

SELECT
  qry.rekvid,
  qry.asutus,
  coalesce(qry.pohi_eelarve, 0)::NUMERIC  AS pohi_eelarve,
  coalesce(qry.laen, 0)::NUMERIC          AS laen,
  coalesce(qry.riigi_eelarve, 0)::NUMERIC AS riigi_eelarve,
  coalesce(qry.siht, 0)::NUMERIC          AS siht,
  coalesce(qry.kokku, 0)::NUMERIC         AS kokku,
  coalesce(qt.summa, 0)                   AS taitmine
FROM (
       SELECT
         t.rekvId,
         r.nimetus                                                                       AS asutus,
         coalesce(sum(t1.summa)
                      FILTER (WHERE t1.kood2 = 'LE-P'), 0) :: NUMERIC(14, 2)             AS pohi_eelarve,
         coalesce(sum(t1.summa)
                      FILTER (WHERE t1.kood2 = 'LE-LA'), 0) :: NUMERIC(14, 2)            AS laen,
         coalesce(sum(t1.summa)
                      FILTER (WHERE t1.kood2 IN ('RE-HK', 'RE-KL', 'RE-ST', 'RE-TT', 'RE-TH')),
                  0) :: NUMERIC(14, 2)                                                   AS riigi_eelarve,
         coalesce(sum(t1.summa)
                      FILTER (WHERE t1.kood2 IN ('LE-Muud', '60')), 0) :: NUMERIC(14, 2) AS siht,
         sum(t1.summa)                                                                   AS kokku
       FROM docs.doc D
              INNER JOIN eelarve.taotlus t ON D.id = t.parentid
              INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
              INNER JOIN ou.rekv r ON r.id = t.rekvId
       WHERE t.aasta = YEAR(l_kpv)
         AND t.kpv <= l_kpv
         AND t.status IN (1, 3)
         AND t1.kood5 IN (SELECT kood
                          FROM com_artikkel
                          WHERE is_kulud)
         AND t.rekvid = (CASE
                           WHEN l_kond = 1
                             THEN t.rekvid
                           ELSE l_rekvid END)
         AND t.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
         AND D.status <> 3 -- not deleted
       GROUP BY t.rekvid, r.parentId, r.nimetus
       UNION ALL
       SELECT
         9999                AS rekvid,
         'Reservfond'        AS asutus,
         sum(t1.summa)       AS pohi_eelarve,
         0 :: NUMERIC(14, 2) AS laen,
         0 :: NUMERIC(14, 2) AS riigi_eelarve,
         0 :: NUMERIC(14, 2) AS siht,
         sum(t1.summa)       AS kokku
       FROM docs.doc D
              INNER JOIN eelarve.taotlus t ON D.id = t.parentid
              INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
              INNER JOIN ou.rekv r ON r.id = t.rekvId
       WHERE t.aasta = YEAR(l_kpv)
         AND t.kpv <= l_kpv
         AND t.status IN (1, 3)
         AND t1.kood5 IN (SELECT kood
                          FROM com_artikkel
                          WHERE is_kulud)
         AND t.rekvid = (CASE
                           WHEN l_kond = 1
                             THEN t.rekvid
                           ELSE l_rekvid END)
         AND t.rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
         AND D.status <> 3 -- not deleted
         AND t1.kood2 = 'LE-RF'
     ) qry
       LEFT OUTER JOIN qryTaitmine qt ON qt.rekvid = qry.rekvid;

$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;

/*

SELECT *
FROM eelarve.lisa_2('2019-12-31', 64, 0)

*/
