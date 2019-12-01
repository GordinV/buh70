DROP FUNCTION IF EXISTS lapsed.get_date_of_birth(TEXT);

CREATE OR REPLACE FUNCTION lapsed.get_date_of_birth(l_isikukood TEXT)
    RETURNS DATE AS
$BODY$

DECLARE
    l_year  text;
    l_month text;
    l_day   text;
    l_date  DATE;
BEGIN

    l_year = substring(l_isikukood, 2, 2)::text ;

    IF (substring(l_isikukood, 1, 1)::INTEGER < 5)
    THEN
        -- 19 sentory
        l_year = '19'::text || l_year::text;
    ELSE
        -- 20 sentory
        l_year = '20'::text || l_year::text;
    END IF;

    l_month = substring(l_isikukood, 4, 2);

    l_day = substring(l_isikukood, 6, 2);

    IF l_month::INTEGER < 1 OR l_month::INTEGER > 12 OR l_day::INTEGER < 1 OR l_day::INTEGER > 31
    THEN
        RAISE NOTICE 'vale isikukood';
        RETURN NULL;
    END IF;

    l_date = date(l_year::INTEGER, l_month::INTEGER, l_day::INTEGER);

    RETURN l_date;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN NULL;


END;

$BODY$
    LANGUAGE plpgsql
    IMMUTABLE
    COST 100;



GRANT EXECUTE ON FUNCTION lapsed.get_date_of_birth(TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_date_of_birth(TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_date_of_birth(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_date_of_birth(TEXT) TO arvestaja;


SELECT lapsed.get_date_of_birth('49308233762');
/*
select substring('40308233762', 2, 2)

*/