DROP FUNCTION IF EXISTS eelarve.tulem(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id INTEGER,
        konto   VARCHAR(20),
        nimetus VARCHAR(254),
        summa   NUMERIC(14, 2),
        idx     INTEGER
    ) AS
$BODY$

WITH qryPreReport AS (
    SELECT *
    FROM eelarve.pikk_tulem(l_kpv :: DATE, l_rekvid, l_kond)
    WHERE konto IN
          ('3', '30', '300', '302', '303', '304', '305', '32', '320', '322', '35', '38', '381', '382', '3880', '3882',
           '3888',
           '4', '41', '45', '50', '55', '60', '61',
           '65', '650', '652', '655', '658', '680000', '690000',
           '7')),
     qryTegevusKulud AS (
         -- Netovara			Saldoandmikust (Sum: Konto 289000 kreedit + Kontod 29* Kreedit + sum: konto 3* kuni 7* kreedit)) - (Sum: Konto 289000 deebet + Kontod 29* Deebet + sum:konot 3* kuni 7* deebet)
         SELECT s.rekvid,
                s.konto,
                sum(coalesce(s.db, 0)) AS db,
                sum(coalesce(s.kr, 0)) AS kr
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv)
           AND s.kuu = month(l_kpv)
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
           AND (
                 left(konto, 2) IN ('60', '61', '62', '63', '64')
                 OR left(konto, 1) IN ('4', '5')
             )

         GROUP BY s.konto, s.rekvid
     ),
     qryTegevusTulem AS (
         SELECT s.rekvid,
                s.konto,
                sum(coalesce(s.db, 0)) AS db,
                sum(coalesce(s.kr, 0)) AS kr
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv)
           AND s.kuu = month(l_kpv)
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
           AND (
                 left(konto, 2) IN ('60', '61', '62', '63', '64')
                 OR left(konto, 1) IN ('3', '4', '5')
             )
         GROUP BY s.konto, s.rekvid
     ),
     qryTulem AS (
         -- Aruandeperioodi tulem		Saldoandmikust (Sum: Kontod 3*kuni 7* Kreedit) - (Sum: Kontod 3* kuni 7* Deebet)
         SELECT s.rekvid,
                s.konto,
                sum(coalesce(s.db, 0)) AS db,
                sum(coalesce(s.kr, 0)) AS kr
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv)
           AND s.kuu = month(l_kpv)
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
           AND left(konto, 1) IN ('3', '4', '5', '6')
         GROUP BY s.konto, s.rekvid
     ),
     qryTulemKokku AS (
         -- Aruandeperioodi tulem		Saldoandmikust (Sum: Kontod 3*kuni 7* Kreedit) - (Sum: Kontod 3* kuni 7* Deebet)
         SELECT s.rekvid,
                s.konto,
                sum(coalesce(s.db, 0)) AS db,
                sum(coalesce(s.kr, 0)) AS kr
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv)
           AND s.kuu = month(l_kpv)
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
           AND left(konto, 1) IN ('3', '4', '5', '6', '7')
         GROUP BY s.konto, s.rekvid
     ),
     qryNetto AS (
         -- Aruandeperioodi tulem		Saldoandmikust (Sum: Kontod 3*kuni 7* Kreedit) - (Sum: Kontod 3* kuni 7* Deebet)
         SELECT s.rekvid,
                s.konto,
                sum(coalesce(s.db, 0)) AS db,
                sum(coalesce(s.kr, 0)) AS kr
         FROM eelarve.saldoandmik s
         WHERE s.aasta = year(l_kpv)
           AND s.kuu = month(l_kpv)
           AND rekvid = (CASE
                             WHEN l_kond = 1 AND l_rekvid <> 63
                                 THEN s.rekvid
                             WHEN l_kond = 1 AND l_rekvid = 63
                                 THEN 999
                             ELSE l_rekvid END)
           AND s.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid)
                            UNION ALL
                            SELECT CASE
                                       WHEN l_kond = 1 AND l_rekvid <> 63
                                           THEN l_rekvid
                                       WHEN l_kond = 1 AND l_rekvid = 63
                                           THEN 999
                                       ELSE l_rekvid END
         )
           AND left(konto, 1) IN ('7')
         GROUP BY s.konto, s.rekvid
     )


SELECT rekv_id,
       konto            AS konto,
       nimetus,
       summa            AS summa,
       CASE
           WHEN left(konto, 1) IN ('3') THEN 100
           WHEN left(konto, 1) IN ('4', '5') THEN 200
           WHEN left(konto, 2) IN ('60', '61') THEN 200
           WHEN left(konto, 2) IN ('65', '68', '69') THEN 300
           WHEN left(konto, 1) IN ('7') THEN 400
           ELSE 100 END AS idx
FROM qryPreReport

UNION ALL
SELECT l_rekvid,
       '4'                                         AS konto,
       'Tegevuskulud'                              AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       190                                         AS idx
FROM qryTegevusKulud
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Aruandeperioodi tegevustulem'              AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       300                                         AS idx
FROM qryTegevusTulem
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Aruandeperioodi tulem'                     AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       310                                         AS idx
FROM qryTulem
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Aruandeperioodi tulem ja siirded kokku'    AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       420                                         AS idx
FROM qryTulemKokku
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Netofinantseerimine eelarvest'             AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       410                                         AS idx
FROM qryNetto


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulem(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;


SELECT *
FROM eelarve.tulem('2021-03-31' :: DATE, 63, 1)
ORDER BY idx, konto
