DROP FUNCTION IF EXISTS eelarve.allikas_eelnou(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.allikas_eelnou(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id      INTEGER,
        parentid     INTEGER,
        parentAsutus VARCHAR(254),
        tegev        VARCHAR(20),
        artikkel     VARCHAR(20),
        nimetus      VARCHAR(254),
        summa_1      NUMERIC(14, 2),
        summa_2      NUMERIC(14, 2),
        summa_3      NUMERIC(14, 2),
        summa_4      NUMERIC(14, 2),
        summa_5      NUMERIC(14, 2),
        summa_6      NUMERIC(14, 2),
        summa_7      NUMERIC(14, 2),
        summa_8      NUMERIC(14, 2),
        asutus       VARCHAR(254)
    ) AS
$BODY$

WITH qryTaitmine AS (
    --  Põhieelarve
    SELECT t1.kood1,
           t1.kood5,
           sum(t1.summa) AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           0::NUMERIC    AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (t1.kood2 IN ('LE-P', 'LE-RF') OR empty(kood2))
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 3
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
    --  Põhieelarve, koostatud
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           sum(t1.summa) AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           0::NUMERIC    AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('LE-P', 'LE-RF')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 1
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
--  Laenude arvelt
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           sum(t1.summa) AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           0::NUMERIC    AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('LE-LA')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 3
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
--  Laenude arvelt, koostatud
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           sum(t1.summa) AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           0::NUMERIC    AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('LE-LA')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 1
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
--  	RIIGIEELARVE
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           sum(t1.summa) AS summa_5,
           0::NUMERIC    AS summa_6,
           0::NUMERIC    AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('RE')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 3
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           sum(t1.summa) AS summa_6,
           0::NUMERIC    AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('RE')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 1
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
    --  	Sihtotstarbelised laekumised
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           sum(t1.summa) AS summa_7,
           0::NUMERIC    AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('60')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 3
    GROUP BY t.rekvid, t1.kood1, t1.kood5
    UNION ALL
    SELECT t1.kood1,
           t1.kood5,
           0::NUMERIC    AS summa_1,
           0::NUMERIC    AS summa_2,
           0::NUMERIC    AS summa_3,
           0::NUMERIC    AS summa_4,
           0::NUMERIC    AS summa_5,
           0::NUMERIC    AS summa_6,
           0::NUMERIC    AS summa_7,
           sum(t1.summa) AS summa_8,
           t.rekvid
    FROM eelarve.taotlus t
             INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.rekvid = (CASE
                          WHEN l_kond = 1
                              THEN t.rekvid
                          ELSE l_rekvid END)
      AND t.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND t1.kood2::TEXT IN ('60')
      AND t.aasta = year(l_kpv) + 1
      AND t.status = 1
    GROUP BY t.rekvid, t1.kood1, t1.kood5
)

SELECT qt.rekvid,
       r.parentid                                                        AS parentId,
       (SELECT nimetus FROM ou.rekv WHERE id = r.parentid)::VARCHAR(254) AS parentAsutus,
       qt.kood1::VARCHAR(20)                                             AS tegevus,
       qt.kood5::VARCHAR(20)                                             AS artikkel,
       l.nimetus::VARCHAR(254)                                           AS nimetus,
       sum(summa_1)::NUMERIC(14, 2)                                      AS summa_1,
       sum(summa_2)::NUMERIC(14, 2)                                      AS summa_2,
       sum(summa_3)::NUMERIC(14, 2)                                      AS summa_3,
       sum(summa_4)::NUMERIC(14, 2)                                      AS summa_4,
       sum(summa_5)::NUMERIC(14, 2)                                      AS summa_5,
       sum(summa_6)::NUMERIC(14, 2)                                      AS summa_6,
       sum(summa_7)::NUMERIC(14, 2)                                      AS summa_7,
       sum(summa_8)::NUMERIC(14, 2)                                      AS summa_8,
       r.nimetus::VARCHAR(254)                                           AS asutus
FROM qryTaitmine qt
         INNER JOIN libs.library l ON l.kood = qt.kood5
    AND l.library = 'TULUDEALLIKAD' AND tun5 = 2
         INNER JOIN ou.rekv r ON r.id = qt.rekvid
GROUP BY qt.kood1, qt.kood5, l.nimetus, qt.rekvid, r.parentid, r.nimetus;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.allikas_eelnou(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.allikas_eelnou(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.allikas_eelnou(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.allikas_eelnou(DATE, INTEGER, INTEGER) TO dbvaatleja;


/*

SELECT *
FROM eelarve.allikas_eelnou('2019-12-31', 63, 1)

select * from libs.library
where library.library = 'DOK'
AND kood = 'ALLIKAS_EELNOU'

INSERT into libs.library (rekvid, kood, nimetus, library, properties, status)
    VALUES (1, 'ALLIKAS_EELNOU', 'Asutuse eelarve eelnõu (hallatavate asutuse ja allikate lõikes)', 'DOK','{"type":"aruanne", "module":["Eelproj"]}', 1)

*/


