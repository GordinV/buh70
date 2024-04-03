DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(l_aasta INTEGER,
                                                                               l_kpv_1 DATE,
                                                                               l_kpv_2 DATE,
                                                                               l_rekvid INTEGER,
                                                                               l_kond INTEGER,
                                                                               l_params JSONB DEFAULT NULL)
    RETURNS TABLE (
        rekv_id                  INTEGER,
        eelarve_kinni            NUMERIC(14, 2),
        eelarve_parandatud       NUMERIC(14, 2),
        eelarve_kassa_kinni      NUMERIC(14, 2),
        eelarve_kassa_parandatud NUMERIC(14, 2),
        tegelik                  NUMERIC(14, 2),
        kassa                    NUMERIC(14, 2),
        tegev                    VARCHAR(20),
        allikas                  VARCHAR(20),
        artikkel                 VARCHAR(20),
        rahavoog                 VARCHAR(20),
        tunnus                   VARCHAR(20),
        proj                     VARCHAR(20),
        uritus                   VARCHAR(20),
        objekt                   VARCHAR(20),
        idx                      INTEGER

    )
AS
$BODY$
WITH params AS (
    SELECT l_kpv_1                                       AS kpv1,
           l_kpv_2                                       AS kpv2,
           l_aasta                                       AS aasta,
           l_rekvid                                      AS rekv_id,
           l_kond                                        AS kond,
           coalesce((l_params ->> 'tunnus')::TEXT, '')   AS tunnus,
           coalesce((l_params ->> 'tegev')::TEXT, '')    AS tegev,
           coalesce((l_params ->> 'artikkel')::TEXT, '') AS artikkel,
           coalesce((l_params ->> 'allikas')::TEXT, '')  AS allikas,
           coalesce((l_params ->> 'rahavoog')::TEXT, '') AS rahavoog,
           coalesce((l_params ->> 'proj')::TEXT, '')     AS proj,
           coalesce((l_params ->> 'uritus')::TEXT, '')   AS uritus,
           coalesce((l_params ->> 'objekt')::TEXT, '')   AS objekt,
           CASE
               WHEN coalesce(l_params ->> 'taotlus_statusid', '0')::INTEGER = 1 THEN ARRAY [3]
               ELSE ARRAY [0,1,2,3] END                  AS taotlus_statusid
),
     rekv_ids AS (
         SELECT a.rekv_id
         FROM params,
              get_asutuse_struktuur(params.rekv_id) a
         WHERE a.rekv_id = CASE
                               WHEN params.kond = 1
                                   -- kond
                                   THEN a.rekv_id
                               ELSE params.rekv_id END),

     qryArtikklid AS (
         SELECT l.kood
         FROM libs.library l
         WHERE l.tun5 = 1 --tulud
           AND l.status <> 3
           AND l.library = 'TULUDEALLIKAD'
     ),

     cur_tulude_kassa_taitmine AS (
         SELECT qry.*
         FROM params,
              eelarve.uus_kassa_tulu_taitmine_detailne(params.kpv1, params.kpv2, params.rekv_id, params.kond) qry
         WHERE qry.artikkel <> '3501' -- Убери, пожалуйста во всех отчетах Tulude eelarve täitmine ХХХХХ строку 3501 - это не доходы от деятельности, а внутренние переводы
           AND (l_params IS NULL OR coalesce(qry.tunnus, '') ILIKE params.tunnus + '%')
           AND (l_params IS NULL OR coalesce(qry.tegev, '') ILIKE params.tegev + '%')
           AND (l_params IS NULL OR coalesce(qry.artikkel, '') ILIKE params.artikkel + '%')
           AND (l_params IS NULL OR coalesce(qry.allikas, '') ILIKE params.allikas + '%')
           AND (l_params IS NULL OR coalesce(qry.rahavoog, '') ILIKE params.rahavoog + '%')
           AND (l_params IS NULL OR coalesce(qry.proj, '') ILIKE params.proj + '%')
           AND (l_params IS NULL OR coalesce(qry.uritus, '') ILIKE params.uritus + '%')
           AND (l_params IS NULL OR coalesce(qry.objekt, '') ILIKE params.objekt + '%')
--      AND qry.rekv_id <> 9 -- TP18510139, VB убрать из отчетов
     ),
     cur_tulude_taitmine AS (
         SELECT qry.*
         FROM params,
              eelarve.tulu_taitmine_detailne(params.kpv1, params.kpv2, params.rekv_id, params.kond) qry
         WHERE qry.artikkel <> '3501'
           AND (l_params IS NULL OR coalesce(qry.tunnus, '') ILIKE params.tunnus + '%')
           AND (l_params IS NULL OR coalesce(qry.tegev, '') ILIKE params.tegev + '%')
           AND (l_params IS NULL OR
                coalesce(qry.artikkel, '') ILIKE params.artikkel + '%')
           AND (l_params IS NULL OR coalesce(qry.allikas, '') ILIKE params.allikas + '%')
           AND (l_params IS NULL OR
                coalesce(qry.rahavoog, '') ILIKE params.rahavoog + '%')
           AND (l_params IS NULL OR coalesce(qry.proj, '') ILIKE params.proj + '%')
           AND (l_params IS NULL OR coalesce(qry.uritus, '') ILIKE params.uritus + '%')
           AND (l_params IS NULL OR coalesce(qry.objekt, '') ILIKE params.objekt + '%')
     ),
     laekumised_eelarvesse AS (
         SELECT j.rekvid,
                0            AS eelarve_kinni,
                0            AS eelarve_parandatud,
                0            AS eelarve_kassa_kinni,
                0            AS eelarve_kassa_parandatud,
                0            AS tegelik,
                sum(j.summa) AS kassa,
                j.kood1      AS tegev,
                j.kood2      AS allikas,
                j.kood5      AS artikkel,
                j.kood3      AS rahavoog,
                j.tunnus     AS tunnus,
                j.proj,
                j.uritus,
                j.objekt,
                200          AS idx
         FROM (SELECT -1 * CASE
                               WHEN (ltrim(rtrim(j1.kood5)) = '3502'
                                   AND (ltrim(rtrim(kood3)) IN ('01', '05', '')
                                       OR kood3 IS NULL)) THEN 0
                               ELSE j1.summa END AS summa,
                      j1.kood1,
                      j1.kood2,
                      j1.kood3,
                      j1.kood5,
                      j1.tunnus,
                      j1.proj,
                      j1.kood4                   AS uritus,
                      j1.objekt,
                      d.rekvid,
                      d.id,
                      j.kpv,
                      j1.kreedit
               FROM docs.doc D
                        INNER JOIN docs.journal j ON j.parentid = D.id
                        INNER JOIN docs.journal1 j1 ON j1.parentid = j.id,
                    params
               WHERE j.kpv >= make_date(year(params.kpv2), 1, 1)
                 AND j.kpv <= params.kpv2
                 AND left(j1.deebet, 6) IN ('100100', '999999') -- поступление доходов
                 AND left(j1.kreedit, 6) = '700001'
                 AND d.rekvid = 63                              -- только фин. департамент
                 --строка art 1532 в доходах может быть только с rahavoog 02, соответственно с rahavoog 23  быть не далжно
                 AND (CASE WHEN j1.kood5 = '1532' AND j1.kood3 IN ('23', '21') THEN FALSE ELSE TRUE END)
                 AND d.status <> 3
                 AND j1.kood5 <> '3501'
                 AND j1.kood5 IN (SELECT kood FROM qryArtikklid)
                 AND (l_params IS NULL OR
                      coalesce(j1.tunnus, '') ILIKE params.tunnus + '%')
                 AND (l_params IS NULL OR coalesce(j1.kood1, '') ILIKE params.tegev + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood5, '') ILIKE params.artikkel + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood2, '') ILIKE params.allikas + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood3, '') ILIKE params.rahavoog + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.proj, '') ILIKE params.proj + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood4, '') ILIKE params.uritus + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.objekt, '') ILIKE params.objekt + '%')
              ) j,
              params
         WHERE params.kond > 0
           AND params.rekv_id = 63 -- только если отчет для фин.департамента
         GROUP BY j.rekvid, j.kood1, j.kood2, j.kood3, j.kood5, j.tunnus, j.proj, j.uritus, j.objekt
     ),
     qryReport AS (
         SELECT qry.rekvid,
                sum(qry.eelarve_kinni)            AS eelarve_kinni,
                sum(qry.eelarve_parandatud)       AS eelarve_parandatud,
                sum(qry.eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                sum(qry.eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                sum(qry.tegelik)                  AS tegelik,
                sum(qry.kassa)                    AS kassa,
                qry.tegev,
                qry.allikas,
                qry.artikkel,
                qry.rahavoog,
                qry.tunnus                   AS tunnus,
                qry.proj AS proj,
                qry.uritus                   AS uritus,
                qry.objekt                   AS objekt,
                qry.idx
         FROM (
                  SELECT e.rekvid,
                         e.summa                 AS eelarve_kinni,
                         e.summa_kassa           AS eelarve_kassa_kinni,
                         0:: NUMERIC             AS eelarve_parandatud,
                         0:: NUMERIC             AS eelarve_kassa_parandatud,
                         0 :: NUMERIC            AS tegelik,
                         0 :: NUMERIC            AS kassa,
                         coalesce(e.kood1, '')   AS tegev,
                         coalesce(e.kood2, '')   AS allikas,
                         coalesce(e.kood5, '')   AS artikkel,
                         coalesce(e.kood3, '')   AS rahavoog,
                         COALESCE(e.tunnus,
                                  '')            AS tunnus,
                         coalesce(t1.proj, '')   AS proj,
                         coalesce(t1.kood4, '')  AS uritus,
                         coalesce(t1.objekt, '') AS objekt,
                         CASE
                             WHEN ltrim(rtrim(e.kood5)) = '2585' AND ltrim(rtrim(e.kood2)) = '80' THEN 120
                             ELSE 200 END        AS idx
                  FROM eelarve.tulud e
                           LEFT OUTER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                       params
                  WHERE e.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND e.aasta = params.aasta
                    AND e.kpv IS NULL
                    AND e.status <> 3
                    AND (l_params IS NULL OR
                         coalesce(e.tunnus, '') ILIKE params.tunnus + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood1, '') ILIKE params.tegev + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood5, '') ILIKE params.artikkel + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood2, '') ILIKE params.allikas + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood3, '') ILIKE params.rahavoog + '%')
                    AND (l_params IS NULL OR
                         coalesce(t1.proj, '') ILIKE params.proj + '%')
                    AND (l_params IS NULL OR
                         coalesce(t1.kood4, '') ILIKE params.uritus + '%')
                    AND (l_params IS NULL OR
                         coalesce(t1.objekt, '') ILIKE params.objekt + '%')
                  UNION ALL
                  SELECT e.rekvid,
                         0 :: NUMERIC                                                        AS eelarve_kinni,
                         0 :: NUMERIC                                                        AS eelarve_kassa_kinni,
                         e.summa                                                             AS eelarve_parandatud,
                         e.summa_kassa                                                       AS eelarve_kassa_parandatud,
                         0 :: NUMERIC                                                        AS tegelik,
                         0 :: NUMERIC                                                        AS kassa,
                         coalesce(e.kood1, '')                                               AS tegev,
                         coalesce(e.kood2, '')                                               AS allikas,
                         coalesce(e.kood5, '')                                               AS artikkel,
                         coalesce(e.kood3, '')                                               AS rahavoog,
                         COALESCE(e.tunnus, '')                                              AS tunnus,
                         COALESCE(t1.proj, '')                                               AS proj,
                         COALESCE(t1.kood4, '')                                              AS uritus,
                         coalesce(t1.objekt, '')                                             AS objekt,
                         CASE WHEN e.kood5 = '2585' AND e.kood2 = '80' THEN 120 ELSE 200 END AS idx
                  FROM eelarve.tulud e
                           LEFT OUTER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                       params
                  WHERE e.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND e.aasta = params.aasta
                    AND (e.kpv IS NULL OR e.kpv <= COALESCE(params.kpv2, CURRENT_DATE))
                    AND e.status <> 3
                    AND (l_params IS NULL OR
                         coalesce(e.tunnus, '') ILIKE params.tunnus + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood1, '') ILIKE params.tegev + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood5, '') ILIKE params.artikkel + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood2, '') ILIKE params.allikas + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood3, '') ILIKE params.rahavoog + '%')
                    AND (l_params IS NULL OR
                         coalesce(t1.proj, '') ILIKE params.proj + '%')
                    AND (l_params IS NULL OR
                         coalesce(t1.kood4, '') ILIKE params.uritus + '%')
                    AND (l_params IS NULL OR
                         coalesce(t1.objekt, '') ILIKE params.objekt + '%')
                  UNION ALL
                  SELECT rekv_id                 AS rekvid,
                         0 :: NUMERIC            AS eelarve_kinni,
                         0 :: NUMERIC            AS eelarve_parandatud,
                         0 :: NUMERIC            AS eelarve_kassa_kinni,
                         0 :: NUMERIC            AS eelarve_kassa_parandatud,
                         summa                   AS tegelik,
                         0 :: NUMERIC            AS kassa,
                         COALESCE(tegev, '')     AS tegev,
                         COALESCE(allikas, '')   AS allikas,
                         COALESCE(artikkel, '')  AS artikkel,
                         COALESCE(rahavoog, '')  AS rahavoog,
                         COALESCE(tunnus, '')    AS tunnus,
                         coalesce(ft.proj, '')   AS proj,
                         coalesce(ft.uritus, '') AS uritus,
                         coalesce(ft.objekt, '') AS objekt,
                         CASE
                             WHEN COALESCE(artikkel, '') = '2585' AND COALESCE(allikas, '') = '80' THEN 120
                             ELSE 200 END        AS idx
                  FROM cur_tulude_taitmine ft
                  WHERE ft.artikkel IS NOT NULL
                    AND NOT empty(ft.artikkel)
--                    AND ft.rekv_id <> 9 -- TP18510139, VB убрать из отчетов
                  UNION ALL
                  SELECT kt.rekv_id                                                           AS rekvid,
                         0 :: NUMERIC                                                         AS eelarve_kinni,
                         0 :: NUMERIC                                                         AS eelarve_parandatud,
                         0 :: NUMERIC                                                         AS eelarve_kassa_kinni,
                         0 :: NUMERIC                                                         AS eelarve_kassa_parandatud,
                         0 :: NUMERIC                                                         AS tegelik,
                         summa                                                                AS kassa,
                         coalesce(tegev, ''),
                         coalesce(allikas, ''),
                         coalesce(artikkel, ''),
                         coalesce(rahavoog, ''),
                         COALESCE(tunnus, '')                                                 AS tunnus,
                         COALESCE(kt.proj, '')                                                AS proj,
                         coalesce(kt.uritus, '')                                              AS uritus,
                         COALESCE(kt.objekt, '')                                              AS objekt,
                         CASE WHEN artikkel = '2585' AND allikas = '80' THEN 120 ELSE 200 END AS idx
                  FROM cur_tulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND NOT empty(kt.artikkel)
--                    AND kt.rekv_id <> 9 -- TP18510139, VB убрать из отчетов
              ) qry
--         WHERE qry.rekvid <> 9
         GROUP BY rekvid,
                  tegev,
                  allikas,
                  artikkel,
                  rahavoog,
                  tunnus,
                  proj,
                  uritus,
                  objekt,
                  idx
     ),
     qry3502 AS (
         SELECT rekvid,
                sum(eelarve_kinni)            AS eelarve_kinni,
                sum(eelarve_parandatud)       AS eelarve_parandatud,
                sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                sum(tegelik)                  AS tegelik,
                sum(kassa)                    AS kassa,
                tegev,
                allikas,
                artikkel,
                rahavoog,
                tunnus,
                proj,
                uritus,
                objekt,
                220                           AS idx
         FROM qryReport
         WHERE ltrim(rtrim(artikkel)) = '3502'
           AND (rahavoog IS NULL OR ltrim(rtrim(rahavoog)) IN ('01', '05', ''))
         GROUP BY rekvid,
                  tegev,
                  allikas,
                  artikkel,
                  rahavoog,
                  tunnus,
                  proj,
                  uritus,
                  objekt,
                  idx
     ),
     qryPreReport AS (
         SELECT *
         FROM (
                  SELECT rekvid,
                         sum(eelarve_kinni)            AS eelarve_kinni,
                         sum(eelarve_parandatud)       AS eelarve_parandatud,
                         sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                         SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                         sum(tegelik)                  AS tegelik,
                         sum(kassa)                    AS kassa,
                         tegev,
                         allikas,
                         artikkel,
                         rahavoog,
                         tunnus,
                         proj,
                         uritus,
                         objekt,
                         idx
                  FROM qryReport
                  WHERE ltrim(rtrim(artikkel)) NOT IN ('3502')
                  GROUP BY rekvid,
                           tegev,
                           allikas,
                           artikkel,
                           rahavoog,
                           tunnus,
                           proj,
                           uritus,
                           objekt,
                           idx
                  UNION ALL
                  -- totals
-- Põhitegevuse tulud
                  SELECT rekvid,
                         sum(
                                 CASE WHEN allikas = '80' AND artikkel = '2585' THEN 0 ELSE eelarve_kinni END) AS eelarve_kinni,
                         sum(CASE
                                 WHEN allikas = '80' AND artikkel = '2585' THEN 0
                                 ELSE eelarve_parandatud END)                                                  AS eelarve_parandatud,
                         sum(CASE
                                 WHEN allikas = '80' AND artikkel = '2585' THEN 0
                                 ELSE eelarve_kassa_kinni END)                                                 AS eelarve_kassa_kinni,
                         SUM(CASE
                                 WHEN allikas = '80' AND artikkel = '2585' THEN 0
                                 ELSE eelarve_kassa_parandatud END)                                            AS eelarve_kassa_parandatud,
                         sum(CASE WHEN allikas = '80' AND artikkel = '2585' THEN 0 ELSE tegelik END)           AS tegelik,
                         sum(CASE WHEN allikas = '80' AND artikkel = '2585' THEN 0 ELSE kassa END)             AS kassa,
                         ''                                                                                    AS tegev,
                         ''                                                                                    AS allikas,
                         '1,2,3,6'                                                                             AS artikkel,
                         ''                                                                                    AS rahavoog,
                         ''                                                                                    AS tunnus,
                         ''                                                                                    AS proj,
                         ''                                                                                    AS uritus,
                         ''                                                                                    AS objekt,
                         150                                                                                   AS idx
                  FROM (SELECT rekvid,
                               eelarve_kinni,
                               eelarve_parandatud,
                               eelarve_kassa_parandatud,
                               eelarve_kassa_kinni,
                               tegelik,
                               kassa,
                               tegev,
                               allikas,
                               artikkel,
                               rahavoog,
                               tunnus,
                               proj,
                               uritus,
                               objekt
                        FROM qryReport
                        WHERE ltrim(rtrim(artikkel)) NOT IN ('3502')
                        UNION ALL
                        SELECT rekvid,
                               eelarve_kinni,
                               eelarve_parandatud,
                               eelarve_kassa_parandatud,
                               eelarve_kassa_kinni,
                               tegelik,
                               kassa,
                               tegev,
                               allikas,
                               artikkel,
                               rahavoog,
                               tunnus,
                               proj,
                               uritus,
                               objekt
                        FROM laekumised_eelarvesse
                        UNION ALL
                        SELECT rekvid,
                               eelarve_kinni,
                               eelarve_parandatud,
                               eelarve_kassa_parandatud,
                               eelarve_kassa_kinni,
                               tegelik,
                               kassa,
                               tegev,
                               allikas,
                               artikkel,
                               rahavoog,
                               tunnus,
                               proj,
                               uritus,
                               objekt
                        FROM qry3502
                       ) j
                  GROUP BY rekvid
                  UNION ALL
-- Art 2585 A80
                  SELECT rekvid,
                         sum(eelarve_kinni)            AS eelarve_kinni,
                         sum(eelarve_parandatud)       AS eelarve_parandatud,
                         sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                         SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                         sum(tegelik)                  AS tegelik,
                         sum(kassa)                    AS kassa,
                         ''                            AS tegev,
                         '80'                          AS allikas,
                         '2585(A80)'                   AS artikkel,
                         ''                            AS rahavoog,
                         ''                            AS tunnus,
                         ''                            AS proj,
                         ''                            AS uritus,
                         ''                            AS objekt,
                         100                           AS idx
                  FROM qryReport
                  WHERE ltrim(rtrim(artikkel)) = '2585'
                    AND ltrim(rtrim(allikas)) = '80'
                  GROUP BY rekvid
                  UNION ALL
                  -- убрать из конда доходы фин.департамента от поступлений доходов из учреждений
                  SELECT rekvid,
                         eelarve_kinni,
                         eelarve_parandatud,
                         eelarve_kassa_kinni,
                         eelarve_kassa_parandatud,
                         tegelik,
                         kassa,
                         tegev,
                         allikas,
                         artikkel,
                         rahavoog,
                         tunnus,
                         proj,
                         uritus,
                         objekt,
                         idx
                  FROM laekumised_eelarvesse
                  UNION ALL
                  SELECT rekvid,
                         eelarve_kinni,
                         eelarve_parandatud,
                         eelarve_kassa_kinni,
                         eelarve_kassa_parandatud,
                         tegelik,
                         kassa,
                         tegev,
                         allikas,
                         artikkel,
                         rahavoog,
                         tunnus,
                         proj,
                         uritus,
                         objekt,
                         idx
                  FROM qry3502
              ) qry
     )
-- pohi osa
SELECT *
FROM qryPreReport
UNION ALL
-- kond
SELECT 999999                        AS rekv_id,
       sum(eelarve_kinni)            AS eelarve_kinni,
       sum(eelarve_parandatud)       AS eelarve_parandatud,
       sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
       SUM(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
       sum(tegelik)                  AS tegelik,
       sum(kassa)                    AS kassa,
       tegev,
       allikas,
       artikkel,
       rahavoog,
       tunnus,
       proj,
       uritus,
       objekt,
       idx
FROM qryPreReport
WHERE l_kond > 0
  AND (
        eelarve_kinni <> 0
        OR eelarve_parandatud <> 0
        OR eelarve_kassa_kinni <> 0
        OR eelarve_kassa_parandatud <> 0
        OR tegelik <> 0
        OR kassa <> 0
    )
GROUP BY tegev,
         allikas,
         artikkel,
         rahavoog,
         tunnus,
         proj,
         uritus,
         objekt,
         idx;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO dbvaatleja;

/*

SELECT *
FROM (
         SELECT sum(tegelik) over(), sum(kassa) over(), sum(eelarve_kinni) over(), sum(eelarve_parandatud) over(), sum(eelarve_kassa_kinni) over(), sum(eelarve_kassa_parandatud) over(), *
         FROM eelarve.tulude_taitmine_a_art_tt_tunnus_proj_uritus(2024::INTEGER, '2024-01-01'::DATE, '2024-12-30', 28, 1,'{"tunnus":null}')
where artikkel = '3818'

allikas = '80'
and artikkel = '3044'
     ) qry
WHERE left(artikkel, 3) IN ('655')
--and tegev = '04730'
  AND allikas = '80'
ORDER BY idx, artikkel, allikas, tegev, rahavoog, tunnus
--and tunnus = '5004'
-- 65448720

 */