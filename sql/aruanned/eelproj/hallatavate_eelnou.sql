DROP FUNCTION IF EXISTS eelarve.hallatavate_eelnou(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.hallatavate_eelnou(DATE, INTEGER, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.hallatavate_eelnou(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, l_aktsepteeritud_status integer default 1)
    RETURNS TABLE (
        rekv_id   INTEGER,
        parent_id INTEGER,
        artikkel  VARCHAR(20),
        tegev     VARCHAR(20),
        summa_1   NUMERIC(14, 2),
        summa_2   NUMERIC(14, 2),
        summa_3   NUMERIC(14, 2),
        summa_4   NUMERIC(14, 2),
        kas_tulud BOOLEAN
    )
AS
$BODY$

WITH params AS (
    SELECT l_rekvid AS rekvid,
           l_kpv    AS kpv,
           l_kond   AS kond,
           case when coalesce(l_aktsepteeritud_status,1) = 1 then array[3] else array[0,1,2,3] end as taotluste_statused
),
     qryEelarve AS (
         -- 2022 põhieelarve
         -- tekkepõhine täpustatud
         -- 30.09.2022 seisuga
         -- reservfondita
         SELECT e.kood5               AS artikkel,
                e.kood1               AS tegev,
                sum(e.summa)::NUMERIC AS summa_1,
                0::NUMERIC            AS summa_2,
                0::NUMERIC            AS summa_3,
                0::NUMERIC            AS summa_4,
                e.rekvid
         FROM eelarve.eelarve e,
              params
         WHERE e.rekvid = (CASE
                               WHEN params.kond = 1
                                   THEN e.rekvid
                               ELSE params.rekvid END)
           AND e.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(params.rekvid))
           AND (e.kood2 IN ('LE-P', '60-LE', '80')) -- pohieelarve
           AND e.aasta = year(params.kpv)
           AND (empty(e.is_parandus) OR e.kpv <= make_date(year(params.kpv), 09, 30))
           AND e.rekvid IN (SELECT id FROM ou.rekv WHERE parentid IN (64, 119))
         GROUP BY e.rekvid, e.kood5, e.kood1
         UNION ALL
         -- järgmine aasta
         -- 2023.a  põhieelarve tekkepõhine eelnõu

         SELECT t1.kood5               AS artikkel,
                t1.kood1               AS tegev,
                0::NUMERIC             AS summa_1,
                sum(t1.summa)::NUMERIC AS summa_2,
                0::NUMERIC             AS summa_3,
                0::NUMERIC             AS summa_4,
                t.rekvid
         FROM eelarve.taotlus t
                  INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
              params
         WHERE t.aasta = YEAR(params.kpv) + 1
           AND t.status IN (select unnest(params.taotluste_statused))
           AND t.rekvid = (CASE
                               WHEN $3 = 1
                                   THEN t.rekvid
                               ELSE params.rekvid END)
           AND t.rekvid IN (SELECT a.rekv_id
                            FROM get_asutuse_struktuur(params.rekvid) a)
           AND t1.kood2 IN ('LE-P', '60-LE', '80')
           AND t.rekvid <> 9
           AND t.rekvid IN (SELECT id FROM ou.rekv WHERE parentid IN (64, 119))

         GROUP BY t1.kood5,
                  t1.kood1,
                  t.rekvid
         UNION ALL
         -- 2022 riigieelarve
-- tekkepõhine täpustatud
-- 30.09.2022 seisuga
         SELECT e.kood5               AS artikkel,
                e.kood1               AS tegev,
                0::NUMERIC            AS summa_1,
                0::NUMERIC            AS summa_2,
                sum(e.summa)::NUMERIC AS summa_3,
                0::NUMERIC            AS summa_4,
                e.rekvid
         FROM eelarve.eelarve e,
              params
         WHERE e.rekvid = (CASE
                               WHEN params.kond = 1
                                   THEN e.rekvid
                               ELSE params.rekvid END)
           AND e.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(params.rekvid))
           AND e.kood2 NOT LIKE '%RF%'
           AND e.kood2 ILIKE '%RE%' -- riigieelarve
           AND e.aasta = year(params.kpv)
           AND (empty(e.is_parandus) OR e.kpv <= make_date(year(params.kpv), 09, 30))
           AND e.rekvid IN (SELECT id FROM ou.rekv WHERE parentid IN (64, 119))

         GROUP BY e.rekvid, e.kood5, e.kood1
         UNION ALL
         -- 2023.a  riigieelarve tekkepõhine eelnõu
         SELECT t1.kood5               AS artikkel,
                t1.kood1               AS tegev,
                0::NUMERIC             AS summa_1,
                0::NUMERIC             AS summa_2,
                0::NUMERIC             AS summa_3,
                sum(t1.summa)::NUMERIC AS summa_4,
                t.rekvid
         FROM eelarve.taotlus t
                  INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
              params
         WHERE t.aasta = YEAR(params.kpv) + 1
           AND t.status IN (select unnest(params.taotluste_statused))
           AND t.rekvid = (CASE
                               WHEN $3 = 1
                                   THEN t.rekvid
                               ELSE params.rekvid END)
           AND t.rekvid IN (SELECT a.rekv_id
                            FROM get_asutuse_struktuur(params.rekvid) a)
           AND t1.kood2 NOT LIKE '%RF%'
           AND t1.kood2 ILIKE '%RE%' -- riigieelarve
           AND t.rekvid <> 9
           AND t.rekvid IN (SELECT id FROM ou.rekv WHERE parentid IN (64, 119))

         GROUP BY t1.kood5,
                  t1.kood1,
                  t.rekvid
     ),
     qryPreReport AS (
         SELECT qt.rekvid,
                r.parentid                                    AS parent_id,
                CASE WHEN l.tun5 = 1 THEN TRUE ELSE FALSE END AS kas_tulud,
                (CASE
-- Доходы здесь отражаются только собственные, для этих учреждений в доходах только группы 32*, 38* и 655. В отчете в колонке E (Kontoklass/art) показываем 4 знака, 381 и 655 - 3 знака
                     WHEN l.tun5 = 1 AND left(qt.artikkel, 3) IN ('381', '655') THEN left(qt.artikkel, 3)
                     WHEN l.tun5 = 2 AND qt.artikkel NOT IN ('2586', '650') THEN left(qt.artikkel, 2)
                     ELSE qt.artikkel
                    END)::VARCHAR(20)                         AS artikkel,
                qt.tegev:: VARCHAR(20)                        AS tegev,
                (summa_1)::NUMERIC(14, 2)                     AS summa_1,
                (summa_2)::NUMERIC(14, 2)                     AS summa_2,
                (summa_3)::NUMERIC(14, 2)                     AS summa_3,
                (summa_4)::NUMERIC(14, 2)                     AS summa_4
         FROM qryEelarve qt
                  INNER JOIN (SELECT *
                              FROM libs.library l
                              WHERE l.library = 'TULUDEALLIKAD'
                                AND l.status <> 3
                                AND (l.tun5 = 1 AND (left(kood, 2) IN ('32', '38') OR l.kood LIKE '655%') OR l.tun5 = 2)
         ) l ON l.kood = qt.artikkel
                  INNER JOIN ou.rekv r ON r.id = qt.rekvid
     )
SELECT *
FROM (
         SELECT rekvid,
                parent_id,
                artikkel,
                tegev,
                sum(summa_1) AS summa_1,
                sum(summa_2) AS summa_2,
                sum(summa_3) AS summa_3,
                sum(summa_4) AS summa_4,
                kas_tulud
         FROM qryPreReport
         GROUP BY rekvid, parent_id, artikkel, tegev, kas_tulud
         UNION ALL
         --               - итог по доходам
--                - итог по расходам
         SELECT NULL                                              AS rekvid,
                NULL                                              AS parent_id,
                CASE WHEN kas_tulud THEN 'TULUD' ELSE 'KULUD' END AS artikkel,
                tegev,
                sum(summa_1)                                      AS summa_1,
                sum(summa_2)                                      AS summa_2,
                sum(summa_3)                                      AS summa_3,
                sum(summa_4)                                      AS summa_4,
                kas_tulud
         FROM qryPreReport q
         GROUP BY tegev, kas_tulud
         UNION ALL
         -- 2 итоги по учреждению по всем Tegevusala, artikkel
--                - итог по доходам
--                - итог по расходам
         SELECT parent_id    AS rekvid,
                NULL,
                artikkel,
                tegev,
                sum(summa_1) AS summa_1,
                sum(summa_2) AS summa_2,
                sum(summa_3) AS summa_3,
                sum(summa_4) AS summa_4,
                kas_tulud
         FROM qryPreReport
         GROUP BY tegev, artikkel, parent_id, kas_tulud
         UNION ALL
         -- 3 итоги по учреждению по конкретному Tegevusala
--                - итог по доходам
--                - итог по расходам
         SELECT rekvid                                            AS rekvid,
                parent_id,
                CASE WHEN kas_tulud THEN 'TULUD' ELSE 'KULUD' END AS artikkel,
                tegev,
                sum(summa_1)                                      AS summa_1,
                sum(summa_2)                                      AS summa_2,
                sum(summa_3)                                      AS summa_3,
                sum(summa_4)                                      AS summa_4,
                kas_tulud
         FROM qryPreReport
         GROUP BY tegev, rekvid, parent_id, kas_tulud
     ) qry
ORDER BY parent_id, rekvid, artikkel, tegev, kas_tulud
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.hallatavate_eelnou(DATE, INTEGER, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.hallatavate_eelnou(DATE, INTEGER, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.hallatavate_eelnou(DATE, INTEGER, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.hallatavate_eelnou(DATE, INTEGER, INTEGER, INTEGER) TO dbvaatleja;


SELECT sum(summa_4) OVER ()                                                                         AS kokku,

       CASE
           WHEN r.parentid IN (119, 3, 64) THEN ltrim(rtrim(coalesce(p.nimetus, '')))
           ELSE r.nimetus END ::VARCHAR(254)                                                        AS asutus,
       CASE WHEN r.parentid IN (119, 3, 64) THEN ltrim(rtrim(r.nimetus)) ELSE '' END ::VARCHAR(254) AS hallava_asutus,
       l.nimetus                                                                                    AS nimetus,
       t.nimetus                                                                                    AS tegev_nimetus,
       qry.*
FROM eelarve.hallatavate_eelnou('2022-12-31', 119, 1, 0) qry
         LEFT OUTER JOIN ou.rekv r ON r.id = qry.rekv_id
         LEFT OUTER JOIN ou.rekv p ON p.id = qry.parent_id
         LEFT OUTER JOIN (SELECT kood, nimetus
                          FROM libs.library l
                          WHERE l.library = 'TULUDEALLIKAD'
                          UNION ALL
                          SELECT 'KULUD' AS kood, 'KOKKU KULUD' AS nimetus
                          UNION ALL
                          SELECT 'TULUD' AS kood, 'KOKKU OMATULUD' AS nimetus
) l
                         ON l.kood = qry.artikkel
         LEFT OUTER JOIN libs.library t ON t.kood = qry.tegev AND t.library = 'TEGEV'
ORDER BY CASE
             WHEN r.id IS NULL THEN 0
             WHEN r.id > 9999 THEN 1
             WHEN r.id = 63 THEN 10
             WHEN r.id = 1190 THEN 100
             WHEN r.id = 119 THEN 110
             WHEN r.parentid = 119 THEN 120
             WHEN r.id = 300 THEN 130
             WHEN r.id = 3 OR r.parentid = 3 THEN 140
             WHEN r.id = 640 THEN 150
             WHEN r.id = 64 THEN 160
             WHEN r.parentid = 64 THEN 170

             WHEN r.parentid = 63 THEN 200
             WHEN r.parentid = 119 THEN 300
             ELSE 900 END * 1000, r.nimetus,
         qry.kas_tulud,
         CASE WHEN artikkel = 'KULUD' THEN '0' WHEN artikkel = 'TULUD' THEN '00' ELSE qry.artikkel END,
         CASE WHEN qry.tegev IS NULL THEN '000000' ELSE qry.tegev END

/*

51196444
51193468

SELECT *
FROM eelarve.hallatavate_eelnou('2022-07-31', 63, 0)

select * from libs.library
where library.library = 'DOK'
AND kood = 'EELARVE_EELNOU'

INSERT into libs.library (rekvid, kood, nimetus, library, properties, status)
    VALUES (1, 'EELARVE_EELNOU', 'Narva linna kondeelarve eelnõu', 'DOK','{"type":"aruanne", "module":["Eelproj"]}', 1)
*/

