DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_jaak(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER);
DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_jaak(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER, JSONB);

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine_jaak(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER,
                                                          l_params JSONB DEFAULT NULL)
    RETURNS TABLE (
        rekv_id        INTEGER,
        tegev          VARCHAR(20),
        allikas        VARCHAR(20),
        artikkel       VARCHAR(20),
        tunnus         VARCHAR(20),
        proj           VARCHAR(20),
        uritus         VARCHAR(20),
        eelarve        NUMERIC(14, 2),
        eelarve_kassa  NUMERIC(14, 2),
        taitmine       NUMERIC(14, 2),
        taitmine_kassa NUMERIC(14, 2)

    )
AS
$BODY$
WITH params AS (
    SELECT l_rekvid                                            AS rekvid,
           l_kpv                                               AS kpv,
           l_kond                                              AS kond,
           make_date(year(l_kpv), 01, 01)                      AS kpv1,
           l_kpv                                               AS kpv2,
           coalesce((l_params ->> 'tunnus')::TEXT, '') + '%'   AS tunnus,
           coalesce((l_params ->> 'tegev')::TEXT, '') + '%'    AS tegev,
           coalesce((l_params ->> 'artikkel')::TEXT, '') + '%' AS artikkel,
           coalesce((l_params ->> 'allikas')::TEXT, '') + '%'  AS allikas,
           coalesce((l_params ->> 'rahavoog')::TEXT, '') + '%' AS rahavoog,
           coalesce((l_params ->> 'proj')::TEXT, '') + '%'     AS proj,
           coalesce((l_params ->> 'uritus')::TEXT, '') + '%'   AS uritus
),
     rekv_ids AS (
         SELECT rekv_id
         FROM params,
              get_asutuse_struktuur(params.rekvid) a
         WHERE a.rekv_id = CASE
                               WHEN params.kond = 1
                                   -- kond
                                   THEN a.rekv_id
                               ELSE params.rekvid END
     ),
     docs_types AS (
         SELECT id, kood FROM libs.library WHERE library.library = 'DOK' AND kood IN ('JOURNAL')
     ),

     qryTunnused AS (SELECT DISTINCT t.rekvid, t1.tunnus
                     FROM eelarve.taotlus t
                              INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                          params
                     WHERE t1.tunnus IS NOT NULL
                       AND NOT empty(t1.tunnus)
                       AND t.status IN (3)
                       AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                       AND t.aasta = YEAR(params.kpv)
     ),
     qryProj AS (SELECT DISTINCT t.rekvid, t1.proj
                 FROM eelarve.taotlus t
                          INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                      params
                 WHERE t1.proj IS NOT NULL
                   AND NOT empty(t1.proj)
                   AND t.status IN (3)
                   AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                   AND t.aasta = YEAR(params.kpv)
     ),

     qryUritus AS (SELECT DISTINCT t.rekvid, t1.kood4 AS uritus
                   FROM eelarve.taotlus t
                            INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid,
                        params
                   WHERE t1.kood4 IS NOT NULL
                     AND NOT empty(t1.kood4)
                     AND t.status IN (3)
                     AND t.rekvid IN (SELECT r.rekv_id FROM rekv_ids r)
                     AND t.aasta = YEAR(params.kpv)
     ),

     qry_eelarve AS (
         -- бюджет
         SELECT e.rekv_id            AS rekv_id,
                sum(e.eelarve)       AS eelarve,
                sum(e.eelarve_kassa) AS eelarve_kassa,
                e.tegev              AS tegev,
                e.allikas            AS allikas,
                e.artikkel           AS artikkel,
                e.tunnus             AS tunnus,
                e.proj,
                e.uritus
         FROM (SELECT e.rekvid        AS rekv_id,
                      e.summa         AS eelarve,
                      e.summa_kassa   AS eelarve_kassa,
                      e.kood1         AS tegev,
                      e.kood2         AS allikas,
                      e.kood5         AS artikkel,
                      CASE
                          WHEN EXISTS(
                                  SELECT 1 FROM qryTunnused t WHERE t.tunnus = e.tunnus AND t.rekvid = e.rekvid)
                              THEN e.tunnus
                          ELSE '' END AS tunnus,
                      CASE
                          WHEN EXISTS(
                                  SELECT 1 FROM qryProj p WHERE p.proj = t1.proj AND p.rekvid = e.rekvid)
                              THEN t1.proj
                          ELSE '' END AS proj,
                      CASE
                          WHEN EXISTS(
                                  SELECT 1 FROM qryUritus u WHERE u.uritus = t1.kood4 AND u.rekvid = e.rekvid)
                              THEN t1.kood4
                          ELSE '' END AS uritus
               FROM eelarve.eelarve e
                        INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id,
                    params p
               WHERE e.aasta = year(p.kpv)
                 AND (e.kpv IS NULL OR e.kpv <= p.kpv)
                 AND (NOT empty(e.is_kulud::INTEGER)
                   OR (e.kood5 IN ('2585', '2586') AND e.kood2 <> '80'
                          ))
                 AND e.rekvid IN (SELECT rekv_id FROM rekv_ids)
                 AND e.status <> 3) e
         GROUP BY e.rekv_id
                 , e.tegev
                 , e.allikas
                 , e.artikkel
                 , e.tunnus
                 , e.proj
                 , e.uritus
     ),
     qry_kulude_kassa_taitmine AS (
         -- kontod
         WITH qryKontodKulud AS (
             SELECT l.kood, l.tun5 AS tyyp
             FROM libs.library l
                      INNER JOIN eelarve.kassa_kulud kassakulud
                                 ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kassakulud.kood) :: TEXT))))
             WHERE l.library = 'KONTOD'
               AND L.status <> 3
         ),
              qryKassaKontod AS (
                  SELECT l.kood, l.tun5 AS tyyp
                  FROM libs.library l
                           INNER JOIN
                       eelarve.kassa_kontod kassakontod
                       ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((kassakontod.kood) :: TEXT))))
                  WHERE l.library = 'KONTOD'
                    AND L.status <> 3
              )
         SELECT qry.rekvid     AS rekv_id,
                sum(qry.summa) AS summa,
                qry.tegev,
                qry.allikas,
                qry.artikkel,
                qry.rahavoog,
                qry.tunnus,
                qry.proj,
                qry.uritus
         FROM (
                  -- расход
                  SELECT (summa)        AS summa,
                         j1.kood1::TEXT AS tegev,
                         j1.kood2::TEXT AS allikas,
                         j1.kood3::TEXT AS rahavoog,
                         j1.kood5::TEXT AS artikkel,
                         j1.tunnus::TEXT,
                         j1.proj::TEXT  AS proj,
                         j1.kood4       AS uritus,
                         j.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = D.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN qryKontodKulud k ON k.kood = j1.deebet
                           INNER JOIN qryKassaKontod kassa ON kassa.kood = j1.kreedit
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                       params
                  WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
                    AND coalesce(a.kpv, j.kpv) <= params.kpv2
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)

                  UNION ALL
                  -- востановление расходов
                  SELECT  (-1 * j1.summa) AS summa,
                                  j1.kood1::TEXT  AS tegev,
                                  j1.kood2::TEXT  AS allikas,
                                  j1.kood3::TEXT  AS rahavoog,
                                  j1.kood5::TEXT  AS artikkel,
                                  j1.tunnus::TEXT,
                                  j1.proj::TEXT   AS proj,
                                  j1.kood4        AS uritus,
                                  j.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN qryKontodKulud k ON k.kood = j1.kreedit
                           INNER JOIN qryKassaKontod kassa ON kassa.kood = j1.deebet
                           INNER JOIN libs.library l
                                      ON l.kood = j1.kood5 AND l.tun5 = 2 AND library = 'TULUDEALLIKAD' --kulud
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                       params

                  WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
                    AND coalesce(a.kpv, j.kpv) <= params.kpv2
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
              ) qry,
              params
         WHERE NOT empty(qry.artikkel)
           AND summa <> 0
           AND CASE WHEN qry.artikkel IN ('2585', '2586') AND qry.allikas = '80' THEN FALSE ELSE TRUE END
           AND qry.artikkel IN (SELECT kood
                                FROM com_artikkel
                                WHERE is_kulud)
           -- lisa filtrid
           AND coalesce(qry.tunnus, '') ILIKE params.tunnus
           AND coalesce(qry.tegev, '') ILIKE params.tegev
           AND coalesce(qry.artikkel, '') ILIKE params.artikkel
           AND coalesce(qry.allikas, '') ILIKE params.allikas
           AND coalesce(qry.rahavoog, '') ILIKE params.rahavoog
           AND coalesce(qry.proj, '') ILIKE params.proj
           AND coalesce(qry.uritus, '') ILIKE params.uritus
         GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.rahavoog, qry.proj, qry.uritus
         HAVING sum(qry.summa) <> 0

/*         -- кассовое исполнение расходы
         SELECT *
         FROM eelarve.uus_kassa_taitmine(make_date(YEAR(l_kpv)
                                             , 01
                                             , 01)
                  , l_kpv
                  , l_rekvid
                  , l_kond) e
         WHERE CASE WHEN artikkel IN ('2585', '2586') AND allikas = '80' THEN FALSE ELSE TRUE END
           AND artikkel IN (SELECT kood
                            FROM com_artikkel
                            WHERE is_kulud)
*/ ),
     -- tekke taotmine расходы
     qry_kulude_taitmine AS (
         WITH qryKontodKassaKulud AS (
             SELECT l.kood, l.tun5
             FROM libs.library l
                      INNER JOIN
                  eelarve.fakt_kulud fakt_kulud
                  ON ((ltrim(rtrim((l.kood) :: TEXT)) ~~ ltrim(rtrim((fakt_kulud.kood) :: TEXT))))
             WHERE l.library = 'KONTOD'
               AND L.status <> 3
         ),
              qryArt AS (SELECT kood
                         FROM libs.library l
                         WHERE l.tun5 = 2 --kulud
                           AND l.library = 'TULUDEALLIKAD'
                           AND status < 3)
         SELECT qry.rekvid     AS rekv_id,
                sum(qry.summa) AS summa,
                qry.tegev,
                qry.allikas,
                qry.artikkel,
                qry.rahavoog,
                qry.tunnus,
                qry.proj,
                qry.uritus
         FROM (
                  -- расходы
                  SELECT 1                          AS kulud,
                         sum(CASE
                                 WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01')
                                     THEN 0
                                 ELSE j1.summa END) AS summa,
                         j1.kood1                   AS tegev,
                         j1.kood2                   AS allikas,
                         j1.kood3                   AS rahavoog,
                         j1.kood5                   AS artikkel,
                         j1.tunnus,
                         j1.proj::TEXT              AS proj,
                         j1.kood4                   AS uritus,
                         j.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN qryKontodKassaKulud k ON k.kood = j1.deebet
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                       params

                  WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
                    AND coalesce(a.kpv, j.kpv) <= params.kpv2
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status < 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND j1.kood5 IN (SELECT kood FROM qryArt)
                    AND NOT empty(j1.kood5)
                  GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood4, j1.kood5, j1.tunnus, j1.proj, j.rekvid
                  UNION ALL
                  -- востановление расходов
                  SELECT 2                                 AS tulud,
                         sum(-1 * (CASE
                                       WHEN left(j1.kood5, 2) = '15' AND NOT empty(j1.kood3) AND j1.kood3 NOT IN ('01')
                                           THEN 0
                                       ELSE j1.summa END)) AS summa,
                         j1.kood1                          AS tegev,
                         j1.kood2                          AS allikas,
                         j1.kood3                          AS rahavoog,
                         j1.kood5                          AS artikkel,
                         j1.tunnus,
                         j1.proj::TEXT                     AS proj,
                         j1.kood4                          AS uritus,
                         j.rekvid
                  FROM docs.doc d
                           INNER JOIN docs.journal j ON j.parentid = d.id
                           INNER JOIN docs.journal1 j1 ON j1.parentid = j.id
                           INNER JOIN qryKontodKassaKulud k ON k.kood = j1.kreedit
                      -- если есть в таблице нач. сальдо, то используем дату из ьаблицы сальдо
                           LEFT OUTER JOIN docs.alg_saldo a ON a.journal_id = d.id,
                       params
                  WHERE coalesce(a.kpv, j.kpv) >= params.kpv1
                    AND coalesce(a.kpv, j.kpv) <= params.kpv2
                    AND d.rekvid IN (SELECT rekv_id FROM rekv_ids)
                    AND d.status < 3
                    AND d.doc_type_id IN (SELECT id FROM docs_types)
                    AND j1.kood5 IN (SELECT kood FROM qryArt)
                    AND NOT empty(j1.kood5)
                  GROUP BY j1.kood1, j1.kood2, j1.kood3, j1.kood4, j1.kood5, j1.tunnus, j1.proj, j.rekvid
              ) qry,
              params
         WHERE NOT empty(qry.artikkel)
           AND qry.summa <> 0
           AND CASE WHEN qry.artikkel IN ('2585', '2586') AND qry.allikas = '80' THEN FALSE ELSE TRUE END
           AND qry.artikkel IN (SELECT kood
                                FROM com_artikkel
                                WHERE is_kulud)
           AND coalesce(qry.tunnus, '') ILIKE params.tunnus
           AND coalesce(qry.tegev, '') ILIKE params.tegev
           AND coalesce(qry.artikkel, '') ILIKE params.artikkel
           AND coalesce(qry.allikas, '') ILIKE params.allikas
           AND coalesce(qry.rahavoog, '') ILIKE params.rahavoog
           AND coalesce(qry.proj, '') ILIKE params.proj
           AND coalesce(qry.uritus, '') ILIKE params.uritus
         GROUP BY qry.rekvid, qry.tegev, qry.allikas, qry.artikkel, qry.tunnus, qry.rahavoog, qry.proj, qry.uritus

         /*SELECT *
                             FROM eelarve.tekke_taitmine(make_date(YEAR(l_kpv)
                                                             , 01
                                                             , 01)
                                      , l_kpv
                                      , l_rekvid
                                      , l_kond)
                             WHERE CASE WHEN artikkel IN ('2585', '2586') AND allikas = '80' THEN FALSE ELSE TRUE END
                               AND artikkel IN (SELECT kood
                                                FROM com_artikkel
                                                WHERE is_kulud)*/
     )
        ,
     pre_report AS (
         SELECT rekv_id,
                tegev,
                allikas,
                artikkel,
                tunnus,
                proj,
                uritus,
                sum(eelarve)::NUMERIC(14, 2)        AS eelarve,
                sum(eelarve_kassa)::NUMERIC(14, 2)  AS eelarve_kassa,
                sum(taitmine)::NUMERIC(14, 2)       AS taitmine,
                sum(taitmine_kassa)::NUMERIC(14, 2) AS taitmine_kassa
         FROM (
                  SELECT rekv_id,
                         tegev,
                         allikas,
                         artikkel,
                         tunnus,
                         proj,
                         uritus,
                         eelarve,
                         eelarve_kassa,
                         0::NUMERIC(14, 2) AS taitmine,
                         0::NUMERIC(14, 2) AS taitmine_kassa
                  FROM qry_eelarve
                  UNION ALL
                  SELECT t.rekv_id,
                         t.tegev,
                         t.allikas,
                         t.artikkel,
                         t.tunnus,
                         t.proj,
                         t.uritus,
                         0::NUMERIC(14, 2) AS eelarve,
                         0::NUMERIC(14, 2) AS eelarve_kassa,
                         0::NUMERIC(14, 2) AS taitmine,
                         t.summa           AS taitmine_kassa
                  FROM qry_kulude_kassa_taitmine t
                  UNION ALL
                  SELECT t.rekv_id,
                         t.tegev,
                         t.allikas,
                         t.artikkel,
                         t.tunnus,
                         t.proj,
                         t.uritus,
                         0::NUMERIC(14, 2)       AS eelarve,
                         0::NUMERIC(14, 2)       AS eelarve_kassa,
                         t.summa::NUMERIC(14, 2) AS taitmine,
                         0::NUMERIC(14, 2)       AS taitmine_kassa
                  FROM qry_kulude_taitmine t
              ) qry
         GROUP BY rekv_id,
                  tegev,
                  allikas,
                  artikkel,
                  tunnus,
                  proj,
                  uritus
     )
SELECT *
FROM pre_report
UNION ALL
-- kond
SELECT 999999,
       tegev,
       allikas,
       artikkel,
       tunnus,
       ''                                  AS proj,
       ''                                  AS uritus,
       sum(eelarve)::NUMERIC(14, 2)        AS eelarve,
       sum(eelarve_kassa)::NUMERIC(14, 2)  AS eelarve_kassa,
       sum(taitmine)::NUMERIC(14, 2)       AS taitmine,
       sum(taitmine_kassa)::NUMERIC(14, 2) AS taitmine_kassa
FROM pre_report
WHERE l_kond > 0
GROUP BY tegev,
         allikas,
         artikkel,
         tunnus

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

/*
select sum(eelarve) over() as eelarve_kokku,
sum(eelarve_kassa) over() as eelarve_kassa_kokku,
sum(taitmine) over() as taitmine_kokku,
sum(taitmine_kassa) over() as taitmine_kassa_kokku,
*
from eelarve.eelarve_taitmine_jaak('2023-07-31', 125, 1)
where rekv_id < 999
and artikkel in (select kood from com_artikkel)
and artikkel = '5511'

eelarve_kokku;eelarve_kassa_kokku;taitmine_kokku;taitmine_kassa_kokku
177563172;170506730;52687539.89;56723908.68
                                56775703.48
103391275.27

eelarve_kokku;eelarve_kassa_kokku;taitmine_kokku;taitmine_kassa_kokku
355126344;341013460;105375079.78;113445275.32

--  6024 rows retrieved starting from 1 in 25 s 941 ms (execution: 25 s 543 ms, fetching: 398 ms)


select sum(eelarve) over() as eelarve_kokku,
sum(eelarve_kassa) over() as eelarve_kassa_kokku,
sum(taitmine) over() as taitmine_kokku,
sum(taitmine_kassa) over() as taitmine_kassa_kokku,
*
from eelarve.eelarve_taitmine_jaak('2023-06-30', 63, 1)
where rekv_id < 999
and artikkel in (select kood from com_artikkel)

eelarve_kokku;eelarve_kassa_kokku;taitmine_kokku;taitmine_kassa_kokku
177563172;170506730;52687539.89;56722637.66
                                56775703.48


*/