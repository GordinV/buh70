DROP FUNCTION IF EXISTS eelarve.bilanss(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
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
    FROM eelarve.pikk_bilanss(l_kpv :: DATE, l_rekvid, l_kond)
    WHERE konto IN ('1', '10', '100', '101', '102', '103', '108', '109', '106',
                    '15', '150020', '1502', '151', '152', '153', '154', '155', '156', '157',
                    '2', '20', '200', '201', '202', '203', '206', '208', '209000',
                    '25', '250', '253', '256', '257', '258', '259000',
                    '290', '291', '292', '297',
                    '`*')),
     qryNettovara AS (
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
           AND (konto = '289000'
             OR left(konto, 2) = '29'
             OR left(konto, 1) IN ('3', '4', '5', '6', '7')
             )

         GROUP BY s.konto, s.rekvid
     ),
     -- Vähemusosalus		Saldoandmikust (Sum: Konto 289000 Kreedit) - (Sum: Konto 289000 Deebet)
     qryVahemusosalus AS (
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
           AND ltrim(rtrim(konto)) = '289000'
         GROUP BY s.konto, s.rekvid
     ),
     --     Aruandja omanikele kuuluv netovara Saldoandmikust (Sum: Kontod 29* Kreedit + sum: konto 3* kuni 7* kreedit) - (Sum: Kontod 29* Deebet -sum 3* kuni 7* deebet)
     qryKuluvNetovara AS (
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
           AND (left(konto, 2) = '29'
             OR left(konto, 1) IN ('3', '4', '5', '6', '7')
             )
         GROUP BY s.konto, s.rekvid
     ),
     qryPudujaak AS (
-- Akumuleeritud ülejääk (puudujääk)		Saldoandmikust (Sum: Konto 298* Kreedit) - (Sum: Konto 298* Deebet)
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
           AND left(konto, 3) = '298'

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
           AND left(konto, 1) IN ('3', '4', '5', '6', '7')
         GROUP BY s.konto, s.rekvid
     )


SELECT rekv_id,
       CASE WHEN konto = '`*' THEN '' ELSE konto END AS konto,
       nimetus,
       summa                                         AS summa,
       CASE
           -- '`*'
           WHEN konto IN ('`*') THEN 350
           WHEN konto IN ('290', '291', '292', '297') THEN 300
           ELSE 100 END                              AS idx
FROM qryPreReport

UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Netovara'                                  AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       200                                         AS idx
FROM qryNettovara
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Vähemusosalus'                             AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       210                                         AS idx
FROM qryVahemusosalus
WHERE (db IS NOT NULL OR kr IS NOT NULL)
UNION ALL
-- Aruandja omanikele kuuluv netovara Saldoandmikust (Sum: Kontod 29* Kreedit + sum: konto 3* kuni 7* kreedit) - (Sum: Kontod 29* Deebet -sum 3* kuni 7* deebet)
SELECT l_rekvid,
       ''                                          AS konto,
       'Aruandja omanikele kuuluv netovara'        AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       220                                         AS idx
FROM qryKuluvNetovara
WHERE (db IS NOT NULL OR kr IS NOT NULL)
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Akumuleeritud ülejääk (puudujääk)'         AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       330                                         AS idx
FROM qryPudujaak
UNION ALL
SELECT l_rekvid,
       ''                                          AS konto,
       'Aruandeperioodi tulem'                     AS nimetus,
       sum(coalesce(kr, 0)) - sum(coalesce(db, 0)) AS summa,
       340                                         AS idx
FROM qryTulem


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION eelarve.bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.bilanss(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER) TO dbvaatleja;

/*
SELECT *
FROM eelarve.pikk_bilanss('2020-12-31' :: DATE, 63, 1)
where konto in ('2', '299000')
GROUP BY konto, nimetus
ORDER BY konto
*/