DROP FUNCTION IF EXISTS public.cur_calender(DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION public.cur_calender(l_alg_kpv DATE, l_lopp_kpv DATE, l_rekv INTEGER)
    RETURNS TABLE (
        paev        INTEGER,
        kpv         DATE,
        dow         INTEGER,
        is_toopaev  BOOLEAN,
        is_tahtpaev BOOLEAN
    )
AS
$BODY$

WITH period AS (
    SELECT date_part('year', l_alg_kpv)::INTEGER  AS aasta,
           date_part('month', l_alg_kpv)::INTEGER AS kuu
)
SELECT day::INTEGER                                                        AS paev,
       MAKE_DATE(period.aasta, period.kuu, DAY)::DATE                      AS kpv,
       date_part('dow', make_date(period.aasta, period.kuu, DAY))::INTEGER AS DOW,
       CASE
           WHEN date_part('dow', make_date(period.aasta, period.kuu, DAY)) IN (0, 6) THEN FALSE
           ELSE TRUE
           END                                                             AS is_toopaev,
       (EXISTS(SELECT id
               FROM PUBLIC.cur_tahtpaevad
               WHERE aasta = date_part('year', make_date(period.aasta, period.kuu, DAY))
                 AND kuu = date_part('month', make_date(period.aasta, period.kuu, DAY))
                 AND paev = date_part('day', make_date(period.aasta, period.kuu, DAY))
           ))                                                              AS is_tahtpaev
FROM (
         SELECT EXTRACT(DAY FROM dt)::INTEGER AS DAY
         FROM generate_series(l_alg_kpv::DATE, l_lopp_kpv::DATE, INTERVAL '1' DAY) AS g(dt)
         GROUP BY EXTRACT(DAY FROM dt)
         ORDER BY 1
     ) qry,
     period
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION public.cur_calender(DATE, DATE, INTEGER) TO PUBLIC;


/*
SELECT *
FROM public.cur_calender('2020-03-01', '2020-03-10' :: DATE, 3);

SELECT *
FROM cur_calender(make_date(2020, 2,1), make_date(2020, 02, 29),
                  3)
WHERE  NOT is_toopaev;
*/