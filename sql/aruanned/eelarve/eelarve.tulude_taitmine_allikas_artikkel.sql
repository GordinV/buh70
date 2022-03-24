DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, BOOLEAN, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, DATE, INTEGER, INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.tulude_taitmine_allikas_artikkel(l_aasta INTEGER,
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
        idx                      INTEGER

    )
AS
$BODY$
WITH cur_tulude_kassa_taitmine AS (
    SELECT *
    FROM eelarve.uus_kassa_tulu_taitmine(l_kpv_1, l_kpv_2, l_rekvid, l_kond) qry
    WHERE artikkel <> '3501' -- Убери, пожалуйста во всех отчетах Tulude eelarve täitmine ХХХХХ строку 3501 - это не доходы от деятельности, а внутренние переводы
      AND (l_params IS NULL OR coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
      AND (l_params IS NULL OR coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
      AND (l_params IS NULL OR coalesce(qry.artikkel, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
      AND (l_params IS NULL OR coalesce(qry.allikas, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
      AND (l_params IS NULL OR coalesce(qry.rahavoog, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
),
     cur_tulude_taitmine AS (
         SELECT *
         FROM eelarve.tulu_taitmine(l_kpv_1, l_kpv_2, l_rekvid, l_kond) qry
         WHERE artikkel <> '3501'
           AND (l_params IS NULL OR coalesce(qry.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.tegev, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.artikkel, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
           AND (l_params IS NULL OR coalesce(qry.allikas, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
           AND (l_params IS NULL OR
                coalesce(qry.rahavoog, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
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
                      d.rekvid,
                      d.id,
                      j.kpv,
                      j1.kreedit
               FROM docs.doc D
                        INNER JOIN docs.journal j ON j.parentid = D.id
                        INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
               WHERE j.kpv >= make_date(year(l_kpv_2), 1, 1)
                 AND j.kpv <= l_kpv_2
                 AND left(j1.deebet, 6) IN ('100100', '999999') -- поступление доходов
                 AND left(j1.kreedit, 6) = '700001'
                 AND d.rekvid = 63                              -- только фин. департамент
                 --строка art 1532 в доходах может быть только с rahavoog 02, соответственно с rahavoog 23  быть не далжно
                 AND (CASE WHEN j1.kood5 = '1532' AND j1.kood3 IN ('23', '21') THEN FALSE ELSE TRUE END)
                 AND d.status <> 3
                 AND j1.kood5 <> '3501'
                 AND (l_params IS NULL OR
                      coalesce(j1.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                 AND (l_params IS NULL OR coalesce(j1.kood1, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood5, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood2, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                 AND (l_params IS NULL OR
                      coalesce(j1.kood3, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')
              ) j
                  INNER JOIN libs.library l ON l.kood = j.kood5
             AND l.tun5 = 1 --tulud
             AND l.status <> 3
             AND l.library = 'TULUDEALLIKAD'
         WHERE l_kond > 0
           AND l_rekvid = 63 -- только если отчет для фин.департамента
         GROUP BY j.rekvid, j.kood1, j.kood2, j.kood3, j.kood5, j.tunnus
     ),
     qryReport AS (
         SELECT rekvid,
                sum(eelarve_kinni)            AS eelarve_kinni,
                sum(eelarve_parandatud)       AS eelarve_parandatud,
                sum(eelarve_kassa_kinni)      AS eelarve_kassa_kinni,
                sum(eelarve_kassa_parandatud) AS eelarve_kassa_parandatud,
                sum(tegelik)                  AS tegelik,
                sum(kassa)                    AS kassa,
                tegev,
                allikas,
                artikkel,
                rahavoog,
                tunnus,
                idx
         FROM (
                  SELECT rekvid,
                         summa               AS eelarve_kinni,
                         summa_kassa         AS eelarve_kassa_kinni,
                         0:: NUMERIC         AS eelarve_parandatud,
                         0:: NUMERIC         AS eelarve_kassa_parandatud,
                         0 :: NUMERIC        AS tegelik,
                         0 :: NUMERIC        AS kassa,
                         coalesce(kood1, '') AS tegev,
                         coalesce(kood2, '') AS allikas,
                         coalesce(kood5, '') AS artikkel,
                         coalesce(kood3, '') AS rahavoog,
                         COALESCE(tunnus,
                                  '')        AS tunnus,
                         CASE
                             WHEN ltrim(rtrim(kood5)) = '2585' AND ltrim(rtrim(kood2)) = '80' THEN 120
                             ELSE 200 END    AS idx
                  FROM eelarve.tulud e
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (SELECT rekv_id
                                     FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND e.kpv IS NULL
                    AND e.status <> 3
                    AND (l_params IS NULL OR
                         coalesce(e.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood1, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood5, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood2, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood3, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')

                  UNION ALL
                  SELECT rekvid,
                         0 :: NUMERIC                                                    AS eelarve_kinni,
                         0 :: NUMERIC                                                    AS eelarve_kassa_kinni,
                         summa                                                           AS eelarve_parandatud,
                         summa_kassa                                                     AS eelarve_kassa_parandatud,
                         0 :: NUMERIC                                                    AS tegelik,
                         0 :: NUMERIC                                                    AS kassa,
                         coalesce(kood1, '')                                             AS tegev,
                         coalesce(kood2, '')                                             AS allikas,
                         coalesce(kood5, '')                                             AS artikkel,
                         coalesce(kood3, '')                                             AS rahavoog,
                         COALESCE(tunnus,
                                  '')                                                    AS tunnus,
                         CASE WHEN kood5 = '2585' AND kood2 = '80' THEN 120 ELSE 200 END AS idx
                  FROM eelarve.tulud e
                  WHERE rekvid = (CASE
                                      WHEN l_kond = 1
                                          THEN rekvid
                                      ELSE l_rekvid END
                      )
                    AND e.rekvid IN (SELECT rekv_id FROM get_asutuse_struktuur(l_rekvid))
                    AND aasta = l_aasta
                    AND (e.kpv IS NULL OR e.kpv <= COALESCE(l_kpv_2, CURRENT_DATE))
                    AND e.status <> 3
                    AND (l_params IS NULL OR
                         coalesce(e.tunnus, '') ILIKE coalesce((l_params ->> 'tunnus')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood1, '') ILIKE coalesce((l_params ->> 'tegev')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood5, '') ILIKE coalesce((l_params ->> 'artikkel')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood2, '') ILIKE coalesce((l_params ->> 'allikas')::TEXT, '') + '%')
                    AND (l_params IS NULL OR
                         coalesce(e.kood3, '') ILIKE coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%')

                  UNION ALL
                  SELECT rekv_id          AS rekvid,
                         0 :: NUMERIC     AS eelarve_kinni,
                         0 :: NUMERIC     AS eelarve_parandatud,
                         0 :: NUMERIC     AS eelarve_kassa_kinni,
                         0 :: NUMERIC     AS eelarve_kassa_parandatud,
                         summa            AS tegelik,
                         0 :: NUMERIC     AS kassa,
                         COALESCE(tegev,
                                  '')     AS tegev,
                         COALESCE(allikas,
                                  '')     AS allikas,
                         COALESCE(artikkel,
                                  '')     AS artikkel,
                         COALESCE(rahavoog,
                                  '')     AS rahavoog,
                         COALESCE(tunnus,
                                  '')     AS tunnus,
                         CASE
                             WHEN COALESCE(artikkel, '') = '2585' AND COALESCE(allikas, '') = '80' THEN 120
                             ELSE 200 END AS idx
                  FROM cur_tulude_taitmine ft
                  WHERE ft.artikkel IS NOT NULL
                    AND NOT empty(ft.artikkel)

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
                         CASE WHEN artikkel = '2585' AND allikas = '80' THEN 120 ELSE 200 END AS idx
                  FROM cur_tulude_kassa_taitmine kt
                  WHERE kt.artikkel IS NOT NULL
                    AND NOT empty(kt.artikkel)
              ) qry
         GROUP BY rekvid,
                  tegev,
                  allikas,
                  artikkel,
                  rahavoog,
                  tunnus,
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
                         idx
                  FROM qryReport
                  WHERE ltrim(rtrim(artikkel)) NOT IN ('3502')
                  GROUP BY rekvid,
                           tegev,
                           allikas,
                           artikkel,
                           rahavoog,
                           tunnus,
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
                               tunnus
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
                               tunnus
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
                               tunnus
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
         idx;


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO eelaktsepterja;
GRANT EXECUTE ON FUNCTION eelarve.tulude_taitmine_allikas_artikkel(INTEGER, DATE, DATE,INTEGER, INTEGER, JSONB) TO dbvaatleja;

/*
SELECT *
FROM (
         SELECT *
         FROM eelarve.tulude_taitmine_allikas_artikkel_(2021::INTEGER, '2022-01-01'::DATE, '2022-03-31', 29, 1,'{"tunnus":null}')
     ) qry
WHERE left(artikkel, 3) IN ('655')
--and tegev = '04730'
  AND allikas = '80'
ORDER BY idx, artikkel, allikas, tegev, rahavoog, tunnus
--and tunnus = '5004'
-- 65448720

 */