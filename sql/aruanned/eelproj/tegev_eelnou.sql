DROP FUNCTION IF EXISTS eelarve.tegev_eelnou(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tegev_eelnou(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id      INTEGER,
        parentid     INTEGER,
        parentAsutus VARCHAR(254),
        tegev        VARCHAR(20),
        nimetus      VARCHAR(254),
        summa_1      NUMERIC(14, 2),
        summa_2      NUMERIC(14, 2),
        summa_3      NUMERIC(14, 2),
        summa_4      NUMERIC(14, 2),
        summa_5      NUMERIC(14, 2),
        summa_6      NUMERIC(14, 2),
        summa_7      NUMERIC(14, 2),
        asutus       VARCHAR(254)
    ) AS
$BODY$

WITH qryTaitmine AS (
    SELECT t.kood1,
           t.kood5,
           sum(t.summa) AS summa_1,
           0::NUMERIC   AS summa_2,
           0::NUMERIC   AS summa_3,
           0::NUMERIC   AS summa_4,
           0::NUMERIC   AS summa_5,
           0::NUMERIC   AS summa_6,
           0::NUMERIC   AS summa_7,
           t.rekvid
    FROM eelarve.eeltaitmine t
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (t.kood2 IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND t.aasta = year(l_kpv) - 1
    GROUP BY t.rekvid, t.kood1, t.kood5
    UNION ALL
-- 		-- 2007.a. eelarve täitmine (ilma sihtotstarbeliste laekumiste, riigieelarveta, remondi ja soetusteta, laenuta)
    SELECT t.kood1,
           t.kood5,
           0::NUMERIC   AS summa_1,
           sum(t.summa) AS _summa_2,
           0::NUMERIC   AS summa_3,
           0::NUMERIC   AS summa_4,
           0::NUMERIC   AS summa_5,
           0::NUMERIC   AS summa_6,
           0::NUMERIC   AS summa_7,
           t.rekvid
    FROM eelarve.eeltaitmine t
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (t.kood2::TEXT IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND t.aasta = year(l_kpv) - 1
    GROUP BY t.rekvid, t.kood1, t.kood5

    UNION ALL
    -- 2008.a. eelarve (ilma sihtotstarbeliste laekumiste, riigieelarveta, remondi ja soetusteta, laenuta)
    SELECT e.kood1,
           e.kood5,
           0::NUMERIC   AS summa_1,
           0::NUMERIC   AS summa_2,
           sum(e.summa) AS _summa_3,
           0::NUMERIC   AS summa_4,
           0::NUMERIC   AS summa_5,
           0::NUMERIC   AS summa_6,
           0::NUMERIC   AS summa_7,
           e.rekvid
    FROM eelarve.eelarve e
    WHERE e.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN e.rekvid
                          ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (e.kood2::TEXT IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND e.is_parandus = 0
      AND e.aasta = year(l_kpv)
    GROUP BY e.rekvid, e.kood1, e.kood5
    UNION ALL
    -- 2008.a. täpsustatud eelarve seisuga 30.06.2008.a (ilma sihtotstarbeliste laekumiste, riigieelarveta, remondi ja soetusteta, laenuta)
    SELECT e.kood1,
           e.kood5,
           0::NUMERIC   AS summa_1,
           0::NUMERIC   AS summa_2,
           0::NUMERIC   AS summa_3,
           sum(e.summa) AS _summa_4,
           0::NUMERIC   AS summa_5,
           0::NUMERIC   AS summa_6,
           0::NUMERIC   AS summa_7,
           e.rekvid
    FROM eelarve.eelarve e
    WHERE e.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN e.rekvid
                          ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (e.kood2::TEXT IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND e.aasta = year(l_kpv)
    GROUP BY e.rekvid, e.kood1, e.kood5
    UNION ALL
    -- 2008.a eelarve täitmine seisuga 30.06.2008.a (ilma sihtotstarbeliste laekumiste, riigieelarveta, remondi ja soetusteta, laenuta)
    SELECT e.tegev,
           e.artikkel,
           0::NUMERIC   AS summa_1,
           0::NUMERIC   AS summa_2,
           0::NUMERIC   AS summa_3,
           0::NUMERIC   AS summa_4,
           sum(e.summa) AS summa_5,
           0::NUMERIC   AS summa_6,
           0::NUMERIC   AS summa_7,
           e.rekvid
    FROM cur_kulude_kassa_taitmine e
    WHERE e.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN e.rekvid
                          ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (e.allikas::TEXT IN ('LE-P', 'LE-RF') OR empty(allikas))
      AND e.aasta = year(l_kpv)
    GROUP BY e.rekvid, e.tegev, e.artikkel
    UNION ALL

    -- 2009.a. eelarve eelnõu (ilma sihtotstarbeliste laekumiste, riigieelarveta, remondi ja soetusteta, laenuta)
    SELECT t1.kood1      AS tegev,
           t1.kood5      AS artikkel,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           sum(t1.summa) AS summa_6,
           0::NUMERIC    AS summa_7,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (t1.kood2::TEXT IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 3
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
-- eelnou
    SELECT t1.kood1      AS tegev,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           sum(t1.summa) AS summa_7,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
             INNER JOIN eelarve.eelproj proj ON t1.eelprojid = proj.id AND proj.status IN (1, 2)
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (t1.kood2::TEXT IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 1
    GROUP BY t.rekvid, t1.kood1, t1.kood5
)

SELECT qt.rekvid,
       r.parentid                                                        AS parentId,
       (SELECT nimetus FROM ou.rekv WHERE id = r.parentid)::VARCHAR(254) AS parentAsutus,
       qt.kood1::VARCHAR(20)                                             AS tegev,
       l.nimetus::VARCHAR(254)                                           AS nimetus,
       sum(summa_1)::NUMERIC(14, 2)                                      AS summa_1,
       sum(summa_2)::NUMERIC(14, 2)                                      AS summa_2,
       sum(summa_3)::NUMERIC(14, 2)                                      AS summa_3,
       sum(summa_4)::NUMERIC(14, 2)                                      AS summa_4,
       sum(summa_5)::NUMERIC(14, 2)                                      AS summa_5,
       sum(summa_6)::NUMERIC(14, 2)                                      AS summa_6,
       sum(summa_7)::NUMERIC(14, 2)                                      AS summa_7,
       r.nimetus::VARCHAR(254)                                           AS asutus
FROM qryTaitmine qt
         INNER JOIN libs.library l ON l.kood = qt.kood1
    AND l.library = 'TEGEV'
         INNER JOIN ou.rekv r ON r.id = qt.rekvid
WHERE qt.kood5::TEXT IN (SELECT kood::TEXT FROM libs.library l WHERE library = 'TULUDEALLIKAD' and tun5 = 2)
GROUP BY qt.kood1, l.nimetus, qt.rekvid, r.parentid, r.nimetus;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tegev_eelnou(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tegev_eelnou(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tegev_eelnou(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tegev_eelnou(DATE, INTEGER, INTEGER) TO dbvaatleja;


/*

SELECT *
FROM eelarve.tegev_eelnou('2020-12-31', 120, 1)

select * from libs.library
where library.library = 'DOK'
AND kood = 'TEGEV_EELNOU'

INSERT into libs.library (rekvid, kood, nimetus, library, properties, status)
    VALUES (1, 'TEGEV_EELNOU', 'Asutuse eelarve eelnõu (hallatavate asutuse ja tegevusalade lõikes)', 'DOK','{"type":"aruanne", "module":["Eelproj"]}', 1)
*/

