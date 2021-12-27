DROP FUNCTION IF EXISTS get_days_between_dates(DATE, DATE);

CREATE OR REPLACE FUNCTION get_days_between_dates(alg_kpv DATE, lopp_kpv DATE)
    RETURNS DATE[] AS
$BODY$

DECLARE
    l_kpv DATE   = alg_kpv;
    a_kpv DATE[] = ARRAY [l_kpv];
BEGIN
    WHILE l_kpv < lopp_kpv
        LOOP
            IF l_kpv < lopp_kpv
            THEN
                l_kpv = l_kpv + 1;
                a_kpv = a_kpv || l_kpv;
            END IF;
        END LOOP;
    raise notice 'a_kpv %', a_kpv;
    RETURN a_kpv;
END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION get_days_between_dates(DATE, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION get_days_between_dates(DATE, DATE) TO dbpeakasutaja;
/*
select  palk.calc_mvt(1200, 500)
select  palk.calc_mvt(1200, 0)
select  palk.calc_mvt(2000, 500)
select  palk.calc_mvt(200, 500)

*/