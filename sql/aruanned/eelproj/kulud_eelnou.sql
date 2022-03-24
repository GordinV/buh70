DROP FUNCTION IF EXISTS eelarve.kulud_eelnou(DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.kulud_eelnou(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER,
                                                l_params JSONB DEFAULT '{}'::JSONB)
    RETURNS TABLE (
        rekv_id                         INTEGER,
        idx                             INTEGER,
        artikkel                        VARCHAR(20),
        tegev                           VARCHAR(20),
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
    a_Sotsiaaltoetused                         TEXT[] = ARRAY ['4130','4131','4132','4133','4134','4137','4138','4139'];
    a_SihtotstarbelisedToetusedTegevuskuludeks TEXT[] = ARRAY ['4500'];
    a_MittesihtotstarbelisedToetused           TEXT[] = ARRAY ['452'];
    a_Toojoukulud                              TEXT[] = ARRAY ['5000','5001','5002','5005','5008','505','506'];
    a_Majandamiskulud                          TEXT[] = ARRAY ['5500','5502','5503','5504','5511','5512','5513','5514','5515','5516','5521','5522','5523','5524','5525','5526','5529','5531','5532','5539','5540'];
    a_MuudKulud                                TEXT[] = ARRAY ['601','608'];
    a_PohivaraSoetus                           TEXT[] = ARRAY ['155','156','157','158','4502','1501','1511','1531','650'];
    a_FinanseerimisTegevus                     TEXT[] = ARRAY ['2586'];
    l_allikas                                  TEXT   = l_params ->> 'allikas';
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
              AND kood IN (SELECT unnest(a_Sotsiaaltoetused)
                           UNION ALL
                           SELECT unnest(a_SihtotstarbelisedToetusedTegevuskuludeks)
                           UNION ALL
                           SELECT unnest(a_MittesihtotstarbelisedToetused)
                           UNION ALL
                           SELECT unnest(a_Toojoukulud)
                           UNION ALL
                           SELECT unnest(a_Majandamiskulud)
                           UNION ALL
                           SELECT unnest(a_MuudKulud)
                           UNION ALL
                           SELECT unnest(a_PohivaraSoetus)
                           UNION ALL
                           SELECT unnest(a_FinanseerimisTegevus)
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
                                AND t1.kood2 NOT LIKE ('%RF%')
                                AND (l_allikas IS NULL OR t1.kood2 ILIKE '%' || l_allikas || '%')
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
                        sum(s.db - s.kr) AS tegelik,
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
                                   INNER JOIN (
                              SELECT kood
                              FROM qryArtikkel
/*                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
*/ ) a
                                              ON ((ltrim(rtrim((j1.deebet) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))

                              -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id

                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv) - 1, 12, 31)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования
                            AND j1.kood2 NOT ILIKE ('%RF%')
                            AND (l_allikas IS NULL OR j1.kood2 ILIKE '%' || l_allikas || '%')
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
/*                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
*/                          ) a
                                              ON ((ltrim(rtrim((j1.kreedit) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))

                              -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id

                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv) - 1, 12, 31)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования

                            AND j1.kood2 NOT ILIKE ('%RF%')
                            AND (l_allikas IS NULL OR j1.kood2 ILIKE '%' || l_allikas || '%')
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
                        sum(s.db - s.kr) AS tegelik,
                        year(l_kpv)      AS aasta,
                        9                AS kuu,
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
                                   INNER JOIN qryArtikkel a
                                              ON ((ltrim(rtrim((j1.deebet) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))
                              -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id

                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv), 09, 30)
                            AND coalesce(alg.kpv, j.kpv) >= make_date(year(l_kpv), 01, 01)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования

                            AND j1.kood2 NOT ILIKE ('%RF%')
                            AND (l_allikas IS NULL OR j1.kood2 ILIKE '%' || l_allikas || '%')
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
                                   INNER JOIN qryArtikkel a
                                              ON ((ltrim(rtrim((j1.kreedit) :: TEXT)) ~~
                                                   ltrim(rtrim((a.kood) || '%' :: TEXT))))
                              -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                                   LEFT OUTER JOIN docs.alg_saldo alg ON alg.journal_id = d.id

                          WHERE coalesce(alg.kpv, j.kpv) <= make_date(year(l_kpv), 09, 30)
                            AND coalesce(alg.kpv, j.kpv) >= make_date(year(l_kpv), 01, 01)
                            AND d.rekvid = (CASE
                                                WHEN l_kond = 1 THEN d.rekvid
                                                ELSE l_rekvid END)
                            AND d.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid) r)
                            and d.rekvid <>9 -- убрать внутренее учреждение культуры для элиминирования
                            AND j1.kood2 NOT ILIKE ('%RF%')
                            AND (l_allikas IS NULL OR j1.kood2 ILIKE '%' || l_allikas || '%')
                            AND d.status <> 3
                      ) s

                 GROUP BY s.tyyp, s.konto, s.tegev, s.allikas, s.rahavoog, s.artikkel, s.tunnus, s.rekv_id
             ),
             qryAasta1 AS (
                 SELECT s.rekv_id      AS rekvid,
                        s.artikkel     AS artikkel,
                        s.tegev        AS tegev,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                 GROUP BY s.rekv_id, s.artikkel, s.tegev, s.tunnus
             ),
             qryAasta2 AS (
                 SELECT s.rekv_id      AS rekvid,
                        s.artikkel     AS artikkel,
                        s.tegev        AS tegev,
                        s.tunnus       AS tunnus,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv)
                 GROUP BY s.rekv_id, s.artikkel, s.tegev, s.tunnus
             ),
             -- текущего года

             qryAasta4 AS (
                 -- Сумма всех строк с данным Art Tekke põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5   AS artikkel,
                        t1.kood1   AS tegev,
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
                   AND t1.kood2 NOT ILIKE ('%RF%')
                   AND (l_allikas IS NULL OR t1.kood2 ILIKE '%' || l_allikas || '%')
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )

                 GROUP BY t1.kood5, t1.kood1, t1.tunnus, t.rekvid
             ),
             qryAasta5 AS (
                 -- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 -- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5                                     AS artikkel,
                        t1.kood1                                     AS tegev,
                        t1.tunnus,
                        sum(summa_kassa)                             AS summa,
                        string_agg(ltrim(rtrim(t1.selg)), ' '::TEXT) AS selg
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
                   AND t1.kood2 NOT ILIKE ('%RF%')
                   AND (l_allikas IS NULL OR t1.kood2 ILIKE '%' || l_allikas || '%')
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )

                 GROUP BY t1.kood5, t1.kood1, t1.tunnus, t.rekvid
             ),
             qryAasta6 AS (
-- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine kinnitatud
-- текущего года

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
                   AND e.kood2 NOT ILIKE ('%RF%')
                   AND (l_allikas IS NULL OR e.kood2 ILIKE '%' || l_allikas || '%')
                   AND e.kpv IS NULL
                   AND e.status <> 3
                   AND kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.tunnus
             ),
             qryAasta7 AS (
-- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine täpsustatud
-- текущего года seisuga 30.09.2022

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
                   AND (e.kpv IS NULL OR e.kpv <= make_date(YEAR($1), 09, 30))
                   AND e.kood2 NOT ILIKE ('%RF%')
                   AND (l_allikas IS NULL OR e.kood2 ILIKE '%' || l_allikas || '%')
                   AND e.status <> 3
                   AND kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.tunnus
             ),

             preReport AS (
                 SELECT qry.rekvid,
                        qry.artikkel,
                        qry.tegev,
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
                          UNION ALL
                          SELECT rekvid                AS rekv_id,
                                 2                     AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
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
                 GROUP BY qry.rekvid, qry.artikkel, qry.tegev,
                          CASE WHEN t.artikkel IS NULL THEN '' ELSE qry.tunnus END),
             qryReport AS (
                 SELECT s.rekvid:: INTEGER,
                        r.parentid,
                        CASE
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_Sotsiaaltoetused THEN 100
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_SihtotstarbelisedToetusedTegevuskuludeks THEN 200
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_MittesihtotstarbelisedToetused THEN 300
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_Toojoukulud THEN 400
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_Majandamiskulud THEN 500
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_MuudKulud THEN 600
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_PohivaraSoetus THEN 700
                            WHEN ARRAY [s.artikkel::TEXT] <@ a_FinanseerimisTegevus THEN 800
                            ELSE 900 END                     AS idx,
                        s.artikkel::VARCHAR(20),
                        coalesce(s.tegev, '')::VARCHAR(20)   AS tegev,
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
                        s.artikkel::VARCHAR(20),
                        sum(s.aasta_1_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_1_tekke_taitmine,
                        sum(s.eelarve_tekkepohine_kinnitatud)::NUMERIC(14, 2)  AS eelarve_tekkepohine_kinnitatud,
                        sum(s.eelarve_tekkepohine_tapsustatud)::NUMERIC(14, 2) AS eelarve_tekkepohine_tapsustatud,
                        sum(s.aasta_2_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_2_tekke_taitmine,
                        sum(s.aasta_2_oodatav_taitmine):: NUMERIC(14, 2)       AS aasta_2_oodatav_taitmine,
                        sum(s.aasta_3_eelnou):: NUMERIC(14, 2)                 AS aasta_3_eelnou,
                        sum(s.aasta_3_prognoos)::NUMERIC(14, 2)                AS aasta_3_prognoos,
                        NULL::TEXT                                             AS selg
                 FROM qryReport s
                 GROUP BY s.artikkel, s.idx, s.tunnus, s.tegev
             ),
             report AS (
                 SELECT qryReport.idx,
/*                        CASE
                            WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvId
                            ELSE l_rekvid END                          AS rekv_id,
*/
                        qryReport.rekvId                               AS rekv_id,
                        qryReport.tunnus,
                        qryReport.tegev,
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
                 GROUP BY qryReport.idx, qryreport.rekvid,
--                          (CASE WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvid ELSE l_rekvid END),
                          qryReport.tunnus, qryReport.tegev, qryReport.artikkel
                 UNION ALL
                 SELECT 0                                              AS idx,
/*                         CASE
                           WHEN qryReport.parentid = l_rekvid THEN qryReport.rekvId
                            ELSE l_rekvid END                          AS rekv_id,
*/
                        qryReport.rekvId                               AS rekv_id,
                        ''                                             AS tunnus,
                        left(qryReport.tegev, 2)::VARCHAR(20)          AS tegev,
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
                 GROUP BY qryreport.rekvid,
                          left(qryReport.tegev, 2)
                 UNION ALL
                 SELECT 0                                            AS idx,
                        qryKond.rekv_id                              AS rekv_id,
                        ''                                           AS tunnus,
                        left(qryKond.tegev, 2)::VARCHAR(20)          AS tegev,
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

                 SELECT *
                 FROM qryKond
             )
        SELECT rep.rekv_id:: INTEGER,
               rep.idx:: INTEGER,
               rep.artikkel:: VARCHAR(20),
               rep.tegev:: VARCHAR(20),
               rep.tunnus:: VARCHAR(20),
               rep.aasta_1_tekke_taitmine:: NUMERIC(14, 2),
               rep.aasta_2_tekke_taitmine:: NUMERIC(14, 2),
               rep.aasta_2_oodatav_taitmine:: NUMERIC(14, 2),
               rep.aasta_3_eelnou:: NUMERIC(14, 2),
               rep.aasta_3_prognoos ::NUMERIC(14, 2),
               rep.eelarve_tekkepohine_kinnitatud ::NUMERIC(14, 2),
               rep.eelarve_tekkepohine_tapsustatud ::NUMERIC(14, 2),
               rep.selg
        FROM report rep
        WHERE rep.artikkel <> '';
END
$$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou(DATE, INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou(DATE, INTEGER, INTEGER,JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou(DATE, INTEGER, INTEGER,JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou(DATE, INTEGER, INTEGER,JSONB) TO dbvaatleja;

/*
SELECT *
FROM eelarve.kulud_eelnou('2021-12-31'::DATE, 63:: INTEGER, 1)
where tegev like '08%'

*/--where idx = 100



