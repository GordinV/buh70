DROP FUNCTION IF EXISTS eelarve.kulud_eelnou_detailne(DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.kulud_eelnou_detailne(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER,
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
             rekv_ids AS (SELECT r.rekv_id
                          FROM public.get_asutuse_struktuur(l_rekvid) r
                          WHERE (r.rekv_id = l_rekvid
                              OR l_kond = 1)
                            AND r.rekv_id <> 9),
             docs_types AS (
                 SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = 'JOURNAL'
             ),
             params AS (
                 SELECT l_rekvid                                                   AS rekv_id,
                        l_kond                                                     AS kond,
                        l_kpv                                                      AS kpv,
                        coalesce((l_params ->> 'proj')::TEXT, '') || '%'           AS proj,
                        coalesce((l_params ->> 'uritus')::TEXT, '') || '%'         AS uritus,
                        '%' || coalesce((l_params ->> 'allikas')::TEXT, '') || '%' AS allikas,
                        coalesce((l_params ->> 'artikkel')::TEXT, '') || '%'       AS artikkel,
                        coalesce((l_params ->> 'tegev')::TEXT, '') || '%'          AS tegev,
                        coalesce((l_params ->> 'tunnus')::TEXT, '') || '%'         AS tunnus
             ),
-- признаки, которые используются в планах
             qryTaotlused AS (SELECT DISTINCT t.rekvid, t1.tunnus
                              FROM eelarve.taotlus t
                                       INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                                   params
                              WHERE t1.tunnus IS NOT NULL
                                AND NOT empty(t1.tunnus)
                                AND t.status IN (3)
                                AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                                AND t.aasta IN (YEAR(params.kpv) - 1, YEAR(params.kpv), YEAR(params.kpv) + 1)
                                AND t1.kood2 NOT LIKE ('%RF%')
                              GROUP BY t.rekvid,
                                       t1.tunnus
                              HAVING (count(*) > 0)
             ),
             -- выберем, где используются проекты
             used_projects AS (
                 SELECT DISTINCT e.kood1 AS tegev,
                                 e.kood2 AS allikas,
                                 e.kood5 AS artikkel,
                                 t1.proj AS proj,
                                 e.rekvid
                 FROM eelarve.kulud e
                          INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                      params
                 WHERE e.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND t1.proj IS NOT NULL
                   AND NOT empty(t1.proj)
                   AND e.status <> 3
                   AND e.aasta IN (YEAR(params.kpv) - 1, YEAR(params.kpv), YEAR(params.kpv) + 1)
                   AND COALESCE(e.tunnus, '') ILIKE params.tunnus
                   AND COALESCE(e.kood1, '') ILIKE params.tegev
                   AND COALESCE(e.kood5, '') ILIKE params.artikkel
                   AND COALESCE(e.kood2, '') ILIKE params.allikas
                   AND coalesce(t1.proj, '') ILIKE params.proj
             ),
             -- выберем, где используются проекты
             used_uritused AS (
                 SELECT DISTINCT e.kood1  AS tegev,
                                 e.kood2  AS allikas,
                                 e.kood5  AS artikkel,
                                 t1.kood4 AS uritus,
                                 e.rekvid
                 FROM eelarve.kulud e
                          INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                      params
                 WHERE e.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND t1.kood4 IS NOT NULL
                   AND NOT empty(t1.kood4)
                   AND e.status <> 3
                   AND e.aasta IN (YEAR(params.kpv) - 1, YEAR(params.kpv), YEAR(params.kpv) + 1)
                   AND COALESCE(e.tunnus, '') ILIKE params.tunnus
                   AND COALESCE(e.kood1, '') ILIKE params.tegev
                   AND COALESCE(e.kood5, '') ILIKE params.artikkel
                   AND COALESCE(e.kood2, '') ILIKE params.allikas
                   AND coalesce(t1.proj, '') ILIKE params.proj
             ),

             tmp_andmik AS (
-- eelmise aasta
                 SELECT 2                                                                                     AS tyyp,
                        ''                                                                                    AS konto,
                        qry.allikas,
                        qry.tegev,
                        qry.artikkel,
                        qry.rahavoog,
                        CASE WHEN qry.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE qry.tunnus END AS tunnus,
                        qry.summa                                                                             AS tegelik,
                        YEAR(params.kpv) - 1                                                                  AS aasta,
                        12                                                                                    AS kuu,
                        qry.rekv_id,
                        CASE
                            WHEN qry.proj IS NOT NULL AND NOT empty(qry.proj) AND exists
                                (SELECT 1
                                 FROM used_projects up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.proj = qry.proj
                                   AND up.rekvid = qry.rekv_id) THEN coalesce(qry.proj, '')
                            ELSE '' END                                                                       AS proj,
                        CASE
                            WHEN qry.uritus IS NOT NULL AND NOT empty(qry.uritus) AND exists
                                (SELECT 1
                                 FROM used_uritused up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.uritus = qry.uritus
                                   AND up.rekvid = qry.rekv_id) THEN coalesce(qry.uritus, '')
                            ELSE '' END                                                                       AS uritus
                 FROM params,
                      eelarve.tekke_taitmine_detailne(make_date(YEAR(params.kpv) - 1, 1, 1),
                                                      make_date(YEAR(params.kpv) - 1, 12, 31),
                                                      params.rekv_id, params.kond, l_params) qry
                 WHERE qry.allikas NOT LIKE ('%RF%')
                   AND qry.rekv_id <> 9
                   AND qry.artikkel NOT IN ('2586')
                 UNION ALL
-- 2586
                 SELECT 2                                                                                     AS tyyp,
                        ''                                                                                    AS konto,
                        qry.allikas                                                                           AS allikas,
                        qry.tegev                                                                             AS tegev,
                        qry.artikkel                                                                          AS artikkel,
                        qry.rahavoog                                                                          AS rahavoog,
                        CASE WHEN qry.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE qry.tunnus END AS tunnus,
                        qry.summa                                                                             AS tegelik,
                        qry.aasta                                                                             AS aasta,
                        12                                                                                    AS kuu,
                        qry.rekvid                                                                            AS rekv_id,
                        CASE
                            WHEN qry.proj IS NOT NULL AND NOT empty(qry.proj) AND exists
                                (SELECT 1
                                 FROM used_projects up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.proj = qry.proj
                                   AND up.rekvid = qry.rekvid) THEN coalesce(qry.proj, '')
                            ELSE '' END                                                                       AS proj,
                        CASE
                            WHEN qry.uritus IS NOT NULL AND NOT empty(qry.uritus) AND exists
                                (SELECT 1
                                 FROM used_uritused up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.uritus = qry.uritus
                                   AND up.rekvid = qry.rekvid) THEN coalesce(qry.uritus, '')
                            ELSE '' END                                                                       AS uritus
                 FROM (
                          SELECT d.id,
                                 d.rekvid,
                                 j1.kood1                          AS tegev,
                                 j1.kood2                          AS allikas,
                                 j1.kood3                          AS rahavoog,
                                 coalesce(j1.kood4, '')            AS uritus,
                                 j1.kood5                          AS artikkel,
                                 j1.tunnus,
                                 coalesce(j1.proj, '')             AS proj,
                                 j1.summa,
                                 date_part('year', params.kpv) - 1 AS aasta
                          FROM docs.doc d
                                   INNER JOIN docs.journal j ON j.parentid = d.id
                                   INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                               params
                          WHERE d.status < 3
                            AND doc_type_id IN (SELECT id FROM docs_types)
                            AND d.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                            AND date_part('year', j.kpv) = date_part('year', params.kpv) - 1
                            AND j1.kood2 NOT LIKE ('%RF%')
                            AND j1.kood3 = '06'
                            AND LEFT(j1.deebet, 3) IN ('208', '258')
                            AND j1.kood5 IS NOT NULL
                            AND NOT empty(j1.kood5)
                      ) qry,
                      params
                 UNION ALL

--  текущий год
                 SELECT 2                                                                                     AS tyyp,
                        ''                                                                                    AS konto,
                        qry.allikas,
                        qry.tegev,
                        qry.artikkel,
                        qry.rahavoog,
                        CASE WHEN qry.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE qry.tunnus END AS tunnus,
                        qry.summa                                                                             AS tegelik,
                        YEAR(params.kpv)                                                                      AS aasta,
                        9                                                                                     AS kuu,
                        qry.rekv_id,
                        CASE
                            WHEN qry.proj IS NOT NULL AND NOT empty(qry.proj) AND exists
                                (SELECT 1
                                 FROM used_projects up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.proj = qry.proj
                                   AND up.rekvid = qry.rekv_id) THEN coalesce(qry.proj, '')
                            ELSE '' END                                                                       AS proj,
                        CASE
                            WHEN qry.uritus IS NOT NULL AND NOT empty(qry.uritus) AND exists
                                (SELECT 1
                                 FROM used_uritused up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.uritus = qry.uritus
                                   AND up.rekvid = qry.rekv_id) THEN coalesce(qry.uritus, '')
                            ELSE '' END                                                                       AS uritus
                 FROM params,
                      eelarve.tekke_taitmine_detailne(make_date(YEAR(params.kpv), 1, 1),
                                                      make_date(YEAR(params.kpv), 09, 30),
                                                      params.rekv_id, params.kond, l_params) qry
                 WHERE qry.allikas NOT LIKE ('%RF%')
                   AND qry.rekv_id <> 9
                   AND qry.artikkel NOT IN ('2586')
                 UNION ALL
-- 2586
                 SELECT 2                                                                                     AS tyyp,
                        ''                                                                                    AS konto,
                        qry.allikas                                                                           AS allikas,
                        qry.tegev                                                                             AS tegev,
                        qry.artikkel                                                                          AS artikkel,
                        qry.rahavoog                                                                          AS rahavoog,
                        CASE WHEN qry.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE qry.tunnus END AS tunnus,
                        qry.summa                                                                             AS tegelik,
                        date_part('year', params.kpv)                                                         AS aasta,
                        12                                                                                    AS kuu,
                        qry.rekvid                                                                            AS rekv_id,
                        CASE
                            WHEN qry.proj IS NOT NULL AND NOT empty(qry.proj) AND exists
                                (SELECT 1
                                 FROM used_projects up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.proj = qry.proj
                                   AND up.rekvid = qry.rekvid) THEN coalesce(qry.proj, '')
                            ELSE '' END                                                                       AS proj,
                        CASE
                            WHEN qry.uritus IS NOT NULL AND NOT empty(qry.uritus) AND exists
                                (SELECT 1
                                 FROM used_uritused up
                                 WHERE up.artikkel = qry.artikkel
                                   AND up.tegev = qry.tegev
                                   AND up.allikas = qry.allikas
                                   AND up.uritus = qry.uritus
                                   AND up.rekvid = qry.rekvid) THEN coalesce(qry.uritus, '')
                            ELSE '' END                                                                       AS uritus
                 FROM (SELECT d.id,
                              d.rekvid,
                              j1.kood1 AS tegev,
                              j1.kood2 AS allikas,
                              j1.kood3 AS rahavoog,
                              j1.kood5 AS artikkel,
                              j1.tunnus,
                              j1.proj,
                              j1.kood4 AS uritus,
                              j1.summa
                       FROM docs.doc d
                                INNER JOIN docs.journal j ON j.parentid = d.id
                                INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                            params
                       WHERE d.status < 3
                         AND doc_type_id IN (SELECT id FROM docs_types)
                         AND d.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                         AND j.kpv >= make_date(YEAR(params.kpv), 1, 1)
                         AND j.kpv <= make_date(YEAR(params.kpv), 09, 30)
                         AND j1.kood2 NOT LIKE ('%RF%')
                         AND j1.kood3 = '06'
                         AND LEFT(j1.deebet, 3) IN ('208', '258')
                         AND j1.kood5 IS NOT NULL
                         AND NOT empty(j1.kood5)
                      ) qry,
                      params
             ),
             qryAasta1 AS (
                 SELECT S.rekv_id                                                                         AS rekvid,
                        S.artikkel                                                                        AS artikkel,
                        S.tegev                                                                           AS tegev,
                        S.allikas                                                                         AS allikas,
                        CASE WHEN S.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE S.tunnus END AS tunnus,
                        coalesce(s.proj, '')                                                              AS proj,
                        coalesce(s.uritus, '')                                                            AS uritus,
                        sum(S.tegelik)                                                                    AS summa,
                        1                                                                                 AS idx,
                        NULL::TEXT                                                                        AS selg
                 FROM tmp_andmik S,
                      params
                 WHERE aasta = YEAR(params.kpv) - 1
                 GROUP BY S.rekv_id,
                          S.artikkel,
                          S.tegev,
                          S.allikas,
                          S.tunnus,
                          s.proj,
                          s.uritus
             ),
             qryAasta2 AS (
                 SELECT S.rekv_id              AS rekvid,
                        S.artikkel             AS artikkel,
                        S.tegev                AS tegev,
                        S.allikas              AS allikas,
                        S.tunnus               AS tunnus,
                        coalesce(s.proj, '')   AS proj,
                        coalesce(s.uritus, '') AS uritus,
                        sum(S.tegelik)         AS summa,
                        1                      AS idx,
                        NULL::TEXT             AS selg
                 FROM tmp_andmik S,
                      params
                 WHERE aasta = YEAR(params.kpv)
                 GROUP BY S.rekv_id,
                          S.artikkel,
                          S.tegev,
                          S.allikas,
                          S.tunnus,
                          s.proj,
                          s.uritus
             ),
             -- текущего года

             qryAasta4 AS (
                 -- Сумма всех строк с данным Art Tekke põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5                                                                            AS artikkel,
                        t1.kood1                                                                            AS tegev,
                        t1.kood2                                                                            AS allikas,
                        CASE WHEN t1.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE t1.tunnus END AS tunnus,
                        coalesce(t1.proj, '')                                                               AS proj,
                        coalesce(t1.kood4, '')                                                              AS uritus,
                        sum(summa)                                                                          AS summa,
                        sum(oodatav_taitmine)                                                               AS oodatav_taitmine,
                        string_agg(REPLACE(t1.selg::TEXT, E'\r\n', ''), ' '::TEXT)                          AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                      params
                 WHERE t.aasta = YEAR(params.kpv) + 1
                   AND t.status IN (3)
                   AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND t1.kood2 NOT ILIKE ('%RF%')
                   AND t1.kood2 ILIKE params.allikas
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )
                 GROUP BY t1.kood5,
                          t1.kood1,
                          t1.kood2,
                          t1.tunnus,
                          t1.proj,
                          t1.kood4,
                          t.rekvid
             ),
             qryAasta5 AS (
                 -- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- Сумма всех строк с данным Art Kassa põhine в проекте бюджета
-- следующего года (Taotlused -esitatud)
                 -- следующего года (Taotlused -esitatud)
                 SELECT t.rekvid,
                        t1.kood5                                                                            AS artikkel,
                        t1.kood1                                                                            AS tegev,
                        t1.kood2                                                                            AS allikas,
                        CASE WHEN t1.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE t1.tunnus END AS tunnus,
                        coalesce(t1.proj, '')                                                               AS proj,
                        coalesce(t1.kood4, '')                                                              AS uritus,
                        sum(summa_kassa)                                                                    AS summa,
                        sum(oodatav_taitmine)                                                               AS oodatav_taitmine,
                        string_agg(REPLACE(t1.selg::TEXT, E'\r\n', ''), ' '::TEXT)                          AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                      params
                 WHERE t.aasta = YEAR(params.kpv) + 1
                   AND t.status IN (3)
                   AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND t1.kood2 NOT ILIKE ('%RF%')
                   AND t1.kood2 ILIKE params.allikas
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )
                 GROUP BY t1.kood5,
                          t1.kood1,
                          t1.kood2,
                          t1.tunnus,
                          t1.proj,
                          t1.kood4,
                          t.rekvid
             ),
             qryAasta6 AS (
-- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine kinnitatud
-- текущего года

                 SELECT e.rekvid,
                        e.kood5                AS artikkel,
                        e.kood1                AS tegev,
                        e.kood2                AS allikas,
                        e.tunnus               AS tunnus,
                        coalesce(t1.proj, '')  AS proj,
                        coalesce(t1.kood4, '') AS uritus,
                        sum(e.summa)           AS summa,
                        NULL::TEXT             AS selg
                 FROM eelarve.eelarve e
                          INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                      params
                 WHERE e.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND aasta = YEAR(params.kpv)
                   AND e.kood2 NOT ILIKE ('%RF%')
                   AND e.kood2 ILIKE params.allikas
                   AND e.kpv IS NULL
                   AND e.status <> 3
                   AND e.kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid,
                          e.kood5,
                          e.kood1,
                          e.kood2,
                          e.tunnus,
                          t1.proj,
                          t1.kood4
             ),
             qryAasta7 AS (
-- Сумма всех строк с данным Art  в блоке Eelarve Tekkepõhine täpsustatud
-- текущего года seisuga 30.09.2022

                 SELECT e.rekvid,
                        e.kood5                AS artikkel,
                        e.kood1                AS tegev,
                        e.kood2                AS allikas,
                        e.tunnus               AS tunnus,
                        coalesce(t1.proj, '')  AS proj,
                        coalesce(t1.kood4, '') AS uritus,
                        sum(e.summa)           AS summa,
                        NULL::TEXT             AS selg
                 FROM eelarve.eelarve e
                          INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                      params
                 WHERE e.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND aasta = YEAR(params.kpv)
                   AND (e.kpv IS NULL OR e.kpv <= make_date(YEAR(params.kpv), 09, 30))
                   AND e.kood2 NOT ILIKE ('%RF%')
                   AND e.kood2 ILIKE params.allikas
                   AND e.status <> 3
                   AND e.kood5 IN (SELECT kood FROM qryArtikkel)
                 GROUP BY e.rekvid,
                          e.kood5,
                          e.kood1,
                          e.kood2,
                          e.tunnus,
                          t1.proj,
                          t1.kood4
             ),
             qryAasta8 AS (
                 -- oodatav taitine
                 SELECT t.rekvid,
                        t1.kood5                                                                            AS artikkel,
                        t1.kood1                                                                            AS tegev,
                        t1.kood2                                                                            AS allikas,
                        CASE WHEN t1.tunnus IN ('null', '04', '1.', '3.3', '13') THEN '' ELSE t1.tunnus END AS tunnus,
                        coalesce(t1.proj, '')                                                               AS proj,
                        coalesce(t1.kood4, '')                                                              AS uritus,
                        sum(oodatav_taitmine)                                                               AS summa,
                        string_agg(REPLACE(t1.selg::TEXT, E'\r\n', ''), ' '::TEXT)                          AS selg
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                      params
                 WHERE t.aasta = YEAR(params.kpv) + 1
                   AND t.status IN (3)
                   AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND t1.kood2 NOT ILIKE ('%RF%')
                   AND t1.kood2 ILIKE params.allikas
                   AND t1.kood5 IN (
                     SELECT kood
                     FROM qryArtikkel
                 )
                 GROUP BY t1.kood5,
                          t1.kood1,
                          t1.kood2,
                          t1.tunnus,
                          t1.proj,
                          t1.kood4,
                          t.rekvid
             ),

             preReport AS (
                 SELECT qry.rekvid,
                        qry.artikkel,
                        qry.tegev,
                        qry.allikas,
                        qry.proj,
                        qry.uritus,
                        CASE
                            WHEN EXISTS(
                                    SELECT 1 FROM qryTaotlused t WHERE t.tunnus = qry.tunnus AND rekvid = qry.rekvid)
                                THEN qry.tunnus
                            ELSE '' END                       AS tunnus,
                        (qry.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        (qry.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        (qry.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        (qry.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        (qry.aasta_3_prognoos)                AS aasta_3_prognoos,
                        (qry.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        (qry.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        rtrim(qry.selg, E'\r\n')              AS selg
                 FROM (
                          -- oodatav taitmine
                          SELECT q.rekvid                 AS rekvid,
                                 2,
                                 q.artikkel,
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 0:: NUMERIC(14, 2)       AS aasta_1_tekke_taitmine,
                                 0:: NUMERIC(14, 2)       AS aasta_2_tekke_taitmine,
                                 q.summa:: NUMERIC(14, 2) AS aasta_2_oodatav_taitmine,
                                 0:: NUMERIC(14, 2)       AS aasta_3_eelnou,
                                 0:: NUMERIC(14, 2)       AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2)       AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)           eelarve_tekkepohine_tapsustatud,
                                 q.selg::TEXT               AS selg
                          FROM qryAasta8 q
                          UNION ALL
                          SELECT q.rekvid           AS rekvid,
                                 q.idx,
                                 q.artikkel,
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 q.summa            AS aasta_1_tekke_taitmine,
                                 0                  AS aasta_2_tekke_taitmine,
                                 0                  AS aasta_2_oodatav_taitmine,
                                 0                  AS aasta_3_eelnou,
                                 0                  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)     eelarve_tekkepohine_tapsustatud,
                                 q.selg::TEXT         AS selg
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
                                 0                  AS aasta_1_tekke_taitmine,
                                 q.summa            AS aasta_2_tekke_taitmine,
                                 0                  AS aasta_2_oodatav_taitmine,
                                 0                  AS aasta_3_eelnou,
                                 0                  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)     eelarve_tekkepohine_tapsustatud,
                                 q.selg::TEXT         AS selg
                          FROM qryAasta2 q
                          UNION ALL
                          SELECT q.rekvid              AS rekv_id,
                                 2                     AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 summa::NUMERIC(14, 2) AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)     AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2)    AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)        eelarve_tekkepohine_tapsustatud,
                                 ltrim(rtrim(REPLACE(q.selg, E'\r\n', '')))::TEXT
                          FROM qryAasta4 q
                          UNION ALL
                          SELECT q.rekvid              AS rekv_id,
                                 2                     AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 0::NUMERIC(14, 2)     AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)     AS aasta_3_eelnou,
                                 summa::NUMERIC(14, 2) AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2)    AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)        eelarve_tekkepohine_tapsustatud,
                                 ltrim(rtrim(q.selg, E'\r\n'))::TEXT
                          FROM qryAasta5 q
                          UNION ALL
                          SELECT q.rekvid               AS rekv_id,
                                 2                      AS idx,
                                 q.artikkel:: VARCHAR(20),
                                 q.tegev,
                                 q.allikas,
                                 q.tunnus,
                                 q.proj,
                                 q.uritus,
                                 0::NUMERIC(14, 2)      AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)      AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)      AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)      AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)      AS aasta_3_prognoos,
                                 summa:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 0::NUMERIC(14, 2)         eelarve_tekkepohine_tapsustatud,
                                 q.selg::TEXT             AS selg
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
                                 0::NUMERIC(14, 2)  AS aasta_1_tekke_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_2_tekke_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_2_oodatav_taitmine,
                                 0::NUMERIC(14, 2)  AS aasta_3_eelnou,
                                 0::NUMERIC(14, 2)  AS aasta_3_prognoos,
                                 0:: NUMERIC(14, 2) AS eelarve_tekkepohine_kinnitatud,
                                 summa::NUMERIC(14, 2) eelarve_tekkepohine_tapsustatud,
                                 q.selg::TEXT         AS selg
                          FROM qryAasta7 q
                      ) qry,
                      params
                 WHERE coalesce(qry.tegev, '') LIKE params.tegev
                   AND coalesce(qry.allikas, '') LIKE params.allikas
                   AND coalesce(qry.tunnus, '') LIKE params.tunnus
                   AND coalesce(qry.artikkel, '') LIKE params.artikkel
                   AND coalesce(qry.proj, '') LIKE params.proj
                   AND coalesce(qry.uritus, '') LIKE params.uritus
             ),
             qryReport AS (
                 SELECT S.rekvid:: INTEGER,
                        r.parentid,
                        CASE
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_Sotsiaaltoetused THEN 100
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_SihtotstarbelisedToetusedTegevuskuludeks THEN 200
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_MittesihtotstarbelisedToetused THEN 300
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_Toojoukulud THEN 400
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_Majandamiskulud THEN 500
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_MuudKulud THEN 600
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_PohivaraSoetus THEN 700
                            WHEN ARRAY [S.artikkel::TEXT] <@ a_FinanseerimisTegevus THEN 800
                            ELSE 900 END                                       AS idx,
                        S.artikkel::VARCHAR(20),
                        COALESCE(S.tegev, '')::VARCHAR(20)                     AS tegev,
                        COALESCE(S.allikas, '')::VARCHAR(20)                   AS allikas,
                        COALESCE(S.tunnus, ''):: VARCHAR(20)                   AS tunnus,
                        s.proj,
                        s.uritus,
                        sum(S.aasta_1_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_1_tekke_taitmine,
                        sum(S.aasta_2_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_2_tekke_taitmine,
                        sum(S.aasta_2_oodatav_taitmine):: NUMERIC(14, 2)       AS aasta_2_oodatav_taitmine,
                        sum(S.aasta_3_eelnou):: NUMERIC(14, 2)                 AS aasta_3_eelnou,
                        sum(S.aasta_3_prognoos)::NUMERIC(14, 2)                AS aasta_3_prognoos,
                        sum(S.eelarve_tekkepohine_kinnitatud)::NUMERIC(14, 2)  AS eelarve_tekkepohine_kinnitatud,
                        sum(S.eelarve_tekkepohine_tapsustatud)::NUMERIC(14, 2) AS eelarve_tekkepohine_tapsustatud,
                        string_agg(S.selg, ',')                                AS selg
                 FROM preReport S
                          INNER JOIN qryArtikkel l ON l.kood = S.artikkel
                          INNER JOIN ou.rekv r ON r.id = S.rekvid
                 GROUP BY S.rekvid, r.parentid, S.artikkel, S.tegev, S.allikas, S.tunnus, s.proj, s.uritus
             ),
             -- kond
             qryKond AS (
                 SELECT S.idx,
                        999999:: INTEGER                                       AS rekv_id,
                        COALESCE(S.tunnus, ''):: VARCHAR(20)                   AS tunnus,
                        COALESCE(S.tegev, '')::VARCHAR(20)                     AS tegev,
                        COALESCE(S.allikas, '')::VARCHAR(20)                   AS allikas,
                        S.artikkel::VARCHAR(20),
                        s.proj,
                        s.uritus,
                        sum(S.aasta_1_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_1_tekke_taitmine,
                        sum(S.eelarve_tekkepohine_kinnitatud)::NUMERIC(14, 2)  AS eelarve_tekkepohine_kinnitatud,
                        sum(S.eelarve_tekkepohine_tapsustatud)::NUMERIC(14, 2) AS eelarve_tekkepohine_tapsustatud,
                        sum(S.aasta_2_tekke_taitmine):: NUMERIC(14, 2)         AS aasta_2_tekke_taitmine,
                        sum(S.aasta_2_oodatav_taitmine):: NUMERIC(14, 2)       AS aasta_2_oodatav_taitmine,
                        sum(S.aasta_3_eelnou):: NUMERIC(14, 2)                 AS aasta_3_eelnou,
                        sum(S.aasta_3_prognoos)::NUMERIC(14, 2)                AS aasta_3_prognoos,
                        NULL::TEXT                                             AS selg
                 FROM qryReport S,
                      params
                 WHERE params.rekv_id = 63
                   AND params.kond = 1 -- только для фин. департамента
                 GROUP BY S.artikkel,
                          S.idx,
                          S.tunnus,
                          S.tegev,
                          S.allikas,
                          s.proj,
                          s.uritus
             ),
             report AS (
                 WITH pre_report AS (
                     SELECT qryReport.idx,
                            qryReport.rekvId                               AS rekv_id,
                            qryReport.tunnus,
                            qryReport.tegev,
                            qryReport.allikas,
                            qryReport.artikkel,
                            qryReport.proj,
                            qryReport.uritus,
                            sum(qryReport.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                            sum(qryReport.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                            sum(qryReport.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                            sum(qryReport.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                            sum(qryReport.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                            sum(qryReport.aasta_3_eelnou)                  AS aasta_3_eelnou,
                            sum(qryReport.aasta_3_prognoos)                AS aasta_3_prognoos,
                            string_agg(qryReport.selg, ',')                AS selg
                     FROM qryReport
                     GROUP BY qryReport.idx,
                              qryreport.rekvid,
                              qryReport.tunnus,
                              qryReport.tegev,
                              qryReport.allikas,
                              qryReport.artikkel,
                              qryReport.proj,
                              qryReport.uritus)
                 SELECT qryReport.idx,
                        qryReport.rekv_id                              AS rekv_id,
                        CASE
                            WHEN qryReport.tunnus IN ('null', '04', '1.', '3.3', '13') THEN ''
                            ELSE qryReport.tunnus END                  AS tunnus,
                        qryReport.tegev,
                        qryReport.allikas,
                        qryReport.artikkel,
                        qryReport.proj,
                        qryReport.uritus,
                        sum(qryReport.aasta_1_tekke_taitmine)          AS aasta_1_tekke_taitmine,
                        sum(qryReport.eelarve_tekkepohine_kinnitatud)  AS eelarve_tekkepohine_kinnitatud,
                        sum(qryReport.eelarve_tekkepohine_tapsustatud) AS eelarve_tekkepohine_tapsustatud,
                        sum(qryReport.aasta_2_tekke_taitmine)          AS aasta_2_tekke_taitmine,
                        sum(qryReport.aasta_2_oodatav_taitmine)        AS aasta_2_oodatav_taitmine,
                        sum(qryReport.aasta_3_eelnou)                  AS aasta_3_eelnou,
                        sum(qryReport.aasta_3_prognoos)                AS aasta_3_prognoos,
                        string_agg(qryReport.selg, ',')                AS selg
                 FROM pre_report qryReport
                 GROUP BY qryReport.idx,
                          qryreport.rekv_id,
                          CASE
                              WHEN qryReport.tunnus IN ('null', '04', '1.', '3.3', '13') THEN ''
                              ELSE qryReport.tunnus END,
                          qryReport.tegev,
                          qryReport.allikas,
                          qryReport.artikkel,
                          qryReport.proj,
                          qryReport.uritus
                 UNION ALL
                 SELECT 0                                              AS idx,
                        qryReport.rekvId                               AS rekv_id,
                        ''                                             AS tunnus,
                        LEFT(qryReport.tegev, 2)::VARCHAR(20)          AS tegev,
                        ''                                             AS allikas,
                        ''                                             AS artikkel,
                        ''                                             AS proj,
                        ''                                             AS uritus,
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
                          LEFT(qryReport.tegev, 2)
                 UNION ALL
                 SELECT 0                                            AS idx,
                        qryKond.rekv_id                              AS rekv_id,
                        ''                                           AS tunnus,
                        LEFT(qryKond.tegev, 2)::VARCHAR(20)          AS tegev,
                        ''                                           AS allikas,
                        ''                                           AS artikkel,
                        ''                                           AS proj,
                        ''                                           AS uritus,
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
                 GROUP BY qryKond.rekv_id,
                          LEFT(qryKond.tegev, 2)
                 UNION ALL
                 SELECT *
                 FROM qryKond
             )
        SELECT rep.rekv_id:: INTEGER,
               rep.idx:: INTEGER,
               rep.artikkel:: VARCHAR(20),
               rep.tegev:: VARCHAR(20),
               rep.allikas::VARCHAR(20),
               rep.tunnus:: VARCHAR(20),
               rep.proj::VARCHAR(20),
               rep.uritus::VARCHAR(20),
               rep.aasta_1_tekke_taitmine:: NUMERIC(14, 2),
               rep.aasta_2_tekke_taitmine:: NUMERIC(14, 2),
               rep.aasta_2_oodatav_taitmine:: NUMERIC(14, 2),
               rep.aasta_3_eelnou:: NUMERIC(14, 2),
               rep.aasta_3_prognoos ::NUMERIC(14, 2),
               rep.eelarve_tekkepohine_kinnitatud ::NUMERIC(14, 2),
               rep.eelarve_tekkepohine_tapsustatud ::NUMERIC(14, 2),
               rep.selg
        FROM report rep
        WHERE rep.artikkel <> ''
          AND (rep.aasta_1_tekke_taitmine <> 0
            OR rep.aasta_2_tekke_taitmine <> 0
            OR rep.aasta_2_oodatav_taitmine <> 0
            OR rep.aasta_3_eelnou <> 0
            OR rep.aasta_3_prognoos <> 0
            OR rep.eelarve_tekkepohine_kinnitatud <> 0
            OR rep.eelarve_tekkepohine_tapsustatud <> 0
            );
END
$$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou_detailne(DATE, INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou_detailne(DATE, INTEGER, INTEGER,JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou_detailne(DATE, INTEGER, INTEGER,JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.kulud_eelnou_detailne(DATE, INTEGER, INTEGER,JSONB) TO dbvaatleja;

/*
SELECT  *
FROM eelarve.kulud_eelnou_detailne('2023-03-31'::DATE, 63:: INTEGER, 1)
where aasta_2_oodatav_taitmine > 0
ORDER BY rekv_id, ARTIKKEL, tegev, TUNNUS

*/--where idx = 100



