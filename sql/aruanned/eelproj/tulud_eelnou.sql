DROP FUNCTION IF EXISTS eelarve.tulud_eelnou(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulud_eelnou_(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.tulud_eelnou(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id                         INTEGER,
        idx                             INTEGER,
        artikkel                        VARCHAR(20),
        tegev                           VARCHAR(20),
        allikas                         VARCHAR(20),
        tunnus                          VARCHAR(20),
        aasta_1_tekke_taitmine          NUMERIC(14, 2),
        aasta_2_tekke_taitmine          NUMERIC(14, 2),
        aasta_2_oodatav_taitmine        NUMERIC(14, 2),
        aasta_3_eelnou                  NUMERIC(14, 2),
        aasta_3_prognoos                NUMERIC(14, 2),
        eelarve_tekkepohine_kinnitatud  NUMERIC(14, 2),
        eelarve_tekkepohine_tapsustatud NUMERIC(14, 2),
        selg                            TEXT
    )
AS
$$
DECLARE
    a_maksud                       TEXT[] = ARRAY ['3000', '3030', '3034', '3041', '3044', '3045', '3047'];
    a_tuluMuugist                  TEXT[] = ARRAY ['320', '3220', '3221', '3222', '3224', '3229', '3232', '3233', '3237', '3238'];
    a_SaadetudToetused             TEXT[] = ARRAY ['3500', '35200', '35201', '352'];
    a_MuudTegevusTulud             TEXT[] = ARRAY ['38250', '38251', '38252', '38254', '3880', '3882', '3823', '3818', '3888'];
    a_TuludInvesteerimistegevusest TEXT[] = ARRAY ['381', '3502', '1502', '1512', '1532', '655','1032'];
    a_FinanseerimisTegevus         TEXT[] = ARRAY ['2585'];
    a_LikviidseteVaradeMuutus      TEXT[] = ARRAY ['100'];
    a_OmaTulud                     TEXT[] = ARRAY ['3044','3045','3047','320','3220','3221','3222','3224','3229','3232','3233','3237','3238',
        '3880','3823','3818','3888','381','1532','655'];
BEGIN
    -- оздаем выборку данных для отчета
    -- eelmise aasta
--    INSERT INTO tmp_andmik (tyyp, konto, allikas, tegev, artikkel, rahavoog, tunnus, tegelik, aasta, kuu, rekv_id)
    RETURN QUERY
        WITH qryArtikkel AS (
            SELECT id, kood, l.nimetus
            FROM libs.library l
            WHERE library = 'TULUDEALLIKAD'
              AND status < 3
              AND kood IN (SELECT unnest(a_maksud)
                           UNION ALL
                           SELECT unnest(a_tuluMuugist)
                           UNION ALL
                           SELECT unnest(a_SaadetudToetused)
                           UNION ALL
                           SELECT unnest(a_MuudTegevusTulud)
                           UNION ALL
                           SELECT *
                           FROM (SELECT unnest(a_TuludInvesteerimistegevusest) AS kood) qry
                           UNION ALL
                           SELECT unnest(a_FinanseerimisTegevus)
                           UNION ALL
                           SELECT unnest(a_LikviidseteVaradeMuutus)
            )
        ),
             qryTaotlused AS (SELECT t1.kood5 AS artikkel, t.rekvid
                              FROM eelarve.taotlus t
                                       INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                              WHERE t1.tunnus IS NOT NULL
                                AND NOT empty(t1.tunnus)
                                AND t.status IN (2, 3)
                                AND t.rekvid = (CASE
                                                    WHEN l_kond = 1 THEN t.rekvid
                                                    ELSE l_rekvid END)
                                AND t.rekvid IN (SELECT r.rekv_id
                                                 FROM get_asutuse_struktuur(l_rekvid) r)
                                AND t.aasta IN (year(l_kpv) - 1, year(l_kpv))
                              GROUP BY t.aasta, t.rekvid, t1.kood5
                              HAVING (count(*) > 0)
             ),
             tmp_andmik AS (
                 SELECT s.tyyp,
                        s.konto,
                        s.allikas,
                        s.tegev,
                        s.artikkel       AS artikkel,
                        s.rahavoog,
                        s.tunnus,
                        sum(s.kr - s.db) AS tegelik,
                        year(l_kpv) - 1  AS aasta,
                        12               AS kuu,
                        s.rekv_id
                 FROM (
                          SELECT 2         AS tyyp,
                                 j1.deebet AS konto,
                                 j1.kood2  AS allikas,
                                 j1.kood1  AS tegev,
                                 j1.kood5  AS artikkel,
                                 j1.kood3  AS rahavoog,
                                 j1.tunnus,
                                 j1.summa  AS db,
                                 0         AS kr,
                                 d.rekvid  AS rekv_id
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                                   INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                              -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id

                                   INNER JOIN (
                              SELECT kood
                              FROM qryArtikkel
                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
                          ) a
                                              ON ((ltrim(rtrim((j1.deebet) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))

--                      LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id
                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv) - 1, 12, 31)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования                            
                            AND d.status <> 3
                          UNION ALL
                          SELECT 2,
                                 j1.kreedit AS konto,
                                 j1.kood2   AS allikas,
                                 j1.kood1   AS tegev,
                                 j1.kood5   AS artikkel,
                                 j1.kood3   AS rahavoog,
                                 j1.tunnus,
                                 0          AS db,
                                 j1.summa   AS kr,
                                 d.rekvid   AS rekv_id
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                                   INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                                   INNER JOIN (
                              SELECT kood
                              FROM qryArtikkel
                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
                          ) a
                                              ON ((ltrim(rtrim((j1.kreedit) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))

                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id
                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv) - 1, 12, 31)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования
                            
                            AND d.status <> 3
                      ) s

                 GROUP BY s.tyyp, s.konto, s.tegev, s.allikas, s.rahavoog, s.artikkel, s.tunnus, s.rekv_id
                 UNION ALL
--  текущий год
                 SELECT s.tyyp,
                        s.konto,
                        s.allikas,
                        s.tegev,
                        s.artikkel,
                        s.rahavoog,
                        s.tunnus,
                        sum(s.kr - s.db) AS tegelik,
                        year(l_kpv)      AS aasta,
                        6                AS kuu,
                        s.rekv_id
                 FROM (
                          SELECT 2                       AS tyyp,
                                 j1.deebet               AS konto,
                                 j1.kood2                AS allikas,
                                 j1.kood1                AS tegev,
                                 a.kood                  AS artikkel,
                                 j1.kood3 :: VARCHAR(20) AS rahavoog,
                                 j1.tunnus,
                                 j1.summa                AS db,
                                 0                       AS kr,
                                 d.rekvid                AS rekv_id
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                                   INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id
                                   INNER JOIN (
                              SELECT kood
                              FROM qryArtikkel
                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
                          ) a
                                              ON ((ltrim(rtrim((j1.deebet) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))

                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv), 06, 30)
                            AND coalesce(alg.kpv, j.kpv) >= make_date(year(l_kpv), 01, 01)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования
                            
                            AND d.status <> 3
                          UNION ALL
                          SELECT 2,
                                 j1.kreedit            AS konto,
                                 j1.kood2              AS allikas,
                                 j1.kood1              AS tegev,
                                 a.kood                AS artikkel,
                                 j1.kood3::VARCHAR(20) AS rahavoog,
                                 j1.tunnus,
                                 0                     AS db,
                                 j1.summa              AS kr,
                                 d.rekvid              AS rekv_id
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                                   INNER JOIN docs.journal1 j1 ON j.id = j1.parentid
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id
                                   INNER JOIN (
                              SELECT kood
                              FROM qryArtikkel
                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
                          ) a
                                              ON ((ltrim(rtrim((j1.kreedit) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))

                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv), 06, 30)
                            AND coalesce(alg.kpv, j.kpv) >= make_date(year(l_kpv), 01, 01)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования
                            
                            AND d.status <> 3
                      ) s

                 GROUP BY s.tyyp, s.konto, s.tegev, s.allikas, s.rahavoog, s.artikkel, s.tunnus, s.rekv_id
             ),
             qryAasta1 AS (
                 SELECT s.rekv_id      AS rekvid,
                        s.artikkel     AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas      AS allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                   AND left(s.konto, 3) NOT IN ('352', '100', '381', '655')
                   AND left(s.konto, 4) NOT IN ('3502', '1502', '1032', '1532', '2585')
                 GROUP BY s.rekv_id, s.artikkel, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 352
                 SELECT S.rekv_id    AS rekvid,
                        '352'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas    AS allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas      AS allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '352%'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas           AS allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE konto LIKE '352000%'
                            AND aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas           AS allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '352001%'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 35200
                 --         get_saldo('KD', '352001', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT s.rekv_id      AS rekvid,
                        '35200'        AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas      AS allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                   AND s.konto LIKE '352001%'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 35201
                 --         get_saldo('KD', '352000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT s.rekv_id      AS rekvid,
                        '35201'        AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas      AS allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                   AND s.konto LIKE '352000%'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 --3502
--         get_saldo('KD', '3502', '01', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT S.rekv_id    AS rekvid,
                        '3502'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas    AS allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas      AS allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '3502%'
                            AND (s.rahavoog IN ('01', '05') OR coalesce(rahavoog, '') = '')
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 100
--         get_saldo('DK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
--         - get_saldo('MDK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('DK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('MDK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('MDK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('DK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('MDK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('MDK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '100'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa, -- так как у нас К-Д
                        1            AS idx
                 FROM (
                          -- get_saldo('DK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '100%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- - get_saldo('MDK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '100%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- + get_saldo('DK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '101%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- - get_saldo('MDK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '101%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- - get_saldo('DK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1019%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- + get_saldo('MDK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1019%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- + get_saldo('DK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '151%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          --  - get_saldo('MDK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '151%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
                          -- - get_saldo('DK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1519%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                          UNION ALL
-- + get_saldo('MDK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1519%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.tegev, s.allikas
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 --         '1502'
--         get_saldo('KD','150','02', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT s.rekv_id      AS rekvid,
                        '1502'         AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                   AND s.konto LIKE '150%'
                   AND s.rahavoog = '02'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 1512
-- get_saldo('KD', '151910', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '101900', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1512'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '151910%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '101900%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 1532
--         get_saldo('KD', '1032', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '1532', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1532'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '1032%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '1532%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 381
--         get_saldo('KD', '381', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '154', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '155', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '156', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '157', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '109', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '381'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- get_saldo('KD', '381', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '381%'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          -- - get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '3818%'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          -- - get_saldo('DK', '154', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '155', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '156', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- -  get_saldo('DK', '157', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '109', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE left(s.konto, 3) IN ('154', '155', '156', '157', '109')
                            AND rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 3818
-- get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT s.rekv_id      AS rekvid,
                        '3818'         AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                   AND s.konto LIKE '3818%'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 2585
-- get_saldo('KD', '208', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '258', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '2585'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '208%'
                            AND s.rahavoog = '05'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '258%'
                            AND s.rahavoog = '05'
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 655
--         get_saldo('KD', '652', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '652000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '652030', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '655', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '658', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '658950', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '655'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- - get_saldo('KD', '652000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '652030', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '658950', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE left(s.konto, 6) IN ('652000', '652030', '658950')
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          --  + get_saldo('KD', '652', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '655', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '658', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE left(s.konto, 3) IN ('655', '658', '652')
                            AND s.aasta = YEAR(l_kpv) - 1
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
             ),
             qryAasta2 AS (
                 SELECT s.rekv_id      AS rekvid,
                        s.artikkel     AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv)
                   AND left(s.konto, 3) NOT IN ('352', '100', '381', '655')
                   AND left(s.konto, 4) NOT IN ('3502', '1502', '1532', '2585', '1032')
                 GROUP BY s.rekv_id, s.artikkel, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 352
                 SELECT S.rekv_id    AS rekvid,
                        '352'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '352%'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE konto LIKE '352000%'
                            AND aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '352001%'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 35200
                 SELECT s.rekv_id      AS rekvid,
                        '35200'        AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv)
                   AND s.konto LIKE '352001%'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 35201
                 --         get_saldo('KD', '352000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT s.rekv_id      AS rekvid,
                        '35201'        AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv)
                   AND s.konto LIKE '352000%'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 --3502
--         get_saldo('KD', '3502', '01', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT S.rekv_id    AS rekvid,
                        '3502'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '3502%'
                            AND (s.rahavoog IN ('01', '05') OR coalesce(rahavoog, '') = '')
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 100
--         get_saldo('DK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
--         - get_saldo('MDK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('DK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('MDK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('MDK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('DK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('MDK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('MDK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '100'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa, -- так как у нас К-Д
                        1            AS idx
                 FROM (
                          -- get_saldo('DK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '100%'
                            AND s.aasta = YEAR(l_kpv)
                            AND s.kuu = 6
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- - get_saldo('MDK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '100%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- + get_saldo('DK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '101%'
                            AND s.aasta = YEAR(l_kpv)
                            AND s.kuu = 6
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- - get_saldo('MDK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '101%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- - get_saldo('DK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1019%'
                            AND s.aasta = YEAR(l_kpv)
                            AND s.kuu = 6
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- + get_saldo('MDK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1019%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- + get_saldo('DK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '151%'
                            AND s.aasta = YEAR(l_kpv)
                            AND s.kuu = 6
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          --  - get_saldo('MDK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '151%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
                          -- - get_saldo('DK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid              AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                    AS tunnus,
                                 -1 * sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1519%'
                            AND s.aasta = YEAR(l_kpv)
                            AND s.kuu = 6
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                          UNION ALL
-- + get_saldo('MDK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid         AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''               AS tunnus,
                                 sum(s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1519%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)

                          GROUP BY s.rekvid, s.allikas, s.tegev
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 --         '1502'
--         get_saldo('KD','150','02', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT s.rekv_id      AS rekvid,
                        '1502'         AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv)
                   AND s.konto LIKE '150%'
                   AND s.rahavoog = '02'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 1512
-- get_saldo('KD', '151910', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '101900', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1512'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '151910%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '101900%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 1532
--         get_saldo('KD', '1032', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '1532', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1532'       AS artikkel,
                        S.tegev      AS tegev,
                        s.allikas,
                        S.tunnus,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 s.allikas,
                                 S.tunnus,
                                 sum(S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE '1032%'
                            AND S.rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv)
                          GROUP BY S.rekv_id, S.tegev, s.allikas, S.tunnus
                          UNION ALL
                          SELECT S.rekv_id,
                                 S.tegev,
                                 s.allikas,
                                 S.tunnus,
                                 sum(S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE '1532%'
                            AND S.rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv)
                          GROUP BY S.rekv_id, S.tegev, s.allikas, S.tunnus
                      ) S
                 GROUP BY S.rekv_id, S.tegev, s.allikas, S.tunnus
                 UNION ALL
                 -- 381
--         get_saldo('KD', '381', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '154', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '155', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '156', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '157', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('DK', '109', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '381'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- get_saldo('KD', '381', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '381%'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          -- - get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '3818%'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          -- - get_saldo('DK', '154', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '155', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '156', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- -  get_saldo('DK', '157', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '109', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE left(s.konto, 3) IN ('154', '155', '156', '157', '109')
                            AND ltrim(rtrim(rahavoog)) = '02'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 3818
-- get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT s.rekv_id      AS rekvid,
                        '3818'         AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv)
                   AND s.konto LIKE '3818%'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 2585
-- get_saldo('KD', '208', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '258', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '2585'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '208%'
                            AND s.rahavoog = '05'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '258%'
                            AND s.rahavoog = '05'
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                 UNION ALL
                 -- 655
--         get_saldo('KD', '652', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '652000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '652030', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '655', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '658', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1) -
--         get_saldo('KD', '658950', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '655'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- - get_saldo('KD', '652000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '652030', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '658950', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 -1 * sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE left(s.konto, 6) IN ('652000', '652030', '658950')
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                          UNION ALL
                          --  + get_saldo('KD', '652', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '655', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '658', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 sum(s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE left(s.konto, 3) IN ('655', '658', '652')
                            AND s.aasta = YEAR(l_kpv)
                          GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus
             ),
             -- пока не нужен
/*             qryAasta3 AS (
                 -- Данные соответствуют данным Tekke eelarve täps в отчете EELARVEARUANNE (Lisa 1, Lisa 5) текущего года за исключением итоговых строк.
                 -- Формулы итогов можно увидеть в соответствующих ячейках
                 -- eelarve taps

                 SELECT e.rekvid,
                        e.kood5      AS artikkel,
                        e.kood1      AS tegev,
                        e.tunnus     AS tunnus,
                        sum(e.summa) AS summa
                 FROM eelarve.eelarve e
                 WHERE rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND e.rekvid IN (SELECT a.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) a)
                   AND aasta = YEAR($1)
                   AND (e.kpv IS NULL AND e.kpv <= l_kpv)
                   AND e.status <> 3
                   AND kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.tunnus
             ),
*/ -- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine kinnitatud
             -- текущего года

             qryAasta4 AS (
                 -- Сумма всех строк с данным Art Tekke põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5   AS artikkel,
                        t1.kood1   AS tegev,
                        t1.kood2   AS allikas,
                        t1.tunnus,
                        sum(summa) AS summa,
                        NULL::TEXT AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                 WHERE t.aasta = YEAR(l_kpv) + 1
                   AND t.status IN (2, 3)
                   AND rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a)
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )

                 GROUP BY t1.kood5, t1.kood1, t1.kood2, t1.tunnus, t.rekvid
             ),
             qryAasta5 AS (
                 -- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 -- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5                                     AS artikkel,
                        t1.kood1                                     AS tegev,
                        t1.kood2                                     AS allikas,
                        t1.tunnus,
                        sum(summa_kassa)                             AS summa,
                        string_agg(ltrim(rtrim(t1.selg)), ' '::TEXT) AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                 WHERE t.aasta = YEAR(l_kpv) + 1
                   AND t.status = 2
                   AND rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a)
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )

                 GROUP BY t1.kood5, t1.kood1, t1.kood2, t1.tunnus, t.rekvid
             ),
             qryAasta6 AS (
-- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine kinnitatud
-- текущего года

                 SELECT e.rekvid,
                        e.kood5      AS artikkel,
                        e.kood1      AS tegev,
                        e.kood2      AS allikas,
                        e.tunnus     AS tunnus,
                        sum(e.summa) AS summa
                 FROM eelarve.eelarve e
                 WHERE rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND e.rekvid IN (SELECT a.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) a)
                   AND aasta = YEAR($1)
                   AND e.kpv IS NULL
                   AND e.status <> 3
                   AND kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.kood2, e.tunnus
             ),
             qryAasta7 AS (
-- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine täpsustatud
-- текущего года seisuga 30.06.2022

                 SELECT e.rekvid,
                        e.kood5      AS artikkel,
                        e.kood1      AS tegev,
                        e.kood2      AS allikas,
                        e.tunnus     AS tunnus,
                        sum(e.summa) AS summa
                 FROM eelarve.eelarve e
                 WHERE rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND e.rekvid IN (SELECT a.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) a)
                   AND aasta = YEAR($1)
                   AND (e.kpv IS NULL OR e.kpv <= make_date(YEAR($1), 06, 30))
                   AND e.status <> 3
                   AND kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.kood2, e.tunnus
             ),

             preReport AS (
                 SELECT qry.rekvid,
                        qry.artikkel,
                        qry.tegev,
                        qry.allikas,
                        CASE WHEN t.artikkel IS NULL THEN '' ELSE qry.tunnus END AS tunnus,
                        sum(qry.aasta_1_tekke_taitmine)                          AS aasta_1_tekke_taitmine,
                        sum(qry.aasta_2_tekke_taitmine)                          AS aasta_2_tekke_taitmine,
                        sum(qry.aasta_2_oodatav_taitmine)                        AS aasta_2_oodatav_taitmine,
                        sum(qry.aasta_3_eelnou)                                  AS aasta_3_eelnou,
                        sum(qry.aasta_3_prognoos)                                AS aasta_3_prognoos,
                        sum(qry.eelarve_tekkepohine_kinnitatud)                  AS eelarve_tekkepohine_kinnitatud,
                        sum(qry.eelarve_tekkepohine_tapsustatud)                 AS eelarve_tekkepohine_tapsustatud,
                        string_agg(qry.selg, ' ')                                AS selg
                 FROM (
                          SELECT q.rekvid           AS rekvid,
                                 q.idx,
                                 q.artikkel,
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.summa            AS aasta_1_tekke_taitmine,
                                 0                  AS aasta_2_tekke_taitmine,
                                 0                  AS aasta_2_oodatav_taitmine,
                                 0                  AS aasta_3_eelnou,
                                 0                  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)     eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT         AS selg
                          FROM qryAasta1 q
                          UNION ALL
                          SELECT q.rekvid           AS rekvid,
                                 q.idx,
                                 q.artikkel,
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 0                  AS aasta_1_tekke_taitmine,
                                 q.summa            AS aasta_2_tekke_taitmine,
                                 0                  AS aasta_2_oodatav_taitmine,
                                 0                  AS aasta_3_eelnou,
                                 0                  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)     eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT         AS selg
                          FROM qryAasta2 q
/*                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 2                     AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.tunnus,
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 summa::NUMERIC(14, 2) AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)     AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2)    AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)        eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT            AS selg
                          FROM qryAasta3 q
*/
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 2                     AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 summa::NUMERIC(14, 2) AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)     AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2)    AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)        eelarve_tekkepohine_tapsustatud,
                                 ltrim(rtrim(q.selg))::TEXT
                          FROM qryAasta4 q
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 2                     AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_3_eelnou,
                                 summa::NUMERIC(14, 2) AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2)    AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)        eelarve_tekkepohine_tapsustatud,
                                 ltrim(rtrim(q.selg))::TEXT
                          FROM qryAasta5 q
                          UNION ALL
                          SELECT rekvid                 AS rekv_id,
                                 2                      AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 0::NUMERIC(14, 2)      AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)      AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)      AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)      AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)      AS aasta_3_prognoos,
                                 summa:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)         eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT             AS selg
                          FROM qryAasta6 q
                          UNION ALL
                          SELECT rekvid             AS rekv_id,
                                 2                  AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 0::NUMERIC(14, 2)  AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 summa::NUMERIC(14, 2) eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT         AS selg
                          FROM qryAasta7 q
                      ) qry
                          LEFT OUTER JOIN qryTaotlused t ON t.artikkel = qry.artikkel AND t.rekvid = qry.rekvid
                 GROUP BY qry.rekvid, qry.artikkel, qry.tegev, qry.allikas,
                          CASE WHEN t.artikkel IS NULL THEN '' ELSE qry.tunnus END),
             qryReport AS (
                 SELECT s.rekvid:: INTEGER,
                        r.parentid,
                        CASE
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_maksud THEN 100
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_tuluMuugist THEN 200
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_SaadetudToetused THEN 300
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_MuudTegevusTulud THEN 400
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_TuludInvesteerimistegevusest THEN 500
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_FinanseerimisTegevus THEN 600
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_LikviidseteVaradeMuutus THEN 700
                            ELSE 900 END                     AS idx,
                        s.artikkel::VARCHAR(20),
                        coalesce(s.tegev, '')::VARCHAR(20)   AS tegev,
                        coalesce(s.allikas, '')::VARCHAR(20) AS allikas,
                        coalesce(s.tunnus, ''):: VARCHAR(20) AS tunnus,
                        s.aasta_1_tekke_taitmine:: NUMERIC(14, 2),
                        s.aasta_2_tekke_taitmine:: NUMERIC(14, 2),
                        s.aasta_2_oodatav_taitmine:: NUMERIC(14, 2),
                        s.aasta_3_eelnou:: NUMERIC(14, 2),
                        s.aasta_3_prognoos::NUMERIC(14, 2),
                        s.eelarve_tekkepohine_kinnitatud::NUMERIC(14, 2),
                        s.eelarve_tekkepohine_tapsustatud::NUMERIC(14, 2),
                        s.selg                               AS selg
                 FROM preReport s
                          INNER JOIN qryArtikkel l ON l.kood = s.artikkel
                          INNER JOIN ou.rekv r ON r.id = s.rekvid
             ),
             -- kond
             qryKond AS (
                 SELECT s.idx,
                        999999:: INTEGER                                       AS rekv_id,
                        coalesce(s.tunnus, ''):: VARCHAR(20)                   AS tunnus,
                        coalesce(s.tegev, '')::VARCHAR(20)                     AS tegev,
                        coalesce(s.allikas, '')::VARCHAR(20)                   AS allikas,
                        s.artikkel::VARCHAR(20),
                        sum(s.aasta_1_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_1_tekke_taitmine,
                        sum(s.aasta_2_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_2_tekke_taitmine,
                        sum(s.aasta_2_oodatav_taitmine):: NUMERIC(14, 2)       AS aasta_2_oodatav_taitmine,
                        sum(s.aasta_3_eelnou):: NUMERIC(14, 2)                 AS aasta_3_eelnou,
                        sum(s.aasta_3_prognoos)::NUMERIC(14, 2)                AS aasta_3_prognoos,
                        sum(s.eelarve_tekkepohine_kinnitatud)::NUMERIC(14, 2)  AS eelarve_tekkepohine_kinnitatud,
                        sum(s.eelarve_tekkepohine_tapsustatud)::NUMERIC(14, 2) AS eelarve_tekkepohine_tapsustatud,
                        NULL::TEXT                                             AS selg
                 FROM qryReport s
                 GROUP BY s.artikkel, s.idx, s.tunnus, s.tegev, s.allikas
             ),
             report AS (
                 SELECT qryReport.idx,
                        CASE
                            WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvId
                            ELSE l_rekvid END                          AS rekv_id,
                        qryReport.tunnus,
                        qryReport.tegev,
                        qryReport.allikas,
                        qryReport.artikkel,
                        sum(qryReport.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        sum(qryReport.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        sum(qryReport.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        sum(qryReport.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        sum(qryReport.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        sum(qryReport.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        sum(qryReport.aasta_3_prognoos)                AS aasta_3_prognoos,
                        string_agg(qryReport.selg, ',')                AS selg
                 FROM qryReport
                 WHERE qryReport.artikkel NOT IN ('100')
                 GROUP BY qryReport.idx,
                          (CASE WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvid ELSE l_rekvid END),
                          qryReport.tunnus, qryReport.tegev, qryReport.allikas, qryReport.artikkel
                 UNION ALL
                 SELECT 0                                              AS idx,
                        CASE
                            WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvId
                            ELSE l_rekvid END                          AS rekv_id,
                        ''                                             AS tunnus,
                        left(qryReport.tegev, 2)::VARCHAR(20)          AS tegev,
                        ''                                             AS allikas,
                        ''                                             AS artikkel,
                        sum(qryReport.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        sum(qryReport.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        sum(qryReport.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        sum(qryReport.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        sum(qryReport.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        sum(qryReport.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        sum(qryReport.aasta_3_prognoos)                AS aasta_3_prognoos,
                        ''                                             AS selg
                 FROM qryReport
                 WHERE NOT empty(qryReport.tegev)
                 GROUP BY (CASE WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvid ELSE l_rekvid END),
                          left(qryReport.tegev, 2)
                 UNION ALL
                 SELECT 0                                            AS idx,
                        qryKond.rekv_id                              AS rekv_id,
                        ''                                           AS tunnus,
                        left(qryKond.tegev, 2)::VARCHAR(20)          AS tegev,
                        ''                                           AS allikas,
                        ''                                           AS artikkel,
                        sum(qryKond.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        sum(qryKond.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        sum(qryKond.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        sum(qryKond.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        sum(qryKond.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        sum(qryKond.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        sum(qryKond.aasta_3_prognoos)                AS aasta_3_prognoos,
                        ''                                           AS selg
                 FROM qryKond
                 WHERE NOT empty(qryKond.tegev)
                 GROUP BY qryKond.rekv_id, left(qryKond.tegev, 2)
                 UNION ALL

                 SELECT qryKond.idx,
                        qryKond.rekv_id,
                        qryKond.tunnus,
                        qryKond.tegev,
                        qryKond.allikas,
                        qryKond.artikkel,
                        qryKond.aasta_1_tekke_taitmine,
                        qryKond.eelarve_tekkepohine_kinnitatud,
                        qryKond.eelarve_tekkepohine_tapsustatud,
                        qryKond.aasta_2_tekke_taitmine,
                        qryKond.aasta_2_oodatav_taitmine,
                        qryKond.aasta_3_eelnou,
                        qryKond.aasta_3_prognoos,
                        qryKond.selg
                 FROM qryKond
             )
        SELECT rep.rekv_id:: INTEGER,
               rep.idx:: INTEGER,
               rep.artikkel:: VARCHAR(20),
               rep.tegev:: VARCHAR(20),
               rep.allikas::VARCHAR(20),
               rep.tunnus:: VARCHAR(20),
               rep.aasta_1_tekke_taitmine:: NUMERIC(14, 2),
               rep.aasta_2_tekke_taitmine:: NUMERIC(14, 2),
               rep.aasta_2_oodatav_taitmine:: NUMERIC(14, 2),
               rep.aasta_3_eelnou:: NUMERIC(14, 2),
               rep.aasta_3_prognoos ::NUMERIC(14, 2),
               rep.eelarve_tekkepohine_kinnitatud ::NUMERIC(14, 2),
               rep.eelarve_tekkepohine_tapsustatud ::NUMERIC(14, 2),
               rep.selg
        FROM report rep;
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
SELECT sum(aasta_1_tekke_taitmine) over(partition by rekv_id, artikkel) as aasta1, sum(aasta_2_tekke_taitmine) over(partition by rekv_id, artikkel) as aasta2 , *
FROM eelarve.tulud_eelnou('2021-12-31'::DATE, 64:: INTEGER, 1)
where artikkel = '3888'
tunnus in  ('4007')

*/


