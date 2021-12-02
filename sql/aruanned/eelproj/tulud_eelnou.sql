DROP FUNCTION IF EXISTS eelarve.tulud_eelnou(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tulud_eelnou(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id                  INTEGER,
        idx                      INTEGER,
        artikkel                 VARCHAR(20),
        nimetus                  VARCHAR(254),
        aasta_1_tekke_taitmine   NUMERIC(14, 2),
        aasta_2_tekke_taitmine   NUMERIC(14, 2),
        aasta_2_oodatav_taitmine NUMERIC(14, 2),
        aasta_3_eelnou           NUMERIC(14, 2),
        aasta_3_prognoos         NUMERIC(14, 2)
    )
AS
$$
BEGIN
    PERFORM fill_data_from_saldoandmik(l_kpv, l_rekvid, l_kond);

    RETURN QUERY
        WITH qryMaksuTulud AS (
            SELECT unnest(ARRAY ['3000', '3030', '3034', '3041', '3044', '3045', '3047']) AS kood
        ),
             qryTuludMuugist AS (
                 SELECT unnest(
                                ARRAY ['320', '3220', '3221', '3222', '3224', '3229', '3232', '3233', '3237', '3238']) AS kood
             ),
             qrySaadetudToetused AS (
                 SELECT unnest(ARRAY ['3500', '35200', '35201', '352']) AS kood
             ),
             qryMuudTegevusTulud AS (
                 SELECT unnest(
                                ARRAY ['38250', '38251', '38252', '38254', '3880', '3882', '3823', '3818', '3888']) AS kood
             ),
             qryTuludInvesteerimistegevusest AS (
                 SELECT unnest(ARRAY ['381', '3502', '1502', '1512', '1532', '655']) AS kood
             ),
             qryFinanseerimisTegevus AS (
                 SELECT unnest(ARRAY ['2585']) AS kood
             ),
             qryLikviidseteVaradeMuutus AS (
                 SELECT unnest(ARRAY ['100']) AS kood
             ),
             qryOmaTulud AS (
                 SELECT unnest(ARRAY ['3044','3045','3047','320','3220','3221','3222','3224','3229','3232','3233','3237','3238',
                     '3880','3823','3818','3888','381','1532','655']) AS kood
             ),
             qryArtikkel AS (
                 SELECT id, kood, l.nimetus
                 FROM libs.library l
                 WHERE library = 'TULUDEALLIKAD'
                   AND status < 3
                   AND kood IN (SELECT kood
                                FROM qryMaksuTulud
                                UNION ALL
                                SELECT kood
                                FROM qryTuludMuugist
                                UNION ALL
                                SELECT kood
                                FROM qrySaadetudToetused
                                UNION ALL
                                SELECT kood
                                FROM qryMuudTegevusTulud
                                UNION ALL
                                SELECT kood
                                FROM qryTuludInvesteerimistegevusest
                                UNION ALL
                                SELECT kood
                                FROM qryFinanseerimisTegevus
                                UNION ALL
                                SELECT kood
                                FROM qryLikviidseteVaradeMuutus
                 )
             ),
             -- Данные соответствуют данным Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) за предыдущий год за исключением
-- итоговых строк. Формулы итогов можно увидеть в соответствующих ячейках

             qryAasta1 AS (
                 SELECT s.rekvid,
                        a.kood           AS artikkel,
                        a.nimetus,
                        sum(s.kr - s.db) AS summa
                 FROM eelarve.saldoandmik s
                          INNER JOIN qryArtikkel a
                                     ON ((ltrim(rtrim((s.konto) :: TEXT)) ~~ ltrim(rtrim((a.kood) || '%' :: TEXT))))
                 WHERE aasta = year($1) - 1
                   AND kuu = 12
                   AND rekvid = (CASE
                                     WHEN $3 = 1 THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a
                 )
                   AND left(s.konto, 3) NOT IN ('352', '100', '381',  '655')
                   AND left(s.konto, 4) NOT IN ('3502', '1502', '1532', '2585')
                 GROUP BY s.rekvid, a.kood, a.nimetus
                 UNION ALL
                 -- 352
                 SELECT s.rekv_id                                                         AS rekvid,
                        a.kood                                                            AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '352', NULL, NULL, s.rekv_id, year(l_kpv) - 1) -
                        get_saldo('KD', '352000', NULL, NULL, s.rekv_id, year(l_kpv) - 1) -
                        get_saldo('KD', '352001', NULL, NULL, s.rekv_id, year(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '352'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 35200
                 SELECT s.rekv_id                                                         AS rekvid,
                        '35200'                                                           AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '352001', NULL, NULL, s.rekv_id, year(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '35200'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 35201
                 SELECT s.rekv_id                                                         AS rekvid,
                        '35201'                                                           AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '352000', NULL, NULL, s.rekv_id, year(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '35201'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 --3502
                 SELECT s.rekv_id                                                     AS rekvid,
                        '3502'                                                        AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '3502', '01', NULL, s.rekv_id, year(l_kpv) - 1) +
                        get_saldo('KD', '3502', '05', NULL, s.rekv_id, year(l_kpv) - 1) +
                        get_saldo('KD', '3502', '', NULL, s.rekv_id, year(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '3502'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 100
                 SELECT s.rekv_id                                                        AS rekvid,
                        '100'                                                            AS artikkel,
                        a.nimetus,
                        get_saldo('DK', '100', NULL, NULL, s.rekv_id, year(l_kpv) - 1)
                            - get_saldo('MDK', '100', NULL, NULL, s.rekv_id, year(l_kpv) - 1) +
                        get_saldo('DK', '101', NULL, NULL, s.rekv_id, year(l_kpv) - 1) -
                        get_saldo('MDK', '101', NULL, NULL, s.rekv_id, year(l_kpv) - 1) -
                        get_saldo('DK', '1019', NULL, NULL, s.rekv_id, year(l_kpv) - 1) +
                        get_saldo('MDK', '1019', NULL, NULL, s.rekv_id, year(l_kpv) - 1) +
                        get_saldo('DK', '151', NULL, NULL, s.rekv_id, year(l_kpv) - 1) -
                        get_saldo('MDK', '151', NULL, NULL, s.rekv_id, year(l_kpv) - 1) -
                        get_saldo('DK', '1519', NULL, NULL, s.rekv_id, year(l_kpv) - 1) +
                        get_saldo('MDK', '1519', NULL, NULL, s.rekv_id, year(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '100'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 1502
                 SELECT S.rekv_id                                       AS rekvid,
                        '1502'                                          AS artikkel,
                        a.nimetus,
                        get_saldo(
                                'KD',
                                '150',
                                '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '1502'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 1532
                 SELECT DISTINCT S.rekv_id                                                       AS rekvid,
                                 '1532'                                                          AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '1032', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) +
                                 get_saldo('KD', '1532', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '1532'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 381
                 SELECT DISTINCT S.rekv_id                                                      AS rekvid,
                                 '381'                                                          AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '381', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('KD', '3818', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('DK', '154', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('DK', '155', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('DK', '156', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('DK', '157', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('DK', '109', '02', NULL, s.rekv_id, YEAR(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '381'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)

                 UNION ALL
                 -- 2585
                 SELECT DISTINCT S.rekv_id                                                      AS rekvid,
                                 '2585'                                                         AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '208', '05', NULL, s.rekv_id, YEAR(l_kpv) - 1) +
                                 get_saldo('KD', '258', '05', NULL, s.rekv_id, YEAR(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '2585'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 655
                 SELECT DISTINCT S.rekv_id                                                         AS rekvid,
                                 '655'                                                             AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '652', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('KD', '652000', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('KD', '652030', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) +
                                 get_saldo('KD', '655', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) +
                                 get_saldo('KD', '658', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) -
                                 get_saldo('KD', '658950', NULL, NULL, s.rekv_id, YEAR(l_kpv) - 1) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '655'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
             ),
-- Данные соответствуют данным Tekke täitmine (Lisa 1) в отчете EELARVEARUANNE (Lisa 1, Lisa 5) по состоянию на 30.06.текущего года за исключением итоговых строк. Формулы итогов можно увидеть в соответствующих ячейках
             qryAasta2 AS (
                 SELECT s.rekvid,
                        a.kood           AS artikkel,
                        a.nimetus,
                        sum(s.kr - s.db) AS summa
                 FROM eelarve.saldoandmik s
                          INNER JOIN qryArtikkel a
                                     ON ((ltrim(rtrim((s.konto) :: TEXT)) ~~ ltrim(rtrim((a.kood) || '%' :: TEXT))))
                 WHERE aasta = year($1)
                   AND kuu = 6
                   AND rekvid = (CASE
                                     WHEN $3 = 1 THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a
                 )
                   AND left(s.konto, 3) NOT IN ('352', '100', '381',  '655')
                   AND left(s.konto, 4) NOT IN ('3502', '1502', '1532', '2585')
                 GROUP BY s.rekvid, a.kood, a.nimetus
                 UNION ALL
                 -- 352
                 SELECT s.rekv_id                                                     AS rekvid,
                        a.kood                                                        AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '352', NULL, NULL, s.rekv_id, year(l_kpv)) -
                        get_saldo('KD', '352000', NULL, NULL, s.rekv_id, year(l_kpv)) -
                        get_saldo('KD', '352001', NULL, NULL, s.rekv_id, year(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '352'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 35200
                 SELECT s.rekv_id                                                     AS rekvid,
                        '35200'                                                       AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '352001', NULL, NULL, s.rekv_id, year(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '35200'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 35201
                 SELECT s.rekv_id                                                     AS rekvid,
                        '35201'                                                       AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '352000', NULL, NULL, s.rekv_id, year(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '35201'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
--3502
                 UNION ALL
                 SELECT s.rekv_id                                                 AS rekvid,
                        '3502'                                                    AS artikkel,
                        a.nimetus,
                        get_saldo('KD', '3502', '01', NULL, s.rekv_id, year(l_kpv)) +
                        get_saldo('KD', '3502', '05', NULL, s.rekv_id, year(l_kpv)) +
                        get_saldo('KD', '3502', '', NULL, s.rekv_id, year(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '3502'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 100
                 SELECT s.rekv_id                                                    AS rekvid,
                        '100'                                                        AS artikkel,
                        a.nimetus,
                        get_saldo('DK', '100', NULL, NULL, s.rekv_id, year(l_kpv))
                            - get_saldo('MDK', '100', NULL, NULL, s.rekv_id, year(l_kpv)) +
                        get_saldo('DK', '101', NULL, NULL, s.rekv_id, year(l_kpv)) -
                        get_saldo('MDK', '101', NULL, NULL, s.rekv_id, year(l_kpv)) -
                        get_saldo('DK', '1019', NULL, NULL, s.rekv_id, year(l_kpv)) +
                        get_saldo('MDK', '1019', NULL, NULL, s.rekv_id, year(l_kpv)) +
                        get_saldo('DK', '151', NULL, NULL, s.rekv_id, year(l_kpv)) -
                        get_saldo('MDK', '151', NULL, NULL, s.rekv_id, year(l_kpv)) -
                        get_saldo('DK', '1519', NULL, NULL, s.rekv_id, year(l_kpv)) +
                        get_saldo('MDK', '1519', NULL, NULL, s.rekv_id, year(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '100'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 1502
                 SELECT S.rekv_id                                   AS rekvid,
                        '1502'                                      AS artikkel,
                        a.nimetus,
                        get_saldo(
                                'KD',
                                '150',
                                '02', NULL, s.rekv_id, YEAR(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '1502'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 1532
                 SELECT DISTINCT S.rekv_id                                                   AS rekvid,
                                 '1532'                                                      AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '1032', '02', NULL, s.rekv_id, YEAR(l_kpv)) +
                                 get_saldo('KD', '1532', '02', NULL, s.rekv_id, YEAR(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '1532'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
-- 381
                 SELECT DISTINCT S.rekv_id                                                  AS rekvid,
                                 '381'                                                      AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '381', NULL, NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('KD', '3818', NULL, NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('DK', '154', '02', NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('DK', '155', '02', NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('DK', '156', '02', NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('DK', '157', '02', NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('DK', '109', '02', NULL, s.rekv_id, YEAR(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '381'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)


                 UNION ALL
                 -- 2585
                 SELECT DISTINCT S.rekv_id                                                  AS rekvid,
                                 '2585'                                                     AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '208', '05', NULL, s.rekv_id, YEAR(l_kpv)) +
                                 get_saldo('KD', '258', '05', NULL, s.rekv_id, YEAR(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '2585'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
                 UNION ALL
                 -- 655
                 SELECT DISTINCT S.rekv_id                                                     AS rekvid,
                                 '655'                                                         AS artikkel,
                                 a.nimetus,
                                 get_saldo('KD', '652', NULL, NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('KD', '652000', NULL, NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('KD', '652030', NULL, NULL, s.rekv_id, YEAR(l_kpv)) +
                                 get_saldo('KD', '655', NULL, NULL, s.rekv_id, YEAR(l_kpv)) +
                                 get_saldo('KD', '658', NULL, NULL, s.rekv_id, YEAR(l_kpv)) -
                                 get_saldo('KD', '658950', NULL, NULL, s.rekv_id, YEAR(l_kpv)) AS summa
                 FROM qryArtikkel a,
                      (SELECT s.rekv_id
                       FROM get_asutuse_struktuur(l_rekvid) s) s
                 WHERE a.kood = '655'
                   AND s.rekv_id = (CASE
                                        WHEN $3 = 1 THEN s.rekv_id
                                        ELSE l_rekvid END)
             ),
             qryAasta3 AS (
-- Данные соответствуют данным Tekke eelarve täps в отчете EELARVEARUANNE (Lisa 1, Lisa 5) текущего года за исключением итоговых строк.
                 -- Формулы итогов можно увидеть в соответствующих ячейках
                 -- eelarve taps
                 SELECT e.rekvid,
                        e.kood5      AS artikkel,
                        sum(e.summa) AS summa
                 FROM eelarve.eelarve e
                 WHERE rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND e.rekvid IN (SELECT a.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) a)
                   AND aasta = year($1)
                   AND (e.kpv IS NOT NULL AND e.kpv <= l_kpv)
                   AND e.status <> 3
                   AND kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5
             ),
             qryAasta4 AS (
-- Сумма всех строк с данным Art Tekke põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        a.kood     AS artikkel,
                        a.nimetus,
                        sum(summa) AS summa
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                          INNER JOIN qryArtikkel a ON a.kood = t1.kood5
                 WHERE t.aasta = year(l_kpv) + 1
                   AND t.status IN (2, 3)
                   AND rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a)

                 GROUP BY a.kood, a.nimetus, t.rekvid
             ),
             qryAasta5 AS (
-- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        a.kood           AS artikkel,
                        a.nimetus,
                        sum(summa_kassa) AS summa
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                          INNER JOIN qryArtikkel a ON a.kood = t1.kood5
                 WHERE t.aasta = year(l_kpv) + 1
                   AND t.status = 2
                   AND rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a)

                 GROUP BY a.kood, a.nimetus, t.rekvid
             ),
             qryPreReport AS (
                 SELECT qry.rekv_id,
                        CASE
                            WHEN qry.artikkel IN (SELECT kood FROM qryMaksuTulud) THEN 100
                            WHEN qry.artikkel IN (SELECT kood FROM qryTuludMuugist) THEN 200
                            WHEN qry.artikkel IN (SELECT kood FROM qrySaadetudToetused) THEN 300
                            WHEN qry.artikkel IN (SELECT kood FROM qryMuudTegevusTulud) THEN 400
                            WHEN qry.artikkel IN (SELECT kood FROM qryTuludInvesteerimistegevusest) THEN 500
                            WHEN qry.artikkel IN (SELECT kood FROM qryFinanseerimisTegevus) THEN 600
                            WHEN qry.artikkel IN (SELECT kood FROM qryLikviidseteVaradeMuutus) THEN 700
                            ELSE 900 END                  AS idx,
                        qry.artikkel,
                        qry.nimetus,
                        sum(qry.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
                        sum(qry.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
                        sum(qry.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
                        sum(qry.aasta_3_eelnou)           AS aasta_3_eelnou,
                        sum(qry.aasta_3_prognoos)         AS aasta_3_prognoos
                 FROM (
                          SELECT rekvid            AS rekv_id,
                                 a.artikkel:: VARCHAR(20),
                                 a.nimetus:: VARCHAR(254),
                                 summa             AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2) AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2) AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2) AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2) AS aasta_3_prognoos
                          FROM qryAasta1 a
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 a.artikkel:: VARCHAR(20),
                                 a.nimetus:: VARCHAR(254),
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 summa::NUMERIC(14, 2) AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)     AS aasta_3_prognoos
                          FROM qryAasta2 a
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 q.artikkel:: VARCHAR(20),
                                 a.nimetus:: VARCHAR(254),
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 summa::NUMERIC(14, 2) AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)     AS aasta_3_prognoos
                          FROM qryAasta3 q
                                   INNER JOIN qryArtikkel a ON q.artikkel = a.kood
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 q.artikkel:: VARCHAR(20),
                                 q.nimetus:: VARCHAR(254),
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 summa::NUMERIC(14, 2) AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)     AS aasta_3_prognoos
                          FROM qryAasta4 q
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 q.artikkel:: VARCHAR(20),
                                 q.nimetus:: VARCHAR(254),
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_3_eelnou,
                                 summa::NUMERIC(14, 2) AS aasta_3_prognoos
                          FROM qryAasta5 q
                      ) qry
                 GROUP BY qry.rekv_id, qry.artikkel, qry.nimetus),
             qryReport AS (
                 SELECT *
                 FROM qryPreReport
                 UNION ALL
                 SELECT q.rekv_id,
                        100                             AS idx,
                        ''                              AS artikkel,
                        upper('Maksutulud')             AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)           AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)         AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryMaksuTulud)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        200                                        AS idx,
                        ''                                         AS artikkel,
                        upper('Tulud kaupade ja teenuste müügist') AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)              AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)              AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine)            AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)                      AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)                    AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryTuludMuugist)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        300                             AS idx,
                        ''                              AS artikkel,
                        upper('Saadud toetused')        AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)           AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)         AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qrySaadetudToetused)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        400                             AS idx,
                        ''                              AS artikkel,
                        upper('Muud tegevustulud')      AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)           AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)         AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryMuudTegevusTulud)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        500                                    AS idx,
                        ''                                     AS artikkel,
                        upper('Tulud investeerimistegevusest') AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)                AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryTuludInvesteerimistegevusest)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        600                             AS idx,
                        ''                              AS artikkel,
                        upper('Finanseerimistegevus')   AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)           AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)         AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryFinanseerimisTegevus)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        700                                AS idx,
                        ''                                 AS artikkel,
                        upper('Likviidsete varade muutus') AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)      AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)      AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine)    AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)              AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)            AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryLikviidseteVaradeMuutus)
                 GROUP BY q.rekv_id
                 UNION ALL
                 SELECT q.rekv_id,
                        800                             AS idx,
                        ''                              AS artikkel,
                        upper('Omatulud')               AS nimetus,
                        sum(q.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
                        sum(q.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
                        sum(q.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
                        sum(q.aasta_3_eelnou)           AS aasta_3_eelnou,
                        sum(q.aasta_3_prognoos)         AS aasta_3_prognoos
                 FROM qryPreReport q
                 WHERE q.artikkel IN (SELECT kood FROM qryOmaTulud)
                 GROUP BY q.rekv_id
             )
        SELECT q.rekv_id,
               q.idx,
               q.artikkel,
               q.nimetus,
               q.aasta_1_tekke_taitmine,
               q.aasta_2_tekke_taitmine,
               q.aasta_2_oodatav_taitmine,
               q.aasta_3_eelnou,
               q.aasta_3_prognoos
        FROM qryReport q
        UNION ALL
        SELECT 999999                          AS rekv_id,
               q.idx,
               q.artikkel,
               q.nimetus,
               sum(q.aasta_1_tekke_taitmine)   AS aasta_1_tekke_taitmine,
               sum(q.aasta_2_tekke_taitmine)   AS aasta_2_tekke_taitmine,
               sum(q.aasta_2_oodatav_taitmine) AS aasta_2_oodatav_taitmine,
               sum(q.aasta_3_eelnou)           AS aasta_3_eelnou,
               sum(q.aasta_3_prognoos)         AS aasta_3_prognoos
        FROM qryReport q
        WHERE l_kond = 1
        GROUP BY q.idx, q.artikkel, q.nimetus;

END
$$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou(DATE, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou(DATE, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou(DATE, INTEGER, INTEGER) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou(DATE, INTEGER, INTEGER) TO dbvaatleja;


/*

SELECT *
FROM eelarve.tulud_eelnou('2021-11-30'::DATE, 63:: INTEGER, 1)
where artikkel like '655%'
order by idx, artikkel

select * from tmp_andmik
*/


