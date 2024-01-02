--DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaive(INTEGER, DATE, DATE);
DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaibeandmik_period(INTEGER, DATE, DATE, TEXT);
DROP FUNCTION IF EXISTS lapsed.saldo_ja_kaibeandmik_period(INTEGER, DATE, DATE, TEXT, TEXT, TEXT);

CREATE OR REPLACE FUNCTION lapsed.saldo_ja_kaibeandmik_period(l_rekvid INTEGER,
                                                              kpv_start DATE DEFAULT make_date(date_part('year', current_date)::INTEGER, 1, 1),
                                                              kpv_end DATE DEFAULT current_date,
                                                              l_isikukood TEXT DEFAULT NULL,
                                                              l_nimi TEXT DEFAULT '%',
                                                              l_vn TEXT DEFAULT '%')
    RETURNS TABLE (
        id         BIGINT,
        period     DATE,
        asutus     TEXT,
        alg_db     NUMERIC(12, 2),
        alg_kr     NUMERIC(12, 2),
        db         NUMERIC(12, 2),
        kr         NUMERIC(12, 2),
        mahakantud NUMERIC(12, 2),
        lopp_db    NUMERIC(12, 2),
        lopp_kr    NUMERIC(12, 2),
        rekvid     INTEGER,
        isik_id    INTEGER,
        arv_period TEXT
    )
AS
$BODY$
WITH params AS (SELECT kpv_start::DATE AS kpv1,
                       kpv_end::DATE   AS kpv2,
                       l_rekvid        AS rekvid,
                       l_isikukood     AS isikukood,
                       l_nimi          AS nimi,
                       l_vn            AS vn
),
     lapsed AS (
         SELECT l.id
         FROM lapsed.laps l,
              params
         WHERE l.isikukood LIKE coalesce(params.isikukood, '') || '%'
           AND l.nimi ILIKE '%' || coalesce(params.nimi,'') || '%'
           AND lapsed.get_viitenumber(l_rekvid, l.id) LIKE coalesce(params.vn, '') || '%'
           AND staatus < 3
     ),
     periods AS (
         WITH month AS (SELECT 1 AS kuu
                        UNION
                        SELECT 2 AS kuu
                        UNION
                        SELECT 3 AS kuu
                        UNION
                        SELECT 4 AS kuu
                        UNION
                        SELECT 5 AS kuu
                        UNION
                        SELECT 6 AS kuu
                        UNION
                        SELECT 7 AS kuu
                        UNION
                        SELECT 8 AS kuu
                        UNION
                        SELECT 9 AS kuu
                        UNION
                        SELECT 10 AS kuu
                        UNION
                        SELECT 11 AS kuu
                        UNION
                        SELECT 12 AS kuu),
              years AS (
                  SELECT DISTINCT year
                  FROM (
                           SELECT date_part('year', p.kpv1)::INTEGER - 1 AS year
                           FROM params p
                           UNION ALL
                           SELECT date_part('year', p.kpv1)::INTEGER AS year
                           FROM params p
                           UNION ALL
                           SELECT date_part('year', p.kpv1)::INTEGER + 1 AS year
                           FROM params p
                           UNION ALL
                           SELECT date_part('year', p.kpv2)::INTEGER AS year
                           FROM params p
                           UNION ALL
                           SELECT date_part('year', p.kpv2)::INTEGER + 1 AS year
                           FROM params p) aasta
              )

         SELECT kpv                                                                                AS kpv1,
                gomonth(kpv, 1) - 1                                                                AS kpv2,
                CASE WHEN date_part('month', period.kpv) < 10 THEN '0' ELSE '' END::TEXT ||
                date_part('month', period.kpv)::TEXT || '-' || date_part('year', period.kpv)::TEXT AS period

         FROM (
                  SELECT make_date(y.year, m.kuu, 1) kpv
                  FROM month m,
                       years y,
                       params p) period,
              params p
         WHERE kpv <= p.kpv2
           AND kpv >= p.kpv1
         ORDER BY kpv
     )
--select * from lapsed
SELECT rep.id,
       periods.kpv1                                                             AS period,
       r.nimetus                                                                AS asutus,
       CASE WHEN rep.alg_db = 0 THEN NULL ELSE rep.alg_db END::NUMERIC(12, 2)   AS alg_db,
       CASE WHEN rep.alg_kr = 0 THEN NULL ELSE rep.alg_kr END::NUMERIC(12, 2)   AS alg_kr,
       rep.db,
       rep.kr,
       rep.mahakantud,
       CASE WHEN rep.lopp_db = 0 THEN NULL ELSE rep.lopp_db END::NUMERIC(12, 2) AS lopp_db,
       CASE WHEN rep.lopp_kr = 0 THEN NULL ELSE rep.lopp_kr END::NUMERIC(12, 2) AS lopp_kr,
       rep.rekvid,
       rep.isik_id,
       periods.period::TEXT                                                     AS arv_period
FROM lapsed,
     periods,
     params,
     lapsed.saldo_ja_kaibeandmik(params.rekvid::INTEGER, periods.kpv1::DATE, periods.kpv2::DATE, lapsed.id
         ) rep
         INNER JOIN ou.rekv r ON r.id = rep.rekvid
--*/$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik_period(INTEGER, DATE, DATE,TEXT, TEXT, TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik_period(INTEGER, DATE, DATE,TEXT, TEXT, TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik_period(INTEGER, DATE, DATE,TEXT, TEXT, TEXT) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_ja_kaibeandmik_period(INTEGER, DATE, DATE,TEXT, TEXT, TEXT) TO dbvaatleja;

SELECT *
FROM lapsed.saldo_ja_kaibeandmik_period(80, '2023-01-01', '2023-03-31', '61510120210','%%','0800091293') qry
ORDER BY isik_id,
         CASE WHEN left(arv_period, 1) = 'A' THEN 'a' WHEN left(arv_period, 1) = 'L' THEN 'l' ELSE 'k' END,
         arv_period

/*
*/
