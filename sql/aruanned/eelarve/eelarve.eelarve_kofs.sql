DROP FUNCTION IF EXISTS eelarve.eelarve_kofs(DATE, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.eelarve_kofs(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
  RETURNS TABLE(
    kood VARCHAR(20),
    nimetus VARCHAR(254),
    eelarve NUMERIC(14, 2),
    taitmine NUMERIC(14, 2),
    eelnou_kinni NUMERIC(14, 2),
    eelnou_koostatud NUMERIC(14, 2)
    ) AS
$BODY$

WITH query AS (
  WITH prev_qry AS (
    SELECT
      e.rekvid,
      e.kood5    AS kood,
      e.summa    AS eelarve,
      0::NUMERIC AS taitmine,
      0::NUMERIC AS eelnou_kinni,
      0::NUMERIC AS eelnou_koostatud
    FROM eelarve.eelarve e
    WHERE e.rekvid = (CASE
                        WHEN l_kond = 1
                          THEN e.rekvid
                        ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND (e.kuu <= month(l_kpv) OR e.kuu = 0)
      AND e.aasta = year(l_kpv)
      AND e.status <> 3

    UNION ALL
      -- taitmine (kulud)
    SELECT
      e.rekvid,
      e.artikkel AS kood,
      0::NUMERIC AS eelarve,
      e.summa    AS taitmine,
      0::NUMERIC AS eelnou_kinni,
      0::NUMERIC AS eelnou_koostatud
    FROM cur_kulude_kassa_taitmine e
    WHERE e.rekvid = (CASE
                        WHEN l_kond = 1
                          THEN e.rekvid
                        ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND e.kuu <= month(l_kpv)
      AND e.aasta = year(l_kpv)
    UNION ALL
      -- taitmine (kulud)
    SELECT
      e.rekvid,
      e.artikkel AS kood,
      0::NUMERIC AS eelarve,
      e.summa    AS taitmine,
      0::NUMERIC AS eelnou_kinni,
      0::NUMERIC AS eelnou_koostatud
    FROM cur_tulude_kassa_taitmine e
    WHERE e.rekvid = (CASE
                        WHEN l_kond = 1
                          THEN e.rekvid
                        ELSE l_rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND e.kuu <= month(l_kpv)
      AND e.aasta = year(l_kpv)
    UNION ALL
      --eelnou kinni
    SELECT
      d.rekvid,
      t1.kood5          AS kood,
      0::NUMERIC        AS eelarve,
      0::NUMERIC        AS taitmine,
      t1.summa::NUMERIC AS eelnou_kinni,
      0::NUMERIC        AS eelnou_koostatud

    FROM docs.doc d
           INNER JOIN eelarve.taotlus t ON t.parentid = d.id
           INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.aasta = year(l_kpv)
      AND d.status <> 3
      AND t.kpv <= l_kpv
      AND t.status = 3 -- kinnitatud
    UNION ALL
      -- eelnou koostatud
    SELECT
      d.rekvid,
      t1.kood5          AS kood,
      0::NUMERIC        AS eelarve,
      0::NUMERIC        AS taitmine,
      t1.summa::NUMERIC AS eelnou_kinni,
      0::NUMERIC        AS eelnou_koostatud

    FROM docs.doc d
           INNER JOIN eelarve.taotlus t ON t.parentid = d.id
           INNER JOIN eelarve.taotlus1 t1 ON t.id = t1.parentid
    WHERE t.aasta = year(l_kpv)
      AND d.status <> 3
      AND t.kpv <= l_kpv
      AND t.status = 1 -- koostatud

    )
    --30
    SELECT 1                                        AS idx,
           '30'::VARCHAR(20)                        AS kood,
           'Maksutulud'::VARCHAR(254)               AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2)            AS eelarve,
           sum(e.taitmine)::NUMERIC(14,2)           AS taitmine,
           sum(e.eelnou_kinni)::NUMERIC(14,2)       AS eelnou_kinni,
           sum(e.eelnou_koostatud):: NUMERIC(14, 2) AS eelnou_koostatud
    FROM prev_qry e
    WHERE e.kood LIKE '30%'
    UNION ALL
    SELECT 1                                                 AS idx,
           '32'::VARCHAR(20)                                 AS kood,
           'Tulud kaupade ja teenuste müügist'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '32%'
    UNION ALL
    SELECT 1                                                 AS idx,
           '3500, 352'::VARCHAR(20)                          AS kood,
           'Saadavad toetused tegevuskuludeks'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE (e.kood IN ('352.00.17.1', '352.00.17.2')
      OR e.kood LIKE '3500%'
      OR (e.kood LIKE '352%' AND e.kood NOT LIKE '352.0%'))
    UNION ALL
    SELECT 1                                   AS idx,
           '352.00.17.1'::VARCHAR(20)          AS kood,
           'Tasandusfond (lg 1)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood = '352.00.17.1'
    UNION ALL
    SELECT 1                                   AS idx,
           '352.00.17.2'::VARCHAR(20)          AS kood,
           'Tasandusfond (lg 2)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood = '352.00.17.2'
    UNION ALL
    SELECT 1                                                              AS idx,
           '3880,3888'::VARCHAR(20)                                       AS kood,
           ' Sh muud eelpool nimetamata muud tegevustulud '::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood IN ('3880', '3888')
    UNION ALL
    SELECT 1                                                                      AS idx,
           '3882'::VARCHAR(20)                                                    AS kood,
           ' Sh saastetasud ja keskkonnale tekitatud kahju hüvitis'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood = '3882'
    UNION ALL
    SELECT 1                                 AS idx,
           '38'::VARCHAR(20)                 AS kood,
           'Muud tegevustulud'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '38%'
    UNION ALL
    SELECT 1                                        AS idx,
           ''::VARCHAR(20)                          AS kood,
           'PÕHITEGEVUSE TULUD KOKKU'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE left(e.kood, 2) IN ('30', '32', '35', '38')
    UNION ALL
      -- kulud
    SELECT 2                                                                 AS idx,
           '40'::VARCHAR(20)                                                 AS kood,
           'Subsiidiumid ettevõtlusega tegelevatele isikutele'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '40%'
    UNION ALL
    SELECT 2                                                                           AS idx,
           '413'::VARCHAR(20)                                                          AS kood,
           'Sotsiaalabitoetused ja muud toetused füüsilistele isikutele'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '413%'
    UNION ALL
    SELECT 2                                                          AS idx,
           '4500'::VARCHAR(20)                                        AS kood,
           'Sihtotstarbelised toetused tegevuskuludeks'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '4500%'
    UNION ALL
    SELECT 2                                               AS idx,
           '452'::VARCHAR(20)                              AS kood,
           'Mittesihtotstarbelised toetused'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '452%'
    UNION ALL
    SELECT 2                                                AS idx,
           '4'::VARCHAR(20)                                 AS kood,
           'Antavad toetused tegevuskuludeks'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '4%'
    UNION ALL
    SELECT 2                              AS idx,
           '50'::VARCHAR(20)              AS kood,
           'Personalikulud'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '50%'
    UNION ALL
    SELECT 2                               AS idx,
           '55'::VARCHAR(20)               AS kood,
           'Majandamiskulud'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '55%'
    UNION ALL
    SELECT 2                          AS idx,
           '60'::VARCHAR(20)          AS kood,
           'Muud kulud'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '60%'
    UNION ALL
    SELECT 2                                 AS idx,
           '5'::VARCHAR(20)                  AS kood,
           'Muud tegevuskulud'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE left(e.kood, 2) IN ('50', '55', '60')
    UNION ALL
    SELECT 2                                        AS idx,
           ''::VARCHAR(20)                          AS kood,
           'PÕHITEGEVUSE KULUD KOKKU'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE left(e.kood, 1) IN ('4', '5')
    UNION ALL
    SELECT 4                                 AS idx,
           ''::VARCHAR(20)                   AS kood,
           'Põhivara müük (+)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '381%'
    UNION ALL
    SELECT 4                                                                AS idx,
           ''::VARCHAR(20)                                                  AS kood,
           'Põhivara soetuseks saadav sihtfinantseerimine(+)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '3502%'
    UNION ALL
    SELECT 4                                                               AS idx,
           ''::VARCHAR(20)                                                 AS kood,
           'Põhivara soetuseks antav sihtfinantseerimine(-)'::VARCHAR(254) AS nimetus,
           sum(-1 * e.eelarve)::NUMERIC(14,2),
           sum(-1 * e.taitmine)::NUMERIC(14,2),
           sum(-1 * e.eelnou_kinni)::NUMERIC(14,2),
           sum(-1 * e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '4502%'
    UNION ALL
    SELECT 4                                   AS idx,
           ''::VARCHAR(20)                     AS kood,
           'Põhivara soetus (-)'::VARCHAR(254) AS nimetus,
           sum(-1 * e.eelarve)::NUMERIC(14,2),
           sum(-1 * e.taitmine)::NUMERIC(14,2),
           sum(-1 * e.eelnou_kinni)::NUMERIC(14,2),
           sum(-1 * e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '15%'
    UNION ALL
    SELECT 4                                 AS idx,
           ''::VARCHAR(20)                   AS kood,
           'Osaluste müük (+)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '101.2.1%'
    UNION ALL
    SELECT 4                                   AS idx,
           ''::VARCHAR(20)                     AS kood,
           'Osaluste soetus (-)'::VARCHAR(254) AS nimetus,
           sum(-1 * e.eelarve)::NUMERIC(14,2),
           sum(-1 * e.taitmine)::NUMERIC(14,2),
           sum(-1 * e.eelnou_kinni)::NUMERIC(14,2),
           sum(-1 * e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '101.1.1%'
    UNION ALL
    SELECT 4                                                  AS idx,
           ''::VARCHAR(20)                                    AS kood,
           'Muude aktsiate ja osade soetus (-)'::VARCHAR(254) AS nimetus,
           sum(-1 * e.eelarve)::NUMERIC(14,2),
           sum(-1 * e.taitmine)::NUMERIC(14,2),
           sum(-1 * e.eelnou_kinni)::NUMERIC(14,2),
           sum(-1 * e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '101.1.2%'
    UNION ALL
    SELECT 4                                         AS idx,
           ''::VARCHAR(20)                           AS kood,
           'Tagasilaekuvad laenud (+)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '1032.2%'
    UNION ALL
    SELECT 4                                  AS idx,
           ''::VARCHAR(20)                    AS kood,
           'Antavad laenud (-)'::VARCHAR(254) AS nimetus,
           sum(-1 * e.eelarve)::NUMERIC(14,2),
           sum(-1 * e.taitmine)::NUMERIC(14,2),
           sum(-1 * e.eelnou_kinni)::NUMERIC(14,2),
           sum(-1 * e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '1032.1%'
    UNION ALL
    SELECT 4                                AS idx,
           ''::VARCHAR(20)                  AS kood,
           'Finantstulud (+)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '382%'
    UNION ALL
    SELECT 4                                 AS idx,
           ''::VARCHAR(20)                   AS kood,
           'Finantstkulud (-)'::VARCHAR(254) AS nimetus,
           sum(e.eelarve)::NUMERIC(14,2),
           sum(e.taitmine)::NUMERIC(14,2),
           sum(e.eelnou_kinni)::NUMERIC(14,2),
           sum(e.eelnou_koostatud):: NUMERIC(14, 2)
    FROM prev_qry e
    WHERE e.kood LIKE '65%'
    UNION ALL
    SELECT 1                                        AS idx,
           e.kood::VARCHAR(20),
           l.nimetus::VARCHAR(254),
           sum(e.eelarve)::NUMERIC(14,2)            AS eelarve,
           sum(e.taitmine)::NUMERIC(14,2)           AS taitmine,
           sum(e.eelnou_kinni)::NUMERIC(14,2)       AS eelnou_kinni,
           sum(e.eelnou_koostatud):: NUMERIC(14, 2) AS eelnou_koostatud
    FROM prev_qry e
           LEFT OUTER JOIN libs.library l ON l.kood = e.kood AND l.library = 'TULUDEALLIKAD'
    WHERE NOT empty(e.kood)
      AND left(e.kood, 2) NOT IN ('35', '32', '38')
      AND left(e.kood, 1) NOT IN ('1', '2', '4', '5', '6')
    GROUP BY e.kood, l.nimetus
)
SELECT
  kood::VARCHAR(20),
  nimetus::VARCHAR(254),
  eelarve::NUMERIC(14,2),
  taitmine::NUMERIC(14,2),
  eelnou_kinni::NUMERIC(14,2),
  eelnou_koostatud::NUMERIC(14,2)
FROM (
       SELECT 3                                                                                    AS idx,
              ''::VARCHAR(20)                                                                      AS kood,
              'PÕHITEGEVUSE TULEM'::VARCHAR(254)                                                   AS nimetus,
              (SELECT sum(eelarve) FROM query WHERE nimetus = 'PÕHITEGEVUSE TULUD KOKKU') -
              (SELECT sum(eelarve) FROM query WHERE nimetus = 'PÕHITEGEVUSE KULUD KOKKU')          AS eelarve,
              (SELECT sum(taitmine) FROM query WHERE nimetus = 'PÕHITEGEVUSE TULUD KOKKU') -
              (SELECT sum(taitmine) FROM query WHERE nimetus = 'PÕHITEGEVUSE KULUD KOKKU')         AS taitmine,
              (SELECT sum(eelnou_kinni) FROM query WHERE nimetus = 'PÕHITEGEVUSE TULUD KOKKU') -
              (SELECT sum(eelnou_kinni) FROM query WHERE nimetus = 'PÕHITEGEVUSE KULUD KOKKU')     AS eelnou_kinni,
              (SELECT sum(eelnou_koostatud) FROM query WHERE nimetus = 'PÕHITEGEVUSE TULUD KOKKU') -
              (SELECT sum(eelnou_koostatud) FROM query WHERE nimetus = 'PÕHITEGEVUSE KULUD KOKKU') AS eelnou_koostatud
       UNION ALL
       SELECT 4                                                       AS idx,
              ''::VARCHAR(20)                                         AS kood,
              'INVESTEERIMISTEGEVUS KOKKU'::VARCHAR(254)              AS nimetus,
              (SELECT sum(eelarve) FROM query WHERE idx = 4)          AS eelarve,
              (SELECT sum(taitmine) FROM query WHERE idx = 4)         AS taitmine,
              (SELECT sum(eelnou_kinni) FROM query WHERE idx = 4)     AS eelnou_kinni,
              (SELECT sum(eelnou_koostatud) FROM query WHERE idx = 4) AS eelnou_koostatud
       UNION ALL
       SELECT idx,
              kood,
              nimetus,
              eelarve,
              taitmine,
              eelnou_kinni,
              eelnou_koostatud
       FROM query
     ) qry
ORDER BY idx, kood

$BODY$
  LANGUAGE SQL
  VOLATILE
  COST 100;

SELECT *
FROM
  eelarve.eelarve_kofs('20181231'::DATE, 63, 0)
/*
              */
