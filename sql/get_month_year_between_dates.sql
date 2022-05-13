DROP FUNCTION IF EXISTS get_month_year_between_dates(DATE, DATE);

CREATE OR REPLACE FUNCTION get_month_year_between_dates(alg_kpv DATE DEFAULT make_date(YEAR(), 01, 01),
                                                        lopp_kpv DATE DEFAULT CURRENT_DATE)
    RETURNS TABLE (
        kuu   INTEGER,
        aasta INTEGER
    )
AS
$BODY$
WITH days_in_period AS
         (
             SELECT *
             FROM unnest(get_days_between_dates(alg_kpv, lopp_kpv)) AS day_
             WHERE day(day_) = 1
         )
SELECT month(dp.day_), year(dp.day_)
FROM days_in_period dp

$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION get_month_year_between_dates(DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_month_year_between_dates(DATE, DATE) TO dbpeakasutaja;

/*
select  * from  get_month_year_between_dates()
select  * from  get_month_year_between_dates('2022-01-01'::date, current_date)

*/