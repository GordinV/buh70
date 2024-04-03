DROP FUNCTION IF EXISTS eelarve.lisa1_lisa5_kontrol_(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.lisa1_lisa5_kontrol(l_kpv DATE,
                                                       l_rekvid INTEGER,
                                                       l_kond INTEGER)
    RETURNS TABLE (
        nimetus            CHARACTER VARYING,
        eelarve            NUMERIC,
        eelarve_kassa      NUMERIC,
        eelarve_taps       NUMERIC,
        eelarve_kassa_taps NUMERIC,
        kassa              NUMERIC,
        saldoandmik        NUMERIC,
        idx                INTEGER
    )
    LANGUAGE 'sql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS
$BODY$

    -- ВЫЗОВ ОТЧЕТА
WITH qryLisa1Lisa5 AS (
    SELECT *
    FROM eelarve.eelarve_andmik_lisa_1_5(l_kpv, l_rekvid, l_kond)
),
     qrySaldoandmik AS (
         SELECT db, kr, konto, tp, rekvid
         FROM eelarve.saldoandmik
         WHERE kuu = month(l_kpv)
           AND aasta = year(l_kpv)
           AND rekvid = (CASE
                             WHEN l_kond = 1
                                 THEN rekvid
                             ELSE l_rekvid END
             )
           AND rekvid IN (SELECT rekv_id
                          FROM get_asutuse_struktuur(l_rekvid))
     ),

     -- art30
     qry_art30 AS (
         SELECT '30'                    AS artikkel,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(tegelik)            AS tegelik,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM qryLisa1Lisa5
         WHERE artikkel IN ('3000', '3030', '3044', '3045', '3047')
     ),
     qry_art35 AS (
         SELECT '35'                    AS artikkel,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(tegelik)            AS tegelik,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM qryLisa1Lisa5
         WHERE artikkel LIKE '35%'
           AND artikkel <> '3502'
     ),
     qry_art38 AS (
         SELECT '38'                    AS artikkel,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(tegelik)            AS tegelik,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM qryLisa1Lisa5
         WHERE (artikkel IN ('3818') OR Left(artikkel, 3) IN ('388', '382'))
     ),
     qry_Pohitulud AS (
         SELECT '3'                     AS artikkel,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(tegelik)            AS tegelik,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT artikkel,
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         tegelik,
                         kassa,
                         saldoandmik
                  FROM qry_art30
                  UNION ALL
                  SELECT artikkel,
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         tegelik,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '32'
                  UNION ALL
                  SELECT artikkel,
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         tegelik,
                         kassa,
                         saldoandmik
                  FROM qry_art35
                  UNION ALL
                  SELECT artikkel,
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         tegelik,
                         kassa,
                         saldoandmik
                  FROM qry_art38
              ) qryTulud),
     qry_PohiKulud AS (
         SELECT 'Pohikulud'             AS artikkel,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(tegelik)            AS tegelik,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM qryLisa1Lisa5
         WHERE (NOT empty(tegev) OR idx = '3.1.099')
     ),
     qry_4 AS (
         SELECT '4'                     AS artikkel,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(tegelik)            AS tegelik,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM qryLisa1Lisa5
         WHERE (artikkel LIKE '40%' OR artikkel LIKE '413%' OR artikkel LIKE '4500%' OR artikkel LIKE '452%')
         UNION ALL
         -- 03.04.2024 VB
         SELECT '4'   AS artikkel,
                0     AS eelarve,
                0     AS eelarve_taps,
                0     AS eelarve_kassa,
                0     AS eelarve_kassa_taps,
                summa AS tegelik,
                0     AS kassa,
                summa AS saldoandmik
         FROM cur_journal j
         WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
           AND kpv <= l_kpv
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
           AND left(deebet, 6) = '601000'
           AND kood5 LIKE '41%'
         UNION ALL
         SELECT '4'        AS artikkel,
                0          AS eelarve,
                0          AS eelarve_taps,
                0          AS eelarve_kassa,
                0          AS eelarve_kassa_taps,
                -1 * summa AS tegelik,
                0          AS kassa,
                -1 * summa AS saldoandmik
         FROM cur_journal j
         WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
           AND kpv <= l_kpv
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
           AND left(kreedit, 6) = '601000'
           AND left(kood5, 2) = '41'

--             Строка 4* Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         --             Сумма всех строк с бюджетом 4* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
         --             Строка 4502 Tekke  täitmine  в отчете EELARVEARUANNE (Lisa 1, Lisa 5)
         --             + (D 601000 art 41* - К 601000 art 41*) в Päevaraamat соответствующего периода=0


     ),
-- 	where (artikkel Like '40%' Or artikkel Like '413%' Or artikkel Like '4500%'  Or artikkel Like '452%');
     qryTuludTaitmine AS (
         SELECT qry.eelarve_kinni            AS eelarve,
                qry.eelarve_parandatud       AS eelarve_taps,
                qry.eelarve_kassa_kinni      AS eelarve_kassa,
                qry.eelarve_kassa_parandatud AS eelarve_kassa_taps,
                qry.tegelik                  AS saldoandmik,
                qry.kassa                    AS kassa,
                qry.artikkel
         FROM eelarve.tulude_taitmine_allikas_artikkel(year(l_kpv)::INTEGER, make_date(year(l_kpv), 01, 01)::DATE,
                                                       l_kpv::DATE,
                                                       l_rekvid, l_kond) qry
         WHERE rekv_id <> 999999),
     qryEelarveTaitmine AS (
         SELECT qry.eelarve_kinni            AS eelarve,
                qry.eelarve_parandatud       AS eelarve_taps,
                qry.eelarve_kassa_kinni      AS eelarve_kassa,
                qry.eelarve_kassa_parandatud AS eelarve_kassa_taps,
                qry.tegelik                  AS saldoandmik,
                qry.kassa                    AS kassa,
                qry.artikkel
         FROM eelarve.eelarve_taitmine_allikas_artikkel(year(l_kpv)::INTEGER, make_date(year(l_kpv), 01, 01)::DATE,
                                                        l_kpv::DATE, l_rekvid::INTEGER,
                                                        l_kond::INTEGER) qry
         WHERE rekv_id <> 999999
     ),
     qryJournal AS (
         SELECT j.deebet,
                j.kreedit,
                sum(j.summa) AS kassa,
                j.kood5      AS artikkel
         FROM cur_journal j
         WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
           AND kpv <= l_kpv
           AND j.rekvid IN (SELECT rekv_id
                            FROM get_asutuse_struktuur(l_rekvid))
           AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
           AND left(deebet, 6) IN ('710001')
           AND left(kreedit, 6) IN ('100100')
         GROUP BY deebet, kreedit, kood5
     )
/*     qryJournal39 AS (SELECT j.deebet,
                             j.kreedit,
                             sum(j.summa) AS kassa,
                             j.kood5      AS artikkel
                      FROM cur_journal j
                      WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
                        AND kpv <= l_kpv
                        AND j.rekvid IN (SELECT rekv_id
                                         FROM get_asutuse_struktuur(l_rekvid))
                        AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                        AND j.rekvid = 9
                      GROUP BY deebet, kreedit, kood5)
*/
-- l_result_eelarve_kassa_taps =  get_kontrol ('','1000','',l_field) +
-- get_kontrol ('','100','',l_field) - get_kontrol ('','1001','',l_field)
SELECT nimetus::VARCHAR(254)                                AS nimetus,
       sum(coalesce(eelarve, 0))::NUMERIC(14, 2)            AS eelarve,
       sum(coalesce(eelarve_kassa, 0))::NUMERIC(14, 2)      AS eelarve_kassa,
       sum(coalesce(eelarve_taps, 0))::NUMERIC(14, 2)       AS eelarve_taps,
       sum(coalesce(eelarve_kassa_taps, 0))::NUMERIC(14, 2) AS eelarve_kassa_taps,
       sum(coalesce(kassa, 0))::NUMERIC(14, 2)              AS kassa,
       sum(coalesce(saldoandmik, 0))::NUMERIC(14, 2)        AS saldoandmik,
       idx::INTEGER
FROM (
         -- Строка PÕHITEGEVUSE TULUD KOKKU   Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 3* Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
         -- строка 3501 Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
         -- строка с бюджетом 381 (только, 3818 не надо брать) Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
         -- строка с бюджетом 3502 Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  +
         -- Сумма всех строк D710001 K 100100 с бюджетом 3*в Päevaraamat-
         -- Сумма всех строк D710001 K 100100 с бюджетом 381*в Päevaraamat Сумма всех строк -
         -- D710001 K 100100 с бюджетом 3501*в Päevaraamat Сумма всех строк D710001 K 100100 с бюджетом 3502*в Päevaraamat =  0
         SELECT 1000                       AS idx,
                'PÕHITEGEVUSE TULUD KOKKU' AS nimetus,
                sum(eelarve)               AS eelarve,
                sum(eelarve_taps)          AS eelarve_taps,
                sum(eelarve_kassa)         AS eelarve_kassa,
                sum(eelarve_kassa_taps)    AS eelarve_kassa_taps,
                sum(kassa)                 AS kassa,
                sum(saldoandmik)           AS saldoandmik
         FROM (
                  SELECT artikkel,
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qry_Pohitulud
                  UNION ALL
                  SELECT '3',
                         -1 * sum(eelarve),
                         -1 * sum(eelarve_taps),
                         -1 * sum(eelarve_kassa),
                         -1 * sum(eelarve_kassa_taps),
                         - 1 * sum(kassa),
                         -1 * sum(saldoandmik)
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3%'
                  UNION ALL
                  SELECT '3',
                         -1 * sum(eelarve),
                         -1 * sum(eelarve_taps),
                         -1 * sum(eelarve_kassa),
                         -1 * sum(eelarve_kassa_taps),
                         - 1 * sum(CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END),
                         -1 * sum(saldoandmik)
                  FROM qryLisa1Lisa5
                  WHERE artikkel LIKE '3501%'
                  UNION ALL
                  SELECT '3',
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '381%'
                    AND artikkel <> '3818'
                  UNION ALL
                  SELECT '3',
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '3502'
                  UNION ALL
                  SELECT '3',
                         0,
                         0,
                         0,
                         0,
                         sum(CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END) AS kassa,
                         0
                  FROM qryJournal
                  WHERE left(artikkel, 1) = '3'
                  UNION ALL
                  SELECT '3',
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE -1 END * sum(kassa) AS kassa,
                         0
                  FROM qryJournal
                  WHERE (artikkel IN ('3501', '3502')
                      OR artikkel = '381'
                            )
                  UNION ALL
                  --                  Строка PÕHITEGEVUSE TULUD KOKKU   Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --                  Сумма всех строк с бюджетом 3* Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
                  --                  строка 3501 Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
                  --                  строка с бюджетом 381 (только, 3818 не надо брать) Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
                  --                  строка с бюджетом 3502 Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  =  0

                  SELECT '3',
                         0,
                         0,
                         0,
                         0,
                         0,
                         sum(kr - db) AS saldoandmik
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3%'
                    AND tp LIKE '185101%'
                    AND l_kond = 1
                    AND l_rekvid = 63
              ) qryPohiTulud
-- Строка PÕHITEGEVUSE TULUD KOKKU   Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
-- Сумма всех строк с бюджетом 3* Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  -
-- строка 3501 Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
-- строка с бюджетом 381 (только, 3818 не надо брать) Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) +
-- строка с бюджетом 3502 Kassa täitmine в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  +
-- Сумма всех строк D710001 K 100100 с бюджетом 3*в Päevaraamat- Сумма всех строк D710001 K 100100 с бюджетом 381*в Päevaraamat Сумма всех строк -
-- D710001 K 100100 с бюджетом 3501*в Päevaraamat Сумма всех строк D710001 K 100100 с бюджетом 3502*в Päevaraamat =  0
         UNION ALL
         -- Строка PÕHITEGEVUSE KULUDE JA INVESTEERIMISTEGEVUSE VÄLJAMINEKUTE JAOTUS TEGEVUSALADE JÄRGI Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Строка 15,2586,4,5,6 KULUD в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn -
         -- строка 2586 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) =0
         SELECT 7000                                                                                    AS idx,
                'PÕHITEGEVUSE KULUDE JA INVESTEERIMIS TEGEVUSE VÄLJAMINEKUTE JAOTUS TEGEVUSALADE JÄRGI' AS nimetus,
                sum(eelarve)                                                                            AS eelarve,
                sum(eelarve_taps)                                                                       AS eelarve_taps,
                sum(eelarve_kassa)                                                                      AS eelarve_kassa,
                sum(eelarve_kassa_taps)                                                                 AS eelarve_kassa_taps,
                sum(kassa)                                                                              AS kassa,
                sum(saldoandmik)                                                                        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qry_Pohikulud
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel = '15,2586,4,5,6'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '2586'
                  UNION ALL
                  -- Строка  PÕHITEGEVUSE KULUDE JA INVESTEERIMISTEGEVUSE VÄLJAMINEKUTE JAOTUS TEGEVUSALADE JÄRGI Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  -
                  -- Строка 15,2586,4,5,6 KULUD в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine  -
                  -- строка 2586  Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма строк 2586 (А80)  Kassa täitmine в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         -1 * kassa,
                         0
                  FROM qryEelarveTaitmine
                  WHERE artikkel = '2586(A80)'
                  UNION ALL

                  -- + Jooksva per saldoandmikust (без элиминирования) конто 4*, 5*, 6* TP 185101* =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_kond = 1 AND l_rekvid = 63 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 1) IN ('4', '5', '6')
                    AND tp LIKE '185101%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '55%'
*/
              ) qryKulud
         UNION ALL

         -- Строка 30 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 30* в отчете Tulu5:12de eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn = 0
         SELECT 1010                    AS idx,
                '30'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qry_art30
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '30%'
                  UNION ALL
                  -- Строка 30 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 32* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine  +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 32*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE
                        '30%'
              ) qry30
         UNION ALL
         -- Строка 3000 Tekke eelarve täps в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 3000 в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve täps=0
         SELECT 1010                                 AS idx,
                '3000'                               AS nimetus,
                sum(COALESCE(eelarve, 0))            AS eelarve,
                sum(COALESCE(eelarve_taps, 0))       AS eelarve_taps,
                sum(COALESCE(eelarve_kassa, 0))      AS eelarve_kassa,
                sum(COALESCE(eelarve_kassa_taps, 0)) AS eelarve_kassa_taps,
                sum(COALESCE(kassa, 0))              AS kassa,
                sum(COALESCE(saldoandmik, 0))        AS saldoandmik
         FROM (
                  SELECT '3000'::VARCHAR(254) AS nimetus,
                         eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3000'
                  UNION ALL
                  SELECT '3000'::VARCHAR(254) AS nimetus,
                         -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '3000'
                  UNION ALL
                  SELECT '3000'::VARCHAR(254) AS nimetus,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '3000'
              ) qry3000
         UNION ALL
         SELECT 1010                                 AS idx,
                '3030'                               AS nimetus,
                sum(coalesce(eelarve, 0))            AS eelarve,
                sum(coalesce(eelarve_taps, 0))       AS eelarve_taps,
                sum(coalesce(eelarve_kassa, 0))      AS eelarve_kassa,
                sum(coalesce(eelarve_kassa_taps, 0)) AS eelarve_kassa_taps,
                sum(coalesce(kassa, 0))              AS kassa,
                sum(coalesce(saldoandmik, 0))        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3030'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '3030'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '3030'
              ) qry3030
         UNION ALL
         SELECT 1010                                 AS idx,
                '3044'                               AS nimetus,
                sum(coalesce(eelarve, 0))            AS eelarve,
                sum(coalesce(eelarve_taps, 0))       AS eelarve_taps,
                sum(coalesce(eelarve_kassa, 0))      AS eelarve_kassa,
                sum(coalesce(eelarve_kassa_taps, 0)) AS eelarve_kassa_taps,
                sum(coalesce(kassa, 0))              AS kassa,
                sum(coalesce(saldoandmik, 0))        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3044'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '3044'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '3044'
              ) qry3044
         UNION ALL
         SELECT 1010                                 AS idx,
                '3045'                               AS nimetus,
                sum(coalesce(eelarve, 0))            AS eelarve,
                sum(coalesce(eelarve_taps, 0))       AS eelarve_taps,
                sum(coalesce(eelarve_kassa, 0))      AS eelarve_kassa,
                sum(coalesce(eelarve_kassa_taps, 0)) AS eelarve_kassa_taps,
                sum(coalesce(kassa, 0))              AS kassa,
                sum(coalesce(saldoandmik, 0))        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3045'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '3045'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '3045'
              ) qry3045
         UNION ALL
         SELECT 1010                                 AS idx,
                '3047'                               AS nimetus,
                sum(coalesce(eelarve, 0))            AS eelarve,
                sum(coalesce(eelarve_taps, 0))       AS eelarve_taps,
                sum(coalesce(eelarve_kassa, 0))      AS eelarve_kassa,
                sum(coalesce(eelarve_kassa_taps, 0)) AS eelarve_kassa_taps,
                sum(coalesce(kassa, 0))              AS kassa,
                sum(coalesce(saldoandmik, 0))        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3047'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '3047'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '3047'
              ) qry3047
         UNION ALL
         SELECT 1010                    AS idx,
                '32'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '32'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '32%'
                  UNION ALL
                  -- Строка 30 Kassa eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 30* в отчете
-- Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  Kassa täitmine=0
--   Строка 30 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --   Сумма всех строк с бюджетом 30* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  --   Сумма всех строк D710001 K 100100 с бюджетом 30*в Päevaraamat = 0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '32%'
                        -- Строка 32 Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                        -- Сумма всех строк с бюджетом 32* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
                        -- Jooksva per saldoandmikust (без элиминирования) конто 32* TP 185101=0
/*                  UNION ALL
                  -- корректировка эллиминирования отдела культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '32%'
*/ -- Строка 32 Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                        -- Сумма всех строк с бюджетом 32* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
                        -- Jooksva per saldoandmikust (без элиминирования) конто 32* TP 185101=0
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '32%'
                    AND tp LIKE '185101%'
              ) qry32
         UNION ALL
         SELECT 1010                    AS idx,
                '320'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '320'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '320%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '320%'
              ) qry320
         UNION ALL
         SELECT 1010                    AS idx,
                '3220'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3220'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3220%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3220%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3220%'
                    AND tp LIKE '185101%'
              ) qry3220
         UNION ALL
         SELECT 1010                    AS idx,
                '3221'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3221'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3221%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3221%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END AS saldoandmik
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3221%'
                    AND tp LIKE '185101%'
--                      Строка 3221 Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 3221* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine+
                  --                      Jooksva per saldoandmikust (без элиминирования) конто 3221* TP 185101=0
                  --                      + сумма строк с бюджетом 3221 в Päevaraamat TP18510139 соответствующего периода
/*                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_kond = 1 THEN -1 * summa ELSE 0 END AS saldoandmik

                  FROM (SELECT sum(j.summa) AS summa
                        FROM cur_journal j
                        WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
                          AND kpv <= l_kpv
                          AND j.rekvid IN (SELECT rekv_id
                                           FROM get_asutuse_struktuur(l_rekvid))
                          AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                          AND kood5 LIKE '3221%'
                          AND lisa_k = '18510139'
                          AND kreedit LIKE '3221%'
                       ) j
                  WHERE l_kond = 1
*/ ) qry3221
         UNION ALL
         SELECT 1010                    AS idx,
                '3222'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3222'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3222%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3222%'
                  UNION ALL
/*                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3222%'
                  UNION ALL
*/
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3222%'
                    AND tp LIKE '185101%'
              ) qry3222
         UNION ALL
-- 3223
         SELECT 1010                    AS idx,
                '3223'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3223'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3223%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3223%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3223%'
                    AND tp LIKE '185101%'
              ) qry3223
         UNION ALL
         SELECT 1010                    AS idx,
                '3224'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3224'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3224%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3224%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3224%'

*/
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3224%'
                    AND tp LIKE '185101%'
              ) qry3224
         UNION ALL
         SELECT 1010                    AS idx,
                '3229'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3229'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3229%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3229%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3229%'
*/
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3229%'
                    AND tp LIKE '185101%'
              ) qry3229
         UNION ALL
         SELECT 1010                    AS idx,
                '3232'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3232'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3232%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3232%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3232%'
*/
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3232%'
                    AND tp LIKE '185101%'
              ) qry3232
         UNION ALL
         SELECT 1010                    AS idx,
                '3233'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3233'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3233%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3233%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa  ELSE 0  END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3233%'
*/
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3233%'
                    AND tp LIKE '185101%'
              ) qry3232
         UNION ALL
         SELECT 1010                    AS idx,
                '3237'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3237'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3237%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3237%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3237%'
*/
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3237%'
                    AND tp LIKE '185101%'
              ) qry3237
         UNION ALL
         SELECT 1010                    AS idx,
                '3238'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3238'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3238%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3238%'
/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '3238%'
*/
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kr - db ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE konto LIKE '3238%'
                    AND tp LIKE '185101%'
              ) qry3237
         UNION ALL
         --         Строка 35 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         --         Сумма всех строк с бюджетом 35* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn -
         --         строка 3501 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  + Строка 3502 Tekke eelarve kinn  в отчете EELARVEARUANNE (Lisa 1, Lisa 5) =0         SELECT '35'                    AS nimetus,
         SELECT 1010                    AS idx,
                '35'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qry_art35
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '35%'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE saldoandmik END
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3501'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3502'
-- Строка 35 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                        -- Сумма всех строк с бюджетом 35* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine   -
                        -- строка 3501 Kassa täitmine в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
                        -- Строка 3502 Kassa  täitmine  в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
                        -- Сумма всех строк D710001 K 100100 с бюджетом 35*в Päevaraamat -
                        -- Сумма  всех строк D710001 K 100100 с бюджетом 3501*в Päevaraamat -Сумма  всех строк D710001 K 100100 с бюджетом 3502*в Päevaraamat =0
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_kond = 1 AND l_rekvid = 63 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '35%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_kond = 1 AND l_rekvid = 63 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE (artikkel LIKE '3501%' OR artikkel LIKE '3502%')
              ) qry35
         UNION ALL
         -- Строка 3500 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 3500* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 1010                    AS idx,
                '3500'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3500'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3500%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_kond = 1 AND l_rekvid = 63 THEN 0 ELSE kassa END,
--                         kassa,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3500%'
              ) qry3500
         UNION ALL
         SELECT 1010                    AS idx,
                '352'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel LIKE '352%'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '352%'
                  UNION ALL
                  -- Строка 352 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 352* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 352*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '352%'
              ) qry352
         UNION ALL
         SELECT 1010                    AS idx,
                '35200'                 AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel LIKE '35200%'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '35200%'
                  UNION ALL
                  -- Строка 352 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 352* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 352*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '35200%'
              ) qry352
         UNION ALL
         SELECT 1010                    AS idx,
                '35201'                 AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel LIKE '35201%'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '35201%'
                  UNION ALL
                  -- Строка 352 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 352* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 352*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '35201%'
              ) qry352
         UNION ALL
         -- Строка 38 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 38* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
         -- Строка 381 Tekke eelarve kinn  в отчете EELARVEARUANNE (Lisa 1, Lisa 5)=0

--         Строка 38 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         --         Сумма всех строк с бюджетом 38* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
         --         Строка 381 Tekke eelarve kinn  в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)=0

         SELECT 1010                    AS idx,
                '38'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qry_art38
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '38%'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         CASE WHEN l_kond = 1 AND l_rekvid = 63 THEN 0 ELSE kassa END,
                         saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '381'
                  UNION ALL
                  -- Строка 38 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 38* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Строка 381 Kassa  täitmine  в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 38*в Päevaraamat -Сумма всех строк D710001 K 100100 с бюджетом 381*в Päevaraamat =0

-- Строка 38 Kassa eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 38* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  Kassa täitmine+
                  -- Строка 381 Kassa  täitmine  в отчете EELARVEARUANNE (Lisa 1, Lisa 5)=0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '38%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '381'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END,
                         0
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '381'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 2) = '38'
                    AND left(tp, 6) = '185101'
              ) qry38
         UNION ALL
         SELECT 1010                    AS idx,
                '3818'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3818'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3818%'
                  UNION ALL
                  -- Строка 3818 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 3818* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 3818*в Päevaraamat =0

-- Строка 3818 Kassa eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 3818* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  Kassa täitmine=0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3818%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 4) = '3818'
                    AND left(tp, 6) = '185101'
              ) qry3818
         UNION ALL
         -- Строка 382 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 382* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
         -- Сумма всех строк с бюджетом 3825* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 1010                    AS idx,
                '382'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '382'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '382%'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3825%'
                  UNION ALL
                  -- Строка 3818 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 3818* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 3818*в Päevaraamat =0

-- Строка 3818 Kassa eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 3818* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  Kassa täitmine=0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '382%'
-- Строка 382 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 382* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
                  -- Сумма всех строк с бюджетом 3825* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
              ) qry382
         UNION ALL
         SELECT 1010                    AS idx,
                '38250'                 AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '38250'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '38250%'
                  UNION ALL
                  --                      Строка 38250 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --                      Сумма всех строк с бюджетом 38250* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  --                      Сумма всех строк D710001 K 100100 с бюджетом 38250*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '38250%'
-- Строка 382 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 382* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
                  -- Сумма всех строк с бюджетом 3825* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
              ) qry382
         UNION ALL
         SELECT 1010                    AS idx,
                '38251'                 AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '38251'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '38251%'
                  UNION ALL
                  --                      Строка 38251 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --                      Сумма всех строк с бюджетом 38251* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  --                      Сумма всех строк D710001 K 100100 с бюджетом 38251*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '38251%'
-- Строка 382 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 382* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
                  -- Сумма всех строк с бюджетом 3825* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
              ) qry382
         UNION ALL
         SELECT 1010                    AS idx,
                '38252'                 AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '38252'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '38252%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '38252%'
              ) qry38
         UNION ALL
         SELECT 1010                    AS idx,
                '38254'                 AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '38254'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '38254%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '38254%'
              ) qry38
         UNION ALL
         SELECT 1010                    AS idx,
                '3880'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3880'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3880%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3880%'
              ) qry38
         UNION ALL
         -- Строка 3882 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 3882* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 1010                    AS idx,
                '3882'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3882'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3882%'
                  UNION ALL
                  -- Строка 3882 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 3882* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine + Сумма всех строк D710001 K 100100 с бюджетом 3882*в Päevaraamat =0Строка 3882 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 3882* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 3882*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3882%'
              ) qry38
         UNION ALL
         -- Строка 3888 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 3888* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 1010                    AS idx,
                '3888'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3888'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3888%'
                  UNION ALL
                  -- Строка 3882 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 3882* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine + Сумма всех строк D710001 K 100100 с бюджетом 3882*в Päevaraamat =0Строка 3882 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 3882* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  -- Сумма всех строк D710001 K 100100 с бюджетом 3882*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3888%'
              ) qry38

         UNION ALL
         -- Строка 4 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 4* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn +
         -- Строка 4502 Tekke eelarve kinn  в отчете EELARVEARUANNE (Lisa 1, Lisa 5) =0
         SELECT 2010                    AS idx,
                '4'                     AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qry_4
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '4%'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '4502'
-- Строка  4* Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
-- Сумма всех строк с бюджетом 4* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art)  Tekke täitmine +
-- Строка 4502 Tekke  täitmine  в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Jooksva per saldoandmikust (без элиминирования) конто 4* TP 185101 = 0
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 1) = '4'
                    AND left(tp, 6) = '185101'
              ) qry4
         UNION ALL
         -- Строка 40* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)  +
         -- Сумма всех строк с бюджетом 40* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn = 0
         SELECT 2010                    AS idx,
                '40'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '40'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '40%'
              ) qry40
         UNION ALL
         -- Строка 413* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 413* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 2010                    AS idx,
                '413'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '413'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '413%'
                  UNION ALL
                  --                  Строка  413* Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --                  Сумма всех строк с бюджетом 413* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine+
                  --                  Jooksva per saldoandmikust (без элиминирования) конто 413* TP 185101=0
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 1) = '413'
                    AND left(tp, 6) = '185101'
                  UNION ALL
                  -- 03.04.2024 VB
                  SELECT 0     AS eelarve,
                         0     AS eelarve_taps,
                         0     AS eelarve_kassa,
                         0     AS eelarve_kassa_taps,
                         0     AS kassa,
                         summa AS saldoandmik
                  FROM cur_journal j
                  WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
                    AND kpv <= l_kpv
                    AND j.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                    AND left(deebet, 6) = '601000'
                    AND kood5 LIKE '41%'
                  UNION ALL
                  SELECT 0          AS eelarve,
                         0          AS eelarve_taps,
                         0          AS eelarve_kassa,
                         0          AS eelarve_kassa_taps,
                         0          AS kassa,
                         -1 * summa AS saldoandmik
                  FROM cur_journal j
                  WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
                    AND kpv <= l_kpv
                    AND j.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                    AND left(kreedit, 6) = '601000'
                    AND left(kood5, 2) = '41'
              ) qry413
         UNION ALL
         -- Строка 4500* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)+
         -- Сумма всех строк с бюджетом 4500* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 2010                    AS idx,
                '4500'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '4500'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '4500%'
              ) qry4500
         UNION ALL
         -- Строка 452* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)+
         -- Сумма всех строк с бюджетом 452* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 2010                    AS idx,
                '452'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '452'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '452%'
              ) qry452
         UNION ALL
         -- Строка 50* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 50* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 2010                    AS idx,
                '50'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '50'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '50%'
                  UNION ALL
                  -- Строка  50* Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 50* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
                  -- Jooksva per saldoandmikust (без элиминирования) конто 50* TP 185101=0

                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 2) = '50'
                    AND left(tp, 6) = '185101'
              ) qry50
         UNION ALL
         -- Строка 55* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 55* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 2010                    AS idx,
                '55'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '55'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '55%'
                  UNION ALL
                  -- Строка  55* Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  -- Сумма всех строк с бюджетом 55* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke täitmine +
                  -- Jooksva per saldoandmikust (без элиминирования) конто 55* TP 185101=0
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN db - kr ELSE 0 END
                  FROM qrySaldoandmik
                  WHERE left(konto, 2) = '55'
                    AND left(tp, 6) = '185101'
                  UNION ALL
                  -- 03.04.2024 VB
                  SELECT 0     AS eelarve,
                         0     AS eelarve_taps,
                         0     AS eelarve_kassa,
                         0     AS eelarve_kassa_taps,
                         0     AS kassa,
                         summa AS saldoandmik
                  FROM cur_journal j
                  WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
                    AND kpv <= l_kpv
                    AND j.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                    AND left(deebet, 6) = '601000'
                    AND kood5 LIKE '41%'
                  UNION ALL
                  SELECT 0          AS eelarve,
                         0          AS eelarve_taps,
                         0          AS eelarve_kassa,
                         0          AS eelarve_kassa_taps,
                         0          AS kassa,
                         -1 * summa AS saldoandmik
                  FROM cur_journal j
                  WHERE kpv >= make_date(year(l_kpv), 01, 01)::DATE
                    AND kpv <= l_kpv
                    AND j.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND j.rekvid = CASE WHEN l_kond = 1 THEN j.rekvid ELSE l_rekvid END
                    AND left(kreedit, 6) = '601000'
                    AND left(kood5, 2) = '41'

/*                  UNION ALL
                  -- убираем элиминирование отд. культуры
                  SELECT 0,
                         0,
                         0,
                         0,
                         0,
                         -1 * CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN kassa ELSE 0 END
                  FROM qryJournal39
                  WHERE artikkel LIKE '55%'
*/ ) qry55
         UNION ALL
         -- Строка 60* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 60* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 2010                    AS idx,
                '60'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '60'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '60%'
              ) qry60
         UNION ALL
         -- Строка 381 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 381* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 3010                    AS idx,
                '381'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '381'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '381'
                  UNION ALL
                  --  Строка 381 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --  Сумма всех строк с бюджетом 381* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine +
                  --  Сумма всех строк D710001 K 100100 с бюджетом 381*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '381'
              ) qry381
         UNION ALL
         -- Строка 15* Tekke eelarve kinn в отче+293:298те EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 155, 15б, 157, 158 в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 3020                    AS idx,
                '15'                    AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '15'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel IN ('155', '156', '157', '158')
              ) qry15
         UNION ALL
         -- Строка 3502 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 3502* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 3030                    AS idx,
                '3502'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '3502'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel LIKE '3502%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel LIKE '3502%'
              ) qry3502
         UNION ALL
         -- Строка 4502* Tekke eelarve kinn в отче+ EELARVEARUANNE (Lisa 1, Lisa 5)+
         -- Сумма всех строк с бюджетом 4502* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 3040                    AS idx,
                '4502'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '4502'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '4502%'
              ) qry4502
         UNION ALL
         -- Строка 1502 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 1502* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 3050                    AS idx,
                '1502'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '1502'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '1502%'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '1502'
              ) qry1502
         UNION ALL
         -- Строка 1501* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)+
         -- Сумма всех строк с бюджетом 1501* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 4010                    AS idx,
                '1501'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '1501'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '1501%'
              ) qry1501
         UNION ALL
         -- Строка 1512 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 1512* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 4020                    AS idx,
                '1512'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '1512'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '1512%'
                  UNION ALL
-- Строка 1532 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) - Сумма всех строк с бюджетом 1532* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine + Сумма всех строк D710001 K 100100 с бюджетом 1532*в Päevaraamat =0
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '1512'
              ) qry1512
         UNION ALL
         -- Строка 1511* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 1511* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 4030                    AS idx,
                '1511'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '1511'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '1511%'
              ) qry1511
         UNION ALL
         -- Строка 1531* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)+
         -- Сумма всех строк с бюджетом 1531* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 4040                    AS idx,
                '1531'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '1531'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel LIKE '1531%'
              ) qry1511

         UNION ALL
         -- Строка 1532 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 1532* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 4050                    AS idx,
                '1532'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '1532'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '1532'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '1532'
              ) qry1511
         UNION ALL
         -- Строка 650* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5)+
         -- Сумма всех строк с бюджетом 650* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn =0
         SELECT 5010                    AS idx,
                '650'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '650'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel = '650'
              ) qry650
         UNION ALL
         -- Строка 655 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 655* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 5020                    AS idx,
                '655'                   AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '655'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '655'
                  UNION ALL
                  SELECT 0,
                         0,
                         0,
                         0,
                         CASE WHEN l_rekvid = 63 AND l_kond = 1 THEN 0 ELSE kassa END,
                         0
                  FROM qryJournal
                  WHERE artikkel = '655'
              ) qry650
         UNION ALL
         -- Строка 2586* Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) +
         -- Сумма всех строк с бюджетом 2586* в отчете Eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn  =0
         SELECT 6020                    AS idx,
                '2586'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '2586'
                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE ltrim(rtrim(artikkel)) = '2586'
/*                  UNION ALL
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryEelarveTaitmine
                  WHERE artikkel = '2586(A80)'
*/ ) qry2586
         UNION ALL
         -- Строка 2585 Tekke eelarve kinn в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
         -- Сумма всех строк с бюджетом 2585* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Tekke eelarve kinn=0
         SELECT 6010                    AS idx,
                '2585'                  AS nimetus,
                sum(eelarve)            AS eelarve,
                sum(eelarve_taps)       AS eelarve_taps,
                sum(eelarve_kassa)      AS eelarve_kassa,
                sum(eelarve_kassa_taps) AS eelarve_kassa_taps,
                sum(kassa)              AS kassa,
                sum(saldoandmik)        AS saldoandmik
         FROM (
                  SELECT eelarve,
                         eelarve_taps,
                         eelarve_kassa,
                         eelarve_kassa_taps,
                         kassa,
                         saldoandmik
                  FROM qryLisa1Lisa5
                  WHERE artikkel = '2585'
                  UNION ALL
                  SELECT -1 * eelarve,
                         -1 * eelarve_taps,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         -1 * saldoandmik
                  FROM qryTuludTaitmine
                  WHERE artikkel = '2585'
/*                  UNION ALL
                  --                      Строка 2585 Kassa täitmine (Lisa 5) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) -
                  --                      Сумма всех строк с бюджетом 2585* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art) Kassa täitmine -
                  --                      Сумма всех строк с бюджетом 2585 (А80)* в отчете Tulude eelarve täitmine (A, TT, RV, Tunnus, Art)  =0
                  SELECT 0,
                         0,
                         -1 * eelarve_kassa,
                         -1 * eelarve_kassa_taps,
                         -1 * kassa,
                         0
                  FROM qryTuludTaitmine
                  WHERE artikkel = '2585(A80)'
*/ ) qry2585
     ) qry
GROUP BY idx, nimetus
ORDER BY idx, CASE WHEN nimetus = 'PÕHITEGEVUSE TULUD KOKKU' THEN '1' ELSE nimetus END ;


$BODY$;

ALTER FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER)
    OWNER TO vlad;

GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER) TO PUBLIC;

GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER) TO dbkasutaja;

GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER) TO dbpeakasutaja;

GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER) TO dbvaatleja;

GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER) TO eelaktsepterja;

GRANT EXECUTE ON FUNCTION eelarve.lisa1_lisa5_kontrol(DATE, INTEGER, INTEGER) TO vlad;



/*
SELECT sum(saldoandmik) OVER (PARTITION BY nimetus) AS sa_kokku, *
FROM eelarve.lisa1_lisa5_kontrol('2024-03-31'::DATE, 63, 1)
--WHERE  nimetus like '3221%'
ORDER BY idx, nimetus
*/

/**/