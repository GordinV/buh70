DROP FUNCTION IF EXISTS eelarve.kassa_taitmine(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.kassa_taitmine(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id  INTEGER,
        tegev    VARCHAR(20),
        artikkel VARCHAR(20),
        nimetus  VARCHAR(254),
        eelarve  NUMERIC(14, 2),
        taitmine NUMERIC(14, 2),
        idx      INTEGER
    ) AS
$BODY$
WITH qryEelarve AS (
    --1000
    SELECT rekvid                                                                         AS rekv_id,
           NULL :: VARCHAR(20)                                                            AS tegev,
           '1000' :: VARCHAR(20)                                                          AS artikkel,
           'Saldo seisuga ' || make_date(year(l_kpv) - 1, 12, 31) :: TEXT :: VARCHAR(254) AS nimetus,
           0 :: NUMERIC(12, 2)                                                            AS eelarve,
           sum(summa)                                                                     AS taitmine,
           4                                                                              AS idx
    FROM (
             SELECT j.rekvid,
                    j1.summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))

               AND (j1.deebet LIKE '100%' OR j1.deebet LIKE '999%')
               AND j1.deebet NOT LIKE '100080%'
               AND j.kpv <= make_date(year(l_kpv) - 1, 12, 31)
             UNION ALL
             SELECT j.rekvid,
                    -1 * summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND (j1.kreedit LIKE '100%' OR j1.kreedit LIKE '999%')
               AND j1.kreedit NOT LIKE '100080%'
               AND j.kpv <= make_date(year(l_kpv) - 1, 12, 31)
         ) qry_100
    GROUP BY rekvid, tegev, artikkel, nimetus, idx
    UNION ALL
    --1001
    SELECT rekvid                                            AS rekv_id,
           NULL :: VARCHAR(20)                               AS tegev,
           '1001' :: VARCHAR(20)                             AS artikkel,
           'Saldo seisuga ' || l_kpv :: TEXT :: VARCHAR(254) AS nimetus,
           0 :: NUMERIC(12, 2)                               AS eelarve,
           sum(summa)                                        AS taitmine,
           4                                                 AS idx
    FROM (
             SELECT j.rekvid,
                    j1.summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))

               AND j1.deebet LIKE '100%'
               AND j1.deebet NOT LIKE '100080%'
               AND j.kpv <= l_kpv
               AND j.kpv > make_date(year(l_kpv) - 1, 12, 31)
             UNION ALL
             SELECT j.rekvid,
                    -1 * summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND j1.kreedit LIKE '100%'
               AND j1.kreedit NOT LIKE '100080%'
               AND j.kpv <= l_kpv
               AND j.kpv > make_date(year(l_kpv) - 1, 12, 31)
         ) qry_100
    GROUP BY rekvid, tegev, artikkel, nimetus, idx
    UNION ALL
    --2580
    SELECT rekvid                                   AS rekv_id,
           NULL :: VARCHAR(20)                      AS tegev,
           '2580' :: VARCHAR(20)                    AS artikkel,
           'Emiteeritud võlakirjad' :: VARCHAR(254) AS nimetus,
           sum(summa) :: NUMERIC(12, 2)             AS eelarve,
           sum(summa)                               AS taitmine,
           4                                        AS idx
    FROM (
             SELECT j.rekvid,
                    j1.summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))

               AND (kreedit LIKE '208%' OR kreedit LIKE '258%' OR kreedit LIKE '20362%' OR
                    (kreedit LIKE '20363%' AND kood5 = '2580'))
               AND j.kpv < make_date(year(l_kpv), 1, 1)
         ) qry_100
    GROUP BY rekvid, tegev, artikkel, nimetus, idx
    UNION ALL
    --3500
    SELECT rekvid                                                     AS rekv_id,
           NULL :: VARCHAR(20)                                        AS tegev,
           '3500' :: VARCHAR(20)                                      AS artikkel,
           'Saadud tegevuskulude sihtfinantseerimine' :: VARCHAR(254) AS nimetus,
           0 :: NUMERIC(12, 2)                                        AS eelarve,
           sum(taitmine)                                              AS taitmine,
           1                                                          AS idx
    FROM (
             SELECT j.rekvid,
                    j1.summa AS taitmine
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))

               AND (LEFT(j1.deebet, 3) = '100' OR LEFT(j1.deebet, 6) = '999999')
               AND (LEFT(j1.kood5, 4) = '3500')
               AND YEAR(j.kpv) = YEAR(l_kpv)
               AND j.kpv <= l_Kpv
             UNION ALL
             SELECT j.rekvid,
                    -1 * summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND (LEFT(j1.deebet, 6) = '710000')
               AND (LEFT(j1.kood5, 4) = '3500')
               AND YEAR(kpv) = YEAR(l_kpv)
               AND j.kpv <= l_kpv
         ) qry_3500
    GROUP BY rekvid, tegev, artikkel, nimetus, idx
    UNION ALL
    --3502
    SELECT rekvid                                                              AS rekv_id,
           NULL :: VARCHAR(20)                                                 AS tegev,
           '3502' :: VARCHAR(20)                                               AS artikkel,
           'Põhivara soetuseks saadav sihtfinantseerimine(+) ' :: VARCHAR(254) AS nimetus,
           0 :: NUMERIC(12, 2)                                                 AS eelarve,
           sum(taitmine)                                                       AS taitmine,
           3                                                                   AS idx
    FROM (
             SELECT j.rekvid,
                    j1.summa AS taitmine
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND (LEFT(j1.deebet, 3) = '100' OR LEFT(j1.deebet, 6) = '999999')
               AND (LEFT(j1.kood5, 4) = '3502')
               AND YEAR(j.kpv) = YEAR(l_kpv)
               AND j.kpv <= l_Kpv
             UNION ALL
             SELECT j.rekvid,
                    -1 * summa
             FROM docs.journal j
                      INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
             WHERE j.rekvid = (CASE
                                   WHEN l_kond = 1
                                       THEN j.rekvid
                                   ELSE l_rekvid END)
               AND j.rekvid IN (SELECT rekv_id
                                FROM get_asutuse_struktuur(l_rekvid))
               AND (LEFT(j1.deebet, 6) = '710000')
               AND (LEFT(j1.kood5, 4) = '3502')
               AND YEAR(kpv) = YEAR(l_kpv)
               AND j.kpv <= l_kpv
         ) qry_3502
    GROUP BY rekvid, tegev, artikkel, nimetus, idx
    UNION ALL
    --2585
    SELECT j.rekvid              AS rekv_id,
           NULL :: VARCHAR(20)   AS tegev,
           '2585' :: VARCHAR(20) AS artikkel,
           'Kohustuste võtmine'  AS nimetus,
           0 :: NUMERIC(12, 2)   AS eelarve,
           j1.summa              AS taitmine,
           4                     AS idx
    FROM docs.journal j
             INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
    WHERE j.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN j.rekvid
                          ELSE l_rekvid END)
      AND j.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND ((LEFT(j1.kreedit, 3) IN ('208', '258') AND j1.kood3 = '05' AND LEFT(j1.deebet, 3) IN ('100') AND
            j1.kood5 = '2585')
        OR
           (LEFT(j1.deebet, 3) IN ('100', '999') AND LEFT(j1.kreedit, 5) IN ('20363', '20362') AND j1.kood5 = '2585'))
      AND j.kpv <= l_kpv
      AND YEAR(kpv) = YEAR(l_kpv)
    UNION ALL
    --2586
    SELECT j.rekvid              AS rekv_id,
           NULL :: VARCHAR(20)   AS tegev,
           '2586' :: VARCHAR(20) AS artikkel,
           'Kohustuste tasumine' AS nimetus,
           0 :: NUMERIC(12, 2)   AS eelarve,
           j1.summa              AS taitmine,
           4                     AS idx
    FROM docs.journal j
             INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
    WHERE j.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN j.rekvid
                          ELSE l_rekvid END)
      AND j.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (((LEFT(j1.deebet, 3) = '208' OR LEFT(j1.deebet, 4) = '2058') AND j1.kood5 = '2586' AND
            LEFT(j1.kreedit, 3) = '100')
        OR (LEFT(j1.kreedit, 3) IN ('100') AND
            (LEFT(j1.deebet, 5) IN ('20363', '20362') OR LEFT(j1.deebet, 3) = '201') AND j1.kood5 = '2586')
        )
      AND j.kpv <= l_kpv
      AND YEAR(kpv) = YEAR(l_kpv)
    UNION ALL
    --eelarve
    SELECT e.rekvid            AS rekv_id,
           e.kood1             AS tegev,
           e.kood5             AS artikkel,
           a.nimetus           AS nimetus,
           sum(summa)          AS eelarve,
           0 :: NUMERIC(14, 2) AS taitmine,
           CASE
               WHEN a.is_kulud
                   THEN 2
               WHEN NOT a.is_kulud AND e.kood5 = '3502'
                   THEN 3
               WHEN NOT a.is_kulud
                   THEN 1
               ELSE
                   3
               END             AS idx
    FROM eelarve.eelarve e
             LEFT OUTER JOIN com_artikkel a ON a.kood = e.kood5
    WHERE aasta = YEAR(l_kpv)
      AND e.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN e.rekvid
                          ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
    GROUP BY e.rekvid, a.is_kulud, e.kood1, e.kood5, a.nimetus
    UNION ALL
    --kulud, taitmine
    SELECT kt.rekvid,
           kt.tegev,
           kt.artikkel,
           a.nimetus,
           0 :: NUMERIC AS eelarve,
           sum(summa)   AS taitmine,
           2            AS idx
    FROM cur_kulude_kassa_taitmine kt
             INNER JOIN com_artikkel a ON a.kood = kt.artikkel
    WHERE kt.rekvid = (CASE
                           WHEN l_kond = 1
                               THEN kt.rekvid
                           ELSE l_rekvid END)
      AND kt.rekvid IN (SELECT rekv_id
                        FROM get_asutuse_struktuur(l_rekvid))
      AND kt.aasta = YEAR(l_kpv)
      AND kt.kuu <= MONTH(l_kpv)
      AND kt.artikkel NOT IN ('3500', '2585', '2586')
    GROUP BY kt.rekvid, kt.tegev, kt.artikkel, a.nimetus
    UNION ALL
    --tulud, taitmine
    SELECT kt.rekvid,
           kt.tegev,
           kt.artikkel,
           a.nimetus,
           0 :: NUMERIC AS eelarve,
           sum(summa)   AS taitmine,
           1            AS idx
    FROM cur_tulude_kassa_taitmine kt
             INNER JOIN com_artikkel a ON a.kood = kt.artikkel
    WHERE kt.rekvid = (CASE
                           WHEN l_kond = 1
                               THEN kt.rekvid
                           ELSE l_rekvid END)
      AND kt.rekvid IN (SELECT rekv_id
                        FROM get_asutuse_struktuur(l_rekvid))
      AND kt.aasta = YEAR(l_kpv)
      AND kt.kuu <= MONTH(l_kpv)
      AND kt.artikkel NOT IN ('3500', '2585', '2586')
      AND kt.artikkel NOT LIKE ('350%')

    GROUP BY kt.rekvid, kt.tegev, kt.artikkel, a.nimetus
)
-- Põhitegevusts tulud kokku
SELECT rekv_id,
       NULL :: VARCHAR(20)                         AS tegev,
       '' :: VARCHAR(20)                           AS artikkel,
       'Põhitegevusts tulud kokku' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                                AS eelarve,
       sum(taitmine)                               AS taitmine,
       1                                           AS idx
FROM qryEelarve
WHERE idx = 1
GROUP BY rekv_id
UNION ALL
--100
--Likviidsete varade muutus (+ suurenemine, - vahenemine)
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                                                       AS tegev,
       '100' :: VARCHAR(20)                                                                                      AS artikkel,
       'Likviidsete varade muutus (+ suurenemine, - vahenemine) Saldo seisuga ' ||
       l_kpv :: TEXT :: VARCHAR(254)                                                                             AS nimetus,
       sum(eelarve)
           FILTER (WHERE artikkel LIKE '100%')                                                                   AS eelarve,
       sum(taitmine)
           FILTER (WHERE artikkel = '1001') - sum(taitmine)
                                                  FILTER (WHERE artikkel = '1000')                               AS taitmine,
       4                                                                                                         AS idx
FROM qryEelarve
WHERE artikkel IN ('1000', '1001')
GROUP BY rekv_id
UNION ALL
SELECT rekv_id,
       NULL :: VARCHAR(20)                         AS tegev,
       '' :: VARCHAR(20)                           AS artikkel,
       'Põhitegevusts kulud kokku' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                                AS eelarve,
       sum(taitmine)                               AS taitmine,
       2                                           AS idx
FROM qryEelarve
WHERE idx = 2
GROUP BY rekv_id
UNION ALL
--30
SELECT rekv_id,
       NULL :: VARCHAR(20)          AS tegev,
       '30' :: VARCHAR(20)          AS artikkel,
       'Maksutulud' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                 AS eelarve,
       sum(taitmine)                AS taitmine,
       1                            AS idx
FROM qryEelarve
WHERE artikkel LIKE '30%'
  AND artikkel <> '30'
GROUP BY rekv_id
UNION ALL
--32
SELECT rekv_id,
       NULL :: VARCHAR(20)                                 AS tegev,
       '32' :: VARCHAR(20)                                 AS artikkel,
       'Tulud kaupade ja teenuste muugist' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                                        AS eelarve,
       sum(taitmine)                                       AS taitmine,
       1                                                   AS idx
FROM qryEelarve
WHERE artikkel LIKE '32%'
  AND artikkel <> '32'
GROUP BY rekv_id
UNION ALL
--352
SELECT rekv_id,
       NULL :: VARCHAR(20)                               AS tegev,
       '352' :: VARCHAR(20)                              AS artikkel,
       'Mittesihtotstarbelised toetused' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                                      AS eelarve,
       sum(taitmine)                                     AS taitmine,
       1                                                 AS idx
FROM qryEelarve
WHERE artikkel LIKE '352%'
  AND artikkel <> '352'
GROUP BY rekv_id
UNION ALL
--  381
SELECT rekv_id,
       NULL :: VARCHAR(20)             AS tegev,
       '381' :: VARCHAR(20)            AS artikkel,
       'Põhivara müük' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                    AS eelarve,
       sum(taitmine)                   AS taitmine,
       3                               AS idx
FROM qryEelarve
WHERE artikkel LIKE '381%'
  AND artikkel <> '3818'
GROUP BY rekv_id
UNION ALL
--  3818
SELECT rekv_id,
       NULL :: VARCHAR(20)                           AS tegev,
       '3818' :: VARCHAR(20)                         AS artikkel,
       'Kasum/kahjum varude müügist' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                                  AS eelarve,
       sum(taitmine)                                 AS taitmine,
       3                                             AS idx
FROM qryEelarve
WHERE artikkel = '3818'
GROUP BY rekv_id
UNION ALL
--382
SELECT rekv_id,
       NULL :: VARCHAR(20)                    AS tegev,
       '382' :: VARCHAR(20)                   AS artikkel,
       'Tulud varude müügist' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                           AS eelarve,
       sum(taitmine)                          AS taitmine,
       1                                      AS idx
FROM qryEelarve
WHERE artikkel LIKE '382%'
  AND artikkel NOT IN ('38250', '38251', '38252', '38254')
GROUP BY rekv_id
UNION ALL
--3880
SELECT rekv_id,
       NULL :: VARCHAR(20)                   AS tegev,
       '3880' :: VARCHAR(20)                 AS artikkel,
       'Muud tulud varadelt' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                          AS eelarve,
       sum(taitmine)                         AS taitmine,
       1                                     AS idx
FROM qryEelarve
WHERE artikkel LIKE '3880%'
GROUP BY rekv_id
UNION ALL
--3888
SELECT rekv_id,
       NULL :: VARCHAR(20)          AS tegev,
       '3888' :: VARCHAR(20)        AS artikkel,
       'Muud tulud' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                 AS eelarve,
       sum(taitmine)                AS taitmine,
       1                            AS idx
FROM qryEelarve
WHERE artikkel LIKE '3888%'
GROUP BY rekv_id
UNION ALL
--413
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                            AS tegev,
       '413' :: VARCHAR(20)                                                           AS artikkel,
       'Sotsiaalabitoetused ja muud toetused füüsilistele isikuteled' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                                              AS eelarve,
       sum(-1 * taitmine)                                                             AS taitmine,
       2                                                                              AS idx
FROM qryEelarve
WHERE artikkel LIKE '413%'
GROUP BY rekv_id
UNION ALL
--4500
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                            AS tegev,
       '4500' :: VARCHAR(20)                                                          AS artikkel,
       'Sotsiaalabitoetused ja muud toetused füüsilistele isikuteled' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                                              AS eelarve,
       sum(-1 * taitmine)                                                             AS taitmine,
       2                                                                              AS idx
FROM qryEelarve
WHERE artikkel LIKE '4500%'
GROUP BY rekv_id
UNION ALL
--4502
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                            AS tegev,
       '4502' :: VARCHAR(20)                                                          AS artikkel,
       'Sotsiaalabitoetused ja muud toetused füüsilistele isikuteled' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                                              AS eelarve,
       sum(-1 * taitmine)                                                             AS taitmine,
       2                                                                              AS idx
FROM qryEelarve
WHERE artikkel LIKE '4502%'
GROUP BY rekv_id
UNION ALL
--452
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                            AS tegev,
       '452' :: VARCHAR(20)                                                           AS artikkel,
       'Sotsiaalabitoetused ja muud toetused füüsilistele isikuteled' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                                              AS eelarve,
       sum(-1 * taitmine)                                                             AS taitmine,
       2                                                                              AS idx
FROM qryEelarve
WHERE artikkel LIKE '452%'
GROUP BY rekv_id

UNION ALL
--50
SELECT rekv_id,
       NULL :: VARCHAR(20)           AS tegev,
       '50' :: VARCHAR(20)           AS artikkel,
       'Tööjõukulud' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)             AS eelarve,
       sum(-1 * taitmine)            AS taitmine,
       2                             AS idx
FROM qryEelarve
WHERE artikkel LIKE '50%'
GROUP BY rekv_id

UNION ALL
--55
SELECT rekv_id,
       NULL :: VARCHAR(20)               AS tegev,
       '55' :: VARCHAR(20)               AS artikkel,
       'Majandamiskulud' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                 AS eelarve,
       sum(-1 * taitmine)                AS taitmine,
       2                                 AS idx
FROM qryEelarve
WHERE artikkel LIKE '55%'
GROUP BY rekv_id
UNION ALL
--60
SELECT rekv_id,
       NULL :: VARCHAR(20)          AS tegev,
       '60' :: VARCHAR(20)          AS artikkel,
       'Muud kulud' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)            AS eelarve,
       sum(-1 * taitmine)           AS taitmine,
       2                            AS idx
FROM qryEelarve
WHERE artikkel LIKE '60%'
GROUP BY rekv_id
UNION ALL
--650
SELECT rekv_id,
       NULL :: VARCHAR(20)             AS tegev,
       '650' :: VARCHAR(20)            AS artikkel,
       'Finantstkulud' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)               AS eelarve,
       sum(-1 * taitmine)              AS taitmine,
       3                               AS idx
FROM qryEelarve
WHERE artikkel LIKE '650%'
GROUP BY rekv_id
UNION ALL
--655
SELECT rekv_id,
       NULL :: VARCHAR(20)            AS tegev,
       '655' :: VARCHAR(20)           AS artikkel,
       'Finantstulud' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                   AS eelarve,
       sum(taitmine)                  AS taitmine,
       3                              AS idx
FROM qryEelarve
WHERE artikkel LIKE '655%'
GROUP BY rekv_id
UNION ALL
--15
SELECT rekv_id,
       NULL :: VARCHAR(20)               AS tegev,
       '15' :: VARCHAR(20)               AS artikkel,
       'Põhivara soetus' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                 AS eelarve,
       sum(-1 * taitmine)                AS taitmine,
       3                                 AS idx
FROM qryEelarve
WHERE artikkel IN ('1550', '1551', '1554', '1555', '1556', '1557', '156', '157', '158', '1553', '1559', '154')
  AND artikkel <> '15'
GROUP BY rekv_id

UNION ALL
--1501
SELECT rekv_id,
       NULL :: VARCHAR(20)               AS tegev,
       '1501' :: VARCHAR(20)             AS artikkel,
       'Põhivara soetus' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                 AS eelarve,
       sum(-1 * taitmine)                AS taitmine,
       3                                 AS idx
FROM qryEelarve
WHERE artikkel LIKE '1501%'
GROUP BY rekv_id
UNION ALL
--1502
SELECT rekv_id,
       NULL :: VARCHAR(20)                                    AS tegev,
       '1502' :: VARCHAR(20)                                  AS artikkel,
       'Osalused tütar- ja sidusettevõtjates' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                      AS eelarve,
       sum(-1 * taitmine)                                     AS taitmine,
       3                                                      AS idx
FROM qryEelarve
WHERE artikkel LIKE '1502%'
GROUP BY rekv_id
UNION ALL
--1511
SELECT rekv_id,
       NULL :: VARCHAR(20)                                   AS tegev,
       '1511' :: VARCHAR(20)                                 AS artikkel,
       'Investeerimisportfelli väärtpaberid' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                     AS eelarve,
       sum(-1 * taitmine)                                    AS taitmine,
       3                                                     AS idx
FROM qryEelarve
WHERE artikkel LIKE '1511%'
GROUP BY rekv_id
UNION ALL
--1512
SELECT rekv_id,
       NULL :: VARCHAR(20)                             AS tegev,
       '1512' :: VARCHAR(20)                           AS artikkel,
       'Tähtajani hoitavad võlakirjad' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                               AS eelarve,
       sum(-1 * taitmine)                              AS taitmine,
       3                                               AS idx
FROM qryEelarve
WHERE artikkel LIKE '1512%'
GROUP BY rekv_id
UNION ALL
--1531
SELECT rekv_id,
       NULL :: VARCHAR(20)                    AS tegev,
       '1531' :: VARCHAR(20)                  AS artikkel,
       'Nõuded ostjate vastu' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                      AS eelarve,
       sum(-1 * taitmine)                     AS taitmine,
       3                                      AS idx
FROM qryEelarve
WHERE artikkel LIKE '1531%'
GROUP BY rekv_id
UNION ALL
--1532
SELECT rekv_id,
       NULL :: VARCHAR(20)                                       AS tegev,
       '1532' :: VARCHAR(20)                                     AS artikkel,
       'Laenu- ja liisingnõuete pikaajaline osa' :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)                                         AS eelarve,
       sum(-1 * taitmine)                                        AS taitmine,
       3                                                         AS idx
FROM qryEelarve
WHERE artikkel LIKE '1532%'
GROUP BY rekv_id
UNION ALL
--1001
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                                    AS tegev,
       '1001' :: VARCHAR(20)                                                                  AS artikkel,
       'Likviidsete varade muutus (+ suurenemine, - vahenemine)Saldo seisuga' :: VARCHAR(254) AS nimetus,
       sum(eelarve)                                                                           AS eelarve,
       sum(taitmine)                                                                          AS taitmine,
       4                                                                                      AS idx
FROM qryEelarve
WHERE artikkel LIKE '1001%'
GROUP BY rekv_id
UNION ALL
--2581
SELECT rekv_id,
       NULL :: VARCHAR(20)                                                          AS tegev,
       '2581' :: VARCHAR(20)                                                        AS artikkel,
       'Laenud' :: VARCHAR(254)                                                     AS nimetus,
       sum(eelarve)
           FILTER (WHERE artikkel <> '2586') - sum(eelarve)
                                                   FILTER (WHERE artikkel = '2586') AS eelarve,
       sum(taitmine)
           FILTER (WHERE artikkel <> '2586') - sum(taitmine)
                                                   FILTER (WHERE artikkel = '2586') AS taitmine,
       3                                                                            AS idx
FROM qryEelarve
WHERE artikkel IN ('2580', '2585', '2586')
GROUP BY rekv_id
UNION ALL
--2585
SELECT rekv_id,
       NULL :: VARCHAR(20)     AS tegev,
       artikkel :: VARCHAR(20) AS artikkel,
       nimetus :: VARCHAR(254) AS nimetus,
       sum(eelarve)            AS eelarve,
       sum(taitmine)           AS taitmine,
       4                       AS idx
FROM qryEelarve
WHERE artikkel = '2585'
GROUP BY rekv_id, artikkel, nimetus
UNION ALL
--2586
SELECT rekv_id,
       NULL :: VARCHAR(20)     AS tegev,
       artikkel :: VARCHAR(20) AS artikkel,
       nimetus :: VARCHAR(254) AS nimetus,
       sum(-1 * eelarve)       AS eelarve,
       sum(-1 * taitmine)      AS taitmine,
       4                       AS idx
FROM qryEelarve
WHERE artikkel = '2586'
GROUP BY rekv_id, idx, artikkel, nimetus

UNION ALL
--teised
SELECT rekv_id,
       NULL :: VARCHAR(20) AS tegev,
       artikkel,
       nimetus,
       sum(eelarve)        AS eelarve,
       sum(taitmine)       AS taitmine,
       idx
FROM qryEelarve
WHERE artikkel IS NOT NULL
  AND NOT empty(artikkel)
  AND artikkel NOT IN ('40', '41', '4500', '452')
  AND left(artikkel, 4) NOT IN
      ('1501', '1502', '1511', '1512', '1531', '1532', '4500', '4502', '3880', '3888', '1001', '2586', '2585')
  -- eraldi
  AND (artikkel NOT LIKE '382%' OR artikkel IN ('38250', '38251', '38252', '38254')) -- eraldi
  AND left(artikkel, 3) NOT IN ('413', '452', '381', '650', '655')                   -- eraldi
  AND left(artikkel, 2) NOT IN ('50', '55', '60', '32')                              -- eraldi
  AND idx IS NOT NULL
GROUP BY rekv_id, idx, artikkel, nimetus
UNION ALL
SELECT rekv_id,
       tegev :: VARCHAR(20) AS tegev,
       NULL :: VARCHAR(20)  AS artikkel,
       t.nimetus,
       sum(eelarve)         AS eelarve,
       sum(taitmine)        AS taitmine,
       5                    AS idx
FROM qryEelarve e
         LEFT OUTER JOIN com_tegev t ON t.kood = e.tegev
WHERE e.tegev IS NOT NULL
  AND NOT empty(tegev)
  AND e.artikkel NOT IN ('2585', '2586')
  AND idx IS NOT NULL

GROUP BY rekv_id, idx, tegev, t.nimetus

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kassa_taitmine(DATE, INTEGER, INTEGER) TO dbvaatleja;

SELECT *
FROM eelarve.kassa_taitmine('2020-03-31', 64, 0)
WHERE artikkel = '4133'
and tegev is not null;
