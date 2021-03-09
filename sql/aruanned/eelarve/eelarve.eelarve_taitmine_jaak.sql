DROP FUNCTION IF EXISTS eelarve.eelarve_taitmine_jaak(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER);

CREATE OR REPLACE FUNCTION eelarve.eelarve_taitmine_jaak(l_kpv DATE, l_rekvid INTEGER, l_kond INTEGER)
    RETURNS TABLE (
        rekv_id        INTEGER,
        tegev          VARCHAR(20),
        allikas        VARCHAR(20),
        artikkel       VARCHAR(20),
        tunnus         VARCHAR(20),
        eelarve        NUMERIC(14, 2),
        eelarve_kassa  NUMERIC(14, 2),
        taitmine       NUMERIC(14, 2),
        taitmine_kassa NUMERIC(14, 2)

    ) AS
$BODY$
WITH qry_eelarve AS (
    -- бюджет
    SELECT e.rekvid           AS rekv_id,
           sum(e.summa)       AS eelarve,
           sum(e.summa_kassa) AS eelarve_kassa,
           e.kood1            AS tegev,
           e.kood2            AS allikas,
           e.kood5            AS artikkel,
           e.tunnus           AS tunnus
    FROM eelarve.eelarve e
    WHERE aasta = year(l_kpv)
      AND (e.kpv IS NULL OR e.kpv <= l_kpv)
      AND (NOT empty(e.is_kulud::INTEGER)
        OR (kood5 IN ('2585', '2586') AND e.kood2 <> '80'
               ))
      AND e.rekvid = (CASE
                          WHEN l_kond IS NULL OR empty(l_kond)
                              THEN l_rekvid
                          ELSE e.rekvid END)
      AND e.rekvid IN (SELECT rekv_id
                       FROM get_asutuse_struktuur(l_rekvid))
      AND e.status <> 3 GROUP BY e.rekvid
        , e.kood1
        , e.kood2
        , e.kood5
        , e.tunnus
),
     qry_kulude_kassa_taitmine AS (
         -- кассовое исполнение расходы
         SELECT *
         FROM eelarve.uus_kassa_taitmine(make_date(YEAR(l_kpv)
                                             , 01
                                             , 01)
                  , l_kpv
                  , l_rekvid
                  , l_kond)
         WHERE CASE WHEN artikkel IN ('2585', '2586') AND allikas = '80' THEN FALSE ELSE TRUE END
           AND artikkel IN (SELECT kood
                            FROM com_artikkel
                            WHERE is_kulud)
     )
        ,
     -- tekke taotmine расходы
     qry_kulude_taitmine AS (SELECT *
                             FROM eelarve.tekke_taitmine(make_date(YEAR(l_kpv)
                                                             , 01
                                                             , 01)
                                      , l_kpv
                                      , l_rekvid
                                      , l_kond)
                             WHERE CASE WHEN artikkel IN ('2585', '2586') AND allikas = '80' THEN FALSE ELSE TRUE END
                               AND artikkel IN (SELECT kood
                                                FROM com_artikkel
                                                WHERE is_kulud)
     )
        ,
     pre_report AS (
         SELECT rekv_id
                 ,
                tegev
                 ,
                allikas
                 ,
                artikkel
                 ,
                tunnus
                 ,
                sum(eelarve)::NUMERIC(14
                    , 2) AS eelarve
                 ,
                sum(eelarve_kassa)::NUMERIC(14
                    , 2) AS eelarve_kassa
                 ,
                sum(taitmine)::NUMERIC(14
                    , 2) AS taitmine
                 ,
                sum(taitmine_kassa)::NUMERIC(14
                    , 2) AS taitmine_kassa
         FROM (
                  SELECT rekv_id
                          ,
                         tegev
                          ,
                         allikas
                          ,
                         artikkel
                          ,
                         tunnus
                          ,
                         eelarve
                          ,
                         eelarve_kassa
                          ,
                         0::NUMERIC(14
                             , 2) AS taitmine
                          ,
                         0::NUMERIC(14
                             , 2) AS taitmine_kassa
                  FROM qry_eelarve
                  UNION ALL
                  SELECT t.rekv_id
                          ,
                         t.tegev
                          ,
                         t.allikas
                          ,
                         t.artikkel
                          ,
                         t.tunnus
                          ,
                         0::NUMERIC(14
                             , 2) AS eelarve
                          ,
                         0::NUMERIC(14
                             , 2) AS eelarve_kassa
                          ,
                         0::NUMERIC(14
                             , 2) AS taitmine
                          ,
                         t.summa  AS taitmine_kassa
                  FROM qry_kulude_kassa_taitmine t
                  UNION ALL
                  SELECT t.rekv_id
                          ,
                         t.tegev
                          ,
                         t.allikas
                          ,
                         t.artikkel
                          ,
                         t.tunnus
                          ,
                         0::NUMERIC(14
                             , 2) AS eelarve
                          ,
                         0::NUMERIC(14
                             , 2) AS eelarve_kassa
                          ,
                         t.summa::NUMERIC(14
                             , 2) AS taitmine
                          ,
                         0::NUMERIC(14
                             , 2) AS taitmine_kassa
                  FROM qry_kulude_taitmine t
              ) qry
         GROUP BY rekv_id
                 ,
                  tegev
                 ,
                  allikas
                 ,
                  artikkel
                 ,
                  tunnus
     )
SELECT *
FROM pre_report
UNION ALL
-- kond
SELECT 999999
        ,
       tegev
        ,
       allikas
        ,
       artikkel
        ,
       tunnus
        ,
       sum(eelarve)::NUMERIC(14
           , 2) AS eelarve
        ,
       sum(eelarve_kassa)::NUMERIC(14
           , 2) AS eelarve_kassa
        ,
       sum(taitmine)::NUMERIC(14
           , 2) AS taitmine
        ,
       sum(taitmine_kassa)::NUMERIC(14
           , 2) AS taitmine_kassa
FROM pre_report
WHERE l_kond
    > 0
    GROUP BY tegev
    ,
    allikas
    ,
    artikkel
    ,
    tunnus

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

/*
select *
from eelarve.eelarve_taitmine_jaak(current_date, 63, 1)
*/