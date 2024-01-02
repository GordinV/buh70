DROP FUNCTION IF EXISTS eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.tulud_eelnou_pikk(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER,
                                                     l_params JSONB DEFAULT '{}'::JSONB)
    RETURNS TABLE (
        rekv_id                         INTEGER,
        idx                             INTEGER,
        artikkel                        VARCHAR(20),
        tegev                           VARCHAR(20),
        allikas                         VARCHAR(20),
        tunnus                          VARCHAR(20),
        proj                            VARCHAR(20),
        uritus                          VARCHAR(20),
        objekt                          VARCHAR(20),
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
    a_maksud                       TEXT[]    = ARRAY ['3000', '3030', '3034', '3041', '3044', '3045', '3047'];
    a_tuluMuugist                  TEXT[]    = ARRAY ['320', '3220', '3221', '3222', '3224', '3229', '3232', '3233', '3237', '3238'];
    a_SaadetudToetused             TEXT[]    = ARRAY ['3500', '35200', '35201', '352'];
    a_MuudTegevusTulud             TEXT[]    = ARRAY ['38250', '38251', '38252', '38254', '3880', '3882', '3823', '3818', '3888'];
    a_TuludInvesteerimistegevusest TEXT[]    = ARRAY ['381', '3502', '1502', '1512', '1532', '655','1032'];
    a_FinanseerimisTegevus         TEXT[]    = ARRAY ['2585'];
    a_LikviidseteVaradeMuutus      TEXT[]    = ARRAY ['100'];
    kas_ainult_aktsepteeritud      BOOLEAN   = coalesce((l_params ->> 'taotlus_statusid')::BOOLEAN, FALSE);
    taotlus_statusid               INTEGER[] = CASE
                                                   WHEN kas_ainult_aktsepteeritud THEN ARRAY [3]
                                                   ELSE ARRAY [0,1,2,3] END;


BEGIN
    -- оздаем выборку данных для отчета
    -- eelmise aasta
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
             rekv_ids AS (SELECT r.rekv_id
                          FROM public.get_asutuse_struktuur(l_rekvid) r
                          WHERE (r.rekv_id = l_rekvid
                              OR l_kond = 1)
                            AND r.rekv_id <> 9),
             qryTaotlused AS (SELECT DISTINCT t.rekvid, t1.tunnus
                              FROM eelarve.taotlus t
                                       INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                              WHERE t1.tunnus IS NOT NULL
                                AND NOT empty(t1.tunnus)
                                AND t.status IN (SELECT unnest(taotlus_statusid))
                                AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                                AND t.aasta IN (YEAR(l_kpv) - 1, YEAR(l_kpv), YEAR(l_kpv) + 1)
                                AND t1.kood2 NOT LIKE ('%RF%')
                              GROUP BY t.rekvid,
                                       t1.tunnus
                              HAVING (count(*) > 0)
             ),
             qryProj AS (SELECT DISTINCT t.rekvid, t1.proj
                         FROM eelarve.taotlus t
                                  INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                         WHERE t1.proj IS NOT NULL
                           AND NOT empty(t1.proj)
                           AND t.status IN (SELECT unnest(taotlus_statusid))
                           AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                           AND t.aasta IN (YEAR(l_kpv) - 1, YEAR(l_kpv), YEAR(l_kpv) + 1)
                           AND t1.kood2 NOT LIKE ('%RF%')
                         GROUP BY t.rekvid,
                                  t1.proj
                         HAVING (count(*) > 0)
             ),
             qryUritus AS (SELECT DISTINCT t.rekvid, t1.kood4 AS uritus
                           FROM eelarve.taotlus t
                                    INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                           WHERE t1.kood4 IS NOT NULL
                             AND NOT empty(t1.kood4)
                             AND t.status IN (SELECT unnest(taotlus_statusid))
                             AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                             AND t.aasta IN (YEAR(l_kpv) - 1, YEAR(l_kpv), YEAR(l_kpv) + 1)
                             AND t1.kood2 NOT LIKE ('%RF%')
                           GROUP BY t.rekvid,
                                    t1.kood4
                           HAVING (count(*) > 0)
             ),
             qryObjekt AS (SELECT DISTINCT t.rekvid, t1.objekt AS objekt
                           FROM eelarve.taotlus t
                                    INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                           WHERE t1.objekt IS NOT NULL
                             AND NOT empty(t1.objekt)
                             AND t.status IN (SELECT unnest(taotlus_statusid))
                             AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                             AND t.aasta IN (YEAR(l_kpv) - 1, YEAR(l_kpv), YEAR(l_kpv) + 1)
                             AND t1.kood2 NOT LIKE ('%RF%')
                           GROUP BY t.rekvid,
                                    t1.objekt
                           HAVING (count(*) > 0)
             ),
             tmp_andmik AS (
                 SELECT s.tyyp,
                        s.konto,
                        s.allikas,
                        s.tegev,
                        s.artikkel      AS artikkel,
                        s.rahavoog,
                        s.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(tegelik)    AS tegelik,
                        year(l_kpv) - 1 AS aasta,
                        12              AS kuu,
                        s.rekv_id
                 FROM (
                          SELECT 2               AS tyyp,
                                 ''              AS konto,
                                 qry.allikas,
                                 qry.tegev,
                                 qry.artikkel,
                                 qry.rahavoog,
                                 qry.tunnus,
                                 qry.proj,
                                 qry.uritus,
                                 qry.objekt,
                                 qry.summa       AS tegelik,
                                 year(l_kpv) - 1 AS aasta,
                                 12              AS kuu,
                                 qry.rekv_id
                          FROM eelarve.tulu_taitmine_pikk(make_date(year(l_kpv) - 1, 1, 1),
                                                          make_date(year(l_kpv) - 1, 12, 31),
                                                          l_rekvid, l_kond) qry
                          WHERE qry.artikkel IN (
                              SELECT kood
                              FROM qryArtikkel
--                              WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                              UNION ALL
                              SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
                          )

                            AND (l_params IS NULL OR
                                 coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                            AND (l_params IS NULL OR
                                 coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                            AND (l_params IS NULL OR coalesce(qry.artikkel, '') ILIKE
                                                     coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                            AND (l_params IS NULL OR
                                 coalesce(qry.allikas, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                            AND (l_params IS NULL OR coalesce(qry.rahavoog, '') ILIKE
                                                     coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
                            AND qry.rekv_id <> 9
                      ) s

                 GROUP BY s.tyyp, s.konto, s.tegev, s.allikas, s.rahavoog, s.artikkel, s.tunnus, s.proj, s.uritus, s.objekt,
                          s.rekv_id
                 UNION ALL
--  текущий год
                 SELECT 2           AS tyyp,
                        ''          AS konto,
                        qry.allikas,
                        qry.tegev,
                        qry.artikkel,
                        qry.rahavoog,
                        qry.tunnus,
                        qry.proj,
                        qry.uritus,
                        qry.objekt,
                        qry.summa   AS tegelik,
                        year(l_kpv) AS aasta,
                        06          AS kuu,
                        qry.rekv_id
                 FROM eelarve.tulu_taitmine_pikk(make_date(year(l_kpv), 01, 01),
                                                 make_date(year(l_kpv), 06, 30),
                                                 l_rekvid, l_kond) qry
                 WHERE qry.artikkel IN (
                     SELECT kood
                     FROM qryArtikkel
--                     WHERE kood NOT IN ('35200', '35201', '3818', '2585')
                     UNION ALL
                     SELECT unnest(ARRAY ['155', '154','156','109', '208', '258'])
                 )
                   AND (l_params IS NULL OR
                        coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                   AND (l_params IS NULL OR
                        coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                   AND (l_params IS NULL OR coalesce(qry.artikkel, '') ILIKE
                                            coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                   AND (l_params IS NULL OR
                        COALESCE(qry.allikas, '') ILIKE COALESCE((l_params ->> 'allikas')::TEXT, '') + '%')
                   AND (l_params IS NULL OR COALESCE(qry.rahavoog, '') ILIKE
                                            COALESCE((l_params ->> 'rahavoog')::TEXT, '') + '%')
                   AND qry.rekv_id <> 9
             ),
             qryAasta1 AS (
                 SELECT S.rekv_id      AS rekvid,
                        S.artikkel     AS artikkel,
                        S.tegev        AS tegev,
                        S.allikas      AS allikas,
                        S.tunnus       AS tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik S
                 WHERE aasta = YEAR(l_kpv) - 1
                   AND LEFT(S.konto, 3) NOT IN ('352', '100', '381', '655')
                   AND LEFT(S.artikkel, 4) NOT IN ('3502', '1502', '1032', '1532', '2585')
                 GROUP BY S.rekv_id, S.artikkel, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 --3502
--         get_saldo('KD', '3502', '01', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT S.rekv_id    AS rekvid,
                        '3502'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas    AS allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas   AS allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel LIKE '3502%'
                            AND (S.rahavoog IN ('01', '05') OR COALESCE(rahavoog, '') = '')
                            AND S.aasta = date_part('year', l_kpv) - 1
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 100
                 SELECT S.rekv_id    AS rekvid,
                        '100'        AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(s.summa) AS summa, -- так как у нас К-Д
                        1            AS idx
                 FROM (
                          -- get_saldo('DK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid      AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''            AS tunnus,
                                 ''            AS proj,
                                 ''            AS uritus,
                                 ''            AS objekt,
                                 (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '100%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          UNION ALL
                          -- - get_saldo('MDK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid           AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                 AS tunnus,
                                 ''                 AS proj,
                                 ''                 AS uritus,
                                 ''                 AS objekt,
                                 -1 * (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '100%'
                            AND s.aasta = date_part('year', l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 2, 12, 31)) r)
                          UNION ALL
                          -- + get_saldo('DK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid      AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''            AS tunnus,
                                 ''            AS proj,
                                 ''            AS uritus,
                                 ''            AS objekt,
                                 (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '101%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          UNION ALL
                          -- - get_saldo('MDK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid           AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                 AS tunnus,
                                 ''                 AS proj,
                                 ''                 AS uritus,
                                 ''                 AS objekt,
                                 -1 * (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '101%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 2, 12, 31)) r)
                          UNION ALL
                          -- - get_saldo('DK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid           AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                 AS tunnus,
                                 ''                 AS proj,
                                 ''                 AS uritus,
                                 ''                 AS objekt,
                                 -1 * (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1019%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          UNION ALL
                          -- + get_saldo('MDK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid      AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''            AS tunnus,
                                 ''            AS proj,
                                 ''            AS uritus,
                                 ''            AS objekt,
                                 (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1019%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 2, 12, 31)) r)
                          UNION ALL
                          -- + get_saldo('DK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid      AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''            AS tunnus,
                                 ''            AS proj,
                                 ''            AS uritus,
                                 ''            AS objekt,
                                 (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '151%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          UNION ALL
                          --  - get_saldo('MDK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid           AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                 AS tunnus,
                                 ''                 AS proj,
                                 ''                 AS uritus,
                                 ''                 AS objekt,
                                 -1 * (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '151%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 2, 12, 31)) r)
                          UNION ALL
                          -- - get_saldo('DK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid           AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''                 AS tunnus,
                                 ''                 AS proj,
                                 ''                 AS uritus,
                                 ''                 AS objekt,
                                 -1 * (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1519%'
                            AND s.aasta = YEAR(l_kpv) - 1
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          UNION ALL
-- + get_saldo('MDK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT s.rekvid      AS rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 ''            AS tunnus,
                                 ''            AS proj,
                                 ''            AS uritus,
                                 ''            AS objekt,
                                 (s.db - s.kr) AS summa
                          FROM eelarve.saldoandmik s
                          WHERE s.konto LIKE '1519%'
                            AND s.aasta = YEAR(l_kpv) - 2
                            AND s.kuu = 12
                            AND s.rekvid = (CASE
                                                WHEN l_kond = 1 THEN s.rekvid
                                                ELSE l_rekvid END)
                            AND s.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 2, 12, 31)) r)
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 --         '1502'
--         get_saldo('KD','150','02', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT s.rekv_id      AS rekvid,
                        '1502'         AS artikkel,
                        s.tegev        AS tegev,
                        s.allikas,
                        s.tunnus       AS tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(s.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik s
                 WHERE aasta = year(l_kpv) - 1
                   AND s.konto LIKE '150%'
                   AND s.rahavoog = '02'
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 1512
-- get_saldo('KD', '151910', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '101900', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1512'       AS artikkel,
                        s.tegev      AS tegev,
                        s.allikas,
                        s.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(s.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '151910%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                          UNION ALL
                          SELECT s.rekv_id,
                                 s.tegev,
                                 s.allikas,
                                 s.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (s.tegelik) AS summa
                          FROM tmp_andmik s
                          WHERE s.konto LIKE '101900%'
                            AND s.rahavoog = '02'
                            AND s.aasta = YEAR(l_kpv) - 1
                      ) s
                 GROUP BY s.rekv_id, s.tegev, s.allikas, s.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 1532
--         get_saldo('KD', '1032', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '1532', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1532'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel = '1032'
                            AND S.rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv) - 1
                          UNION ALL
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel = '1532'
                            AND S.rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv) - 1
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
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
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- get_saldo('KD', '381', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE '381%'
                            AND S.aasta = YEAR(l_kpv) - 1
                          UNION ALL
                          -- - get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 -1 * (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE '3818%'
                            AND S.aasta = YEAR(l_kpv) - 1
                          UNION ALL
                          -- - get_saldo('DK', '154', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '155', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '156', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- -  get_saldo('DK', '157', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '109', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE LEFT(S.konto, 3) IN ('154', '155', '156', '157', '109')
                            AND rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv) - 1
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 3818
-- get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id      AS rekvid,
                        '3818'         AS artikkel,
                        S.tegev        AS tegev,
                        S.allikas,
                        S.tunnus       AS tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik S
                 WHERE aasta = YEAR(l_kpv) - 1
                   AND S.konto LIKE '3818%'
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 2585
-- get_saldo('KD', '208', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '258', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '2585'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel LIKE '208%'
                            AND S.rahavoog = '05'
                            AND S.aasta = YEAR(l_kpv) - 1
                          UNION ALL
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel LIKE '258%'
                            AND S.rahavoog = '05'
                            AND S.aasta = YEAR(l_kpv) - 1
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
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
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- - get_saldo('KD', '652000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '652030', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '658950', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 -1 * (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE LEFT(S.konto, 6) IN ('652000', '652030', '658950')
                            AND S.aasta = YEAR(l_kpv) - 1
                          UNION ALL
                          --  + get_saldo('KD', '652', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '655', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '658', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE LEFT(S.konto, 3) IN ('655', '658', '652')
                            AND S.aasta = YEAR(l_kpv) - 1
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
             ),
             qryAasta2 AS (
                 SELECT S.rekv_id      AS rekvid,
                        S.artikkel     AS artikkel,
                        S.tegev        AS tegev,
                        S.allikas,
                        S.tunnus       AS tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik S
                 WHERE aasta = YEAR(l_kpv)
                   AND LEFT(S.konto, 3) NOT IN ('352', '100', '381', '655')
                   AND LEFT(S.artikkel, 4) NOT IN ('3502', '1502', '1532', '2585', '1032')
                 GROUP BY S.rekv_id, S.artikkel, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 --         get_saldo('KD', '3502', '01', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '3502', '', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT S.rekv_id    AS rekvid,
                        '3502'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel LIKE '3502%'
                            AND (S.rahavoog IN ('01', '05')
                              OR COALESCE(rahavoog, '') = '')
                            AND S.aasta = YEAR(l_kpv)
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
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
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa, -- так как у нас К-Д
                        1            AS idx
                 FROM (
                          -- get_saldo('DK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid         AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''               AS tunnus,
                                 ''               AS proj,
                                 ''               AS uritus,
                                 ''               AS objekt,
                                 sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '100%'
                            AND S.aasta = YEAR(l_kpv)
                            AND S.kuu = 6
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv), 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- - get_saldo('MDK', '100', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid              AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''                    AS tunnus,
                                 ''                    AS proj,
                                 ''                    AS uritus,
                                 ''                    AS objekt,
                                 -1 * sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '100%'
                            AND S.aasta = YEAR(l_kpv) - 1
                            AND S.kuu = 12
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- + get_saldo('DK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid         AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''               AS tunnus,
                                 ''               AS proj,
                                 ''               AS uritus,
                                 ''               AS objekt,
                                 sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '101%'
                            AND S.aasta = YEAR(l_kpv)
                            AND S.kuu = 6
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv), 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- - get_saldo('MDK', '101', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid              AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''                    AS tunnus,
                                 ''                    AS proj,
                                 ''                    AS uritus,
                                 ''                    AS objekt,
                                 -1 * sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '101%'
                            AND S.aasta = YEAR(l_kpv) - 1
                            AND S.kuu = 12
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- - get_saldo('DK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid              AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''                    AS tunnus,
                                 ''                    AS proj,
                                 ''                    AS uritus,
                                 ''                    AS objekt,
                                 -1 * sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '1019%'
                            AND S.aasta = YEAR(l_kpv)
                            AND S.kuu = 6
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv), 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- + get_saldo('MDK', '1019', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid         AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''               AS tunnus,
                                 ''               AS proj,
                                 ''               AS uritus,
                                 ''               AS objekt,
                                 sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '1019%'
                            AND S.aasta = YEAR(l_kpv) - 1
                            AND S.kuu = 12
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- + get_saldo('DK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid         AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''               AS tunnus,
                                 ''               AS proj,
                                 ''               AS uritus,
                                 ''               AS objekt,
                                 sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '151%'
                            AND S.aasta = YEAR(l_kpv)
                            AND S.kuu = 6
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          --  - get_saldo('MDK', '151', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid              AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''                    AS tunnus,
                                 ''                    AS proj,
                                 ''                    AS uritus,
                                 ''                    AS objekt,
                                 -1 * sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '151%'
                            AND S.aasta = YEAR(l_kpv) - 1
                            AND S.kuu = 12
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
                          -- - get_saldo('DK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid              AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''                    AS tunnus,
                                 ''                    AS proj,
                                 ''                    AS uritus,
                                 ''                    AS objekt,
                                 -1 * sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '1519%'
                            AND S.aasta = YEAR(l_kpv)
                            AND S.kuu = 6
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv), 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                          UNION ALL
-- + get_saldo('MDK', '1519', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekvid         AS rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 ''               AS tunnus,
                                 ''               AS proj,
                                 ''               AS uritus,
                                 ''               AS objekt,
                                 sum(S.db - S.kr) AS summa
                          FROM eelarve.saldoandmik S
                          WHERE S.konto LIKE
                                '1519%'
                            AND S.aasta = YEAR(l_kpv) - 1
                            AND S.kuu = 12
                            AND S.rekvid = (CASE
                                                WHEN l_kond = 1 THEN S.rekvid
                                                ELSE l_rekvid END)
                            AND S.rekvid IN (SELECT r.rekv_id
                                             FROM get_asutuse_struktuur(l_rekvid, make_date(YEAR(l_kpv) - 1, 12, 31)) r)
                          GROUP BY S.rekvid, S.allikas, S.tegev
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 --         '1502'
--         get_saldo('KD','150','02', NULL, S.rekv_id, YEAR (l_kpv) - 1) AS summa
                 SELECT S.rekv_id      AS rekvid,
                        '1502'         AS artikkel,
                        S.tegev        AS tegev,
                        S.allikas,
                        S.tunnus       AS tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik S
                 WHERE aasta = YEAR(l_kpv)
                   AND S.konto LIKE '150%'
                   AND S.rahavoog = '02'
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 1512
-- get_saldo('KD', '151910', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '101900', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1512'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE '151910%'
                            AND S.rahavoog =
                                '02'
                            AND S.aasta = YEAR(l_kpv)
                          UNION ALL
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE
                                '101900%'
                            AND S.rahavoog =
                                '02'
                            AND S.aasta = YEAR(l_kpv)
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 1532
--         get_saldo('KD', '1032', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '1532', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '1532'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel = '1032'
                            AND S.rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv)
                          UNION ALL
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel = '1532'
                            AND S.rahavoog = '02'
                            AND S.aasta = YEAR(l_kpv)
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
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
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- get_saldo('KD', '381', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE '381%'
                            AND S.aasta = YEAR(l_kpv)
                          UNION ALL
                          -- - get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 -1 * (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.konto LIKE
                                '3818%'
                            AND S.aasta = YEAR(l_kpv)
                          UNION ALL
                          -- - get_saldo('DK', '154', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '155', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '156', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- -  get_saldo('DK', '157', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('DK', '109', '02', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE LEFT(S.konto, 3) IN (
                                                     '154',
                                                     '155',
                                                     '156',
                                                     '157',
                                                     '109')
                            AND ltrim(rtrim(rahavoog)) =
                                '02'
                            AND S.aasta = YEAR(l_kpv)
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 3818
-- get_saldo('KD', '3818', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id      AS rekvid,
                        '3818'         AS artikkel,
                        S.tegev        AS tegev,
                        S.allikas,
                        S.tunnus       AS tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.tegelik) AS summa,
                        1              AS idx
                 FROM tmp_andmik S
                 WHERE aasta = YEAR(l_kpv)
                   AND S.konto LIKE '3818%'
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
                 UNION ALL
                 -- 2585
-- get_saldo('KD', '208', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1) +
--         get_saldo('KD', '258', '05', NULL, S.rekv_id, YEAR (l_kpv) - 1)
                 SELECT S.rekv_id    AS rekvid,
                        '2585'       AS artikkel,
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel LIKE '208%'
                            AND S.rahavoog =
                                '05'
                            AND S.aasta = YEAR(l_kpv)
                          UNION ALL
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE S.artikkel LIKE
                                '258%'
                            AND S.rahavoog =
                                '05'
                            AND S.aasta = YEAR(l_kpv)
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
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
                        S.tegev      AS tegev,
                        S.allikas,
                        S.tunnus,
                        s.proj,
                        s.uritus,
                        s.objekt,
                        sum(S.summa) AS summa,
                        1            AS idx
                 FROM (
                          -- - get_saldo('KD', '652000', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '652030', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- - get_saldo('KD', '658950', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 -1 * (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE LEFT(S.konto, 6) IN ('652000',
                                                     '652030',
                                                     '658950')
                            AND S.aasta = YEAR(l_kpv)
                          UNION ALL
                          --  + get_saldo('KD', '652', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '655', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          -- + get_saldo('KD', '658', NULL, NULL, S.rekv_id, YEAR (l_kpv) - 1)
                          SELECT S.rekv_id,
                                 S.tegev,
                                 S.allikas,
                                 S.tunnus,
                                 s.proj,
                                 s.uritus,
                                 s.objekt,
                                 (S.tegelik) AS summa
                          FROM tmp_andmik S
                          WHERE LEFT(S.konto, 3) IN (
                                                     '655',
                                                     '658',
                                                     '652')
                            AND S.aasta = YEAR(l_kpv)
                      ) S
                 GROUP BY S.rekv_id, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus, s.objekt
             ),
             -- пока не нужен
             -- текущего года
             qryAasta4 AS (
                 -- Сумма всех строк с данным Art Tekke põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5   AS artikkel,
                        t1.kood1   AS tegev,
                        t1.kood2   AS allikas,
                        t1.tunnus,
                        t1.proj,
                        t1.kood4   AS uritus,
                        t1.objekt,
                        sum(summa) AS summa,
                        NULL::TEXT AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1
                                     ON t.id = t1.parentid
                 WHERE t.aasta = YEAR(l_kpv) + 1
                   AND t.status IN (SELECT unnest(taotlus_statusid)) -- акцептированные
                   AND coalesce(t.tunnus, 0) = 0                     -- только утвержденные
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
                 GROUP BY t1.kood5, t1.kood1, t1.kood2, t1.tunnus, t1.proj, t1.kood4, t1.objekt, t.rekvid
             ),
             qryAasta5 AS (
                 -- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 -- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5                                                                  AS artikkel,
                        t1.kood1                                                                  AS tegev,
                        t1.kood2                                                                  AS allikas,
                        t1.tunnus,
                        t1.proj,
                        t1.kood4                                                                  AS uritus,
                        t1.objekt,
                        sum(summa_kassa)                                                          AS summa,
                        string_agg(ltrim(rtrim(replace(t1.selg, E'\n', ''), E'\r\n')), ','::TEXT) AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1
                                     ON t.id = t1.parentid
                 WHERE t.aasta = YEAR(l_kpv) + 1
                   AND t.status IN (SELECT unnest(taotlus_statusid))
                   AND coalesce(t.tunnus, 0) = 0 -- только утвержденные
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
                 GROUP BY t1.kood5, t1.kood1, t1.kood2, t1.tunnus, t1.proj, t1.kood4, t1.objekt, t.rekvid
             ),
             qryAasta6 AS (
                 -- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine kinnitatud
-- текущего года
                 SELECT e.rekvid,
                        e.kood5      AS artikkel,
                        e.kood1      AS tegev,
                        e.kood2      AS allikas,
                        e.tunnus     AS tunnus,
                        t1.proj      AS proj,
                        t1.kood4     AS uritus,
                        t1.objekt,
                        sum(e.summa) AS summa
                 FROM eelarve.eelarve e
                          INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id
                 WHERE rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND e.rekvid IN (SELECT a.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) a)
                   AND aasta = YEAR($1)
                   AND e.kpv IS NULL
                   AND e.status <> 3
                   AND e.kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.kood2, e.tunnus, t1.kood4, t1.objekt, t1.proj
             ),
             qryAasta7 AS (
                 -- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine täpsustatud
-- текущего года seisuga 30.06.2022

                 SELECT e.rekvid,
                        e.kood5      AS artikkel,
                        e.kood1      AS tegev,
                        e.kood2      AS allikas,
                        e.tunnus     AS tunnus,
                        t1.proj,
                        t1.kood4     AS uritus,
                        t1.objekt,
                        sum(e.summa) AS summa
                 FROM eelarve.eelarve e
                          INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id
                 WHERE rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND e.rekvid IN (SELECT a.rekv_id
                                    FROM get_asutuse_struktuur(l_rekvid) a)
                   AND aasta = YEAR($1)
                   AND (e.kpv IS NULL OR e.kpv <= make_date(YEAR($1), 06, 30))
                   AND e.status <> 3
                   AND e.kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid, e.kood5, e.kood1, e.kood2, e.tunnus, t1.proj, t1.kood4, t1.objekt
             ),
             qryAasta8 AS (
                 -- oodatav taitine
                 SELECT t.rekvid,
                        t1.kood5                                                                            AS artikkel,
                        t1.kood1                                                                            AS tegev,
                        t1.kood2                                                                            AS allikas,
                        CASE WHEN t1.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE t1.tunnus END AS tunnus,
                        t1.proj,
                        t1.kood4                                                                            AS uritus,
                        t1.objekt,
                        sum(oodatav_taitmine)                                                               AS summa,
                        string_agg(replace(t1.selg::TEXT, E'\r\n', ''), ' '::TEXT)                          AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
                 WHERE t.aasta = YEAR(l_kpv) + 1
                   AND t.status IN (SELECT unnest(taotlus_statusid))
                   AND rekvid = (CASE
                                     WHEN $3 = 1
                                         THEN rekvid
                                     ELSE l_rekvid END)
                   AND rekvid IN (SELECT a.rekv_id
                                  FROM get_asutuse_struktuur(l_rekvid) a)
                   AND t1.kood2 NOT ILIKE ('%RF%')
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )
                   AND t.rekvid <> 9
                 GROUP BY t1.kood5,
                          t1.kood1,
                          t1.kood2,
                          t1.tunnus,
                          t1.proj,
                          t1.kood4,
                          t1.objekt,
                          t.rekvid
             ),
             preReport AS (
                 SELECT qry.rekvid,
                        qry.artikkel,
                        qry.tegev,
                        qry.allikas,
                        CASE
                            WHEN EXISTS(
                                    SELECT 1
                                    FROM qryTaotlused t
                                    WHERE t.tunnus = qry.tunnus
                                      AND rekvid = qry.rekvid)
                                THEN qry.tunnus
                            ELSE '' END                       AS tunnus,
                        CASE
                            WHEN EXISTS(
                                    SELECT 1
                                    FROM qryProj t
                                    WHERE t.proj = qry.proj
                                      AND rekvid = qry.rekvid)
                                THEN qry.proj
                            ELSE '' END                       AS proj,
                        CASE
                            WHEN EXISTS(
                                    SELECT 1
                                    FROM qryUritus t
                                    WHERE t.uritus = qry.uritus
                                      AND rekvid = qry.rekvid)
                                THEN qry.uritus
                            ELSE '' END                       AS uritus,
                        CASE
                            WHEN EXISTS(
                                    SELECT 1
                                    FROM qryObjekt t
                                    WHERE t.objekt = qry.objekt
                                      AND rekvid = qry.rekvid)
                                THEN qry.objekt
                            ELSE '' END                       AS objekt,

                        (qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        (qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        (qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        (qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        (qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                        (qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        (qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        qry.selg                              AS selg
                 FROM (
                          SELECT q.rekvid           AS rekvid,
                                 q.idx,
                                 q.artikkel,
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
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
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
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
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
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
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
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
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
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
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
                                 0::NUMERIC(14, 2)  AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 summa::NUMERIC(14, 2) eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT         AS selg
                          FROM qryAasta7 q
                          UNION ALL
                          SELECT q.rekvid           AS rekvid,
                                 2,
                                 q.artikkel,
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 q.objekt,
                                 0                  AS aasta_1_tekke_taitmine,
                                 0                  AS aasta_2_tekke_taitmine,
                                 q.summa            AS aasta_2_oodatav_taitmine,
                                 0                  AS aasta_3_eelnou,
                                 0                  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)     eelarve_tekkepohine_tapsustatud,
                                 NULL::TEXT         AS selg
                          FROM qryAasta8 q
                      ) qry
             ),
             qryReport AS (
                 SELECT S.rekvid:: INTEGER,
                        r.parentid,
                        CASE
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_maksud THEN 100
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_tuluMuugist THEN 200
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_SaadetudToetused THEN 300
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_MuudTegevusTulud THEN 400
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_TuludInvesteerimistegevusest THEN 500
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_FinanseerimisTegevus THEN 600
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_LikviidseteVaradeMuutus THEN 700
                            ELSE 900 END                                       AS idx,
                        S.artikkel::VARCHAR(20),
                        COALESCE(S.tegev, '')::VARCHAR(20)                     AS tegev,
                        COALESCE(S.allikas,
                                 '')::VARCHAR(20)                              AS allikas,
                        COALESCE(S.tunnus,
                                 ''):: VARCHAR(20)                             AS tunnus,
                        COALESCE(S.proj,
                                 ''):: VARCHAR(20)                             AS proj,
                        COALESCE(S.uritus,
                                 ''):: VARCHAR(20)                             AS uritus,
                        coalesce(s.objekt, '')::VARCHAR(20)                    AS objekt,
                        sum(S.aasta_1_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_1_tekke_taitmine,
                        sum(S.aasta_2_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_2_tekke_taitmine,
                        sum(S.aasta_2_oodatav_taitmine):: NUMERIC(14, 2)       AS aasta_2_oodatav_taitmine,
                        sum(S.aasta_3_eelnou):: NUMERIC(14, 2)                 AS aasta_3_eelnou,
                        sum(S.aasta_3_prognoos)::NUMERIC(14, 2)                AS aasta_3_prognoos,
                        sum(S.eelarve_tekkepohine_kinnitatud)::NUMERIC(14, 2)  AS eelarve_tekkepohine_kinnitatud,
                        sum(S.eelarve_tekkepohine_tapsustatud)::NUMERIC(14, 2) AS eelarve_tekkepohine_tapsustatud,
                        string_agg(S.selg, ',')                                AS selg
                 FROM preReport S
                          INNER JOIN ou.rekv r
                                     ON r.id = S.rekvid
                 GROUP BY S.rekvid, r.parentid, S.artikkel, S.tegev, S.allikas, S.allikas, S.tunnus, s.proj, s.uritus,
                          s.objekt
             ),
             -- kond
             qryKond AS (
                 SELECT S.idx,
                        999999:: INTEGER                                       AS rekv_id,
                        COALESCE(S.tunnus, ''):: VARCHAR(20)                   AS tunnus,
                        S.proj:: VARCHAR(20)                                   AS proj,
                        s.uritus::VARCHAR(20)                                  AS uritus,
                        s.objekt:: VARCHAR(20)                                 AS objekt,
                        COALESCE(S.tegev,
                                 '')::VARCHAR(20)                              AS tegev,
                        COALESCE(S.allikas,
                                 '')::VARCHAR(20)                              AS allikas,
                        S.artikkel::VARCHAR(20),
                        sum(S.aasta_1_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_1_tekke_taitmine,
                        sum(S.aasta_2_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_2_tekke_taitmine,
                        sum(S.aasta_2_oodatav_taitmine):: NUMERIC(14, 2)       AS aasta_2_oodatav_taitmine,
                        sum(S.aasta_3_eelnou):: NUMERIC(14, 2)                 AS aasta_3_eelnou,
                        sum(S.aasta_3_prognoos)::NUMERIC(14, 2)                AS aasta_3_prognoos,
                        sum(S.eelarve_tekkepohine_kinnitatud)::NUMERIC(14, 2)  AS eelarve_tekkepohine_kinnitatud,
                        sum(S.eelarve_tekkepohine_tapsustatud)::NUMERIC(14, 2) AS eelarve_tekkepohine_tapsustatud,
                        NULL::TEXT                                             AS selg
                 FROM qryReport S
                 WHERE l_rekvid = 63
                   AND l_kond = 1 -- только для фин. департамента
                 GROUP BY S.artikkel, S.idx, S.tunnus, S.tegev, S.allikas, s.proj, s.uritus, s.objekt
             ),
             report AS (
                 SELECT qryReport.idx,
                        qryReport.rekvId                               AS rekv_id,
                        qryReport.tunnus,
                        qryReport.proj,
                        qryReport.uritus,
                        qryReport.objekt,
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
                 GROUP BY qryReport.idx, qryReport.rekvid,
                          qryReport.tunnus, qryReport.tegev, qryReport.allikas, qryReport.artikkel, qryReport.proj,
                          qryReport.uritus, qryReport.objekt
                 UNION ALL
                 SELECT qryReport.idx,
                        qryReport.rekvId                               AS rekv_id,
                        qryReport.tunnus,
                        qryReport.proj,
                        qryReport.uritus,
                        qryReport.objekt,
                        qryReport.tegev,
                        qryReport.allikas,
                        qryReport.artikkel,
                        0                                              AS aasta_1_tekke_taitmine,
                        sum(qryReport.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        sum(qryReport.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        0                                              AS aasta_2_tekke_taitmine,
                        sum(qryReport.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        0                                              AS aasta_3_eelnou,
                        0                                              AS aasta_3_prognoos,
                        string_agg(qryReport.selg, ',')                AS selg
                 FROM qryReport
                 WHERE qryReport.artikkel = '100'
                 GROUP BY qryReport.idx, qryReport.rekvid,
                          qryReport.tunnus, qryReport.tegev, qryReport.allikas, qryReport.artikkel, qryReport.proj,
                          qryReport.uritus, qryReport.objekt
                 UNION ALL
                 SELECT 0                                              AS idx,
                        qryReport.rekvId                               AS rekv_id,
                        ''                                             AS tunnus,
                        ''                                             AS proj,
                        ''                                             AS uritus,
                        ''                                             AS objekt,
                        LEFT(qryReport.tegev, 2)::VARCHAR(20)          AS tegev,
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
                 GROUP BY qryReport.rekvid,
                          LEFT(qryReport.tegev, 2
                              )
                 UNION ALL
                 SELECT 0                                            AS idx,
                        qryKond.rekv_id                              AS rekv_id,
                        ''                                           AS tunnus,
                        ''                                           AS proj,
                        ''                                           AS uritus,
                        ''                                           AS objekt,
                        LEFT(qryKond.tegev, 2)::VARCHAR(20)          AS tegev,
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
                 GROUP BY qryKond.rekv_id, LEFT(qryKond.tegev, 2
                     )
                 UNION ALL
                 SELECT qryKond.idx,
                        qryKond.rekv_id,
                        qryKond.tunnus,
                        qryKond.proj,
                        qryKond.uritus,
                        qryKond.objekt,
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
               rep.proj,
               rep.uritus,
               rep.objekt,
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


GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER, JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulud_eelnou_pikk(DATE, INTEGER, INTEGER, JSONB) TO dbvaatleja;



SELECT *
FROM eelarve.tulud_eelnou_pikk('2023-12-31'::DATE, 63:: INTEGER, 1, jsonb_build_object('kas_aktsepteeritud', 0))
--WHERE aasta_2_oodatav_taitmine > 0


