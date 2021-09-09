DROP FUNCTION IF EXISTS cur_calender(DATE, DATE, INTEGER);

CREATE OR REPLACE FUNCTION cur_calender(l_alg_kpv DATE, l_lopp_kpv DATE, l_rekv INTEGER)
    RETURNS TABLE (
        paev        INTEGER,
        kpv         DATE,
        dow         INTEGER,
        is_toopaev  BOOLEAN,
        is_tahtpaev BOOLEAN
    )
AS
$BODY$

SELECT day                                                                                                 AS paev,
       make_date(year(l_alg_kpv), month(l_alg_kpv), day)                                                   AS kpv,
       DOW(make_date(year(l_alg_kpv), month(l_alg_kpv), day))                                              AS dow,
       CASE
           WHEN DOW(make_date(year(l_alg_kpv), month(l_alg_kpv), day)) IN (0, 6) THEN FALSE
           ELSE TRUE END                                                                                   AS is_toopaev,
       (exists(SELECT id
               FROM cur_tahtpaevad
               WHERE aasta = year(make_date(year(l_alg_kpv), month(l_alg_kpv), day))
                 AND kuu = month(make_date(year(l_alg_kpv), month(l_alg_kpv), day))
                 AND paev = day(make_date(year(l_alg_kpv), month(l_alg_kpv), day))
           ))                                                                                              AS is_tahtpaev
FROM (
         SELECT extract(DAY FROM dt)::INTEGER AS day
         FROM generate_series(l_alg_kpv::DATE, l_lopp_kpv::DATE, INTERVAL '1' DAY) AS g(dt)
         GROUP BY extract(DAY FROM dt)
         ORDER BY 1
     ) qry
    ;

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION cur_calender(DATE, DATE, INTEGER) TO PUBLIC;


/*
SELECT *
FROM cur_calender('2020-03-01', '2020-03-10' :: DATE, 3);

SELECT *
FROM cur_calender(make_date(2020, 2,1), make_date(2020, 02, 29),
                  3)
WHERE  NOT is_toopaev;
*/