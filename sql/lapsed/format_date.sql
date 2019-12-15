-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS format_date(TEXT);
DROP FUNCTION IF EXISTS format_date(DATE);

CREATE OR REPLACE FUNCTION format_date(l_kpv TEXT
)
    RETURNS DATE AS

$BODY$

DECLARE
    return_date DATE;
BEGIN
    -- format DD.MM.YYYY HH:MI:SS
    IF (SELECT l_kpv SIMILAR TO '__.__.____') or (SELECT l_kpv SIMILAR TO '__.__.____ __:__*')
    THEN
        return_date = make_date(substring(l_kpv FROM 7 FOR 4)::INTEGER, substring(l_kpv FROM 4 FOR 2)::INTEGER,
                                left(l_kpv, 2)::INTEGER);

    ELSEIF (isfinite(l_kpv::DATE))
    THEN
        return_date = l_kpv;
    END IF;

    RETURN return_date;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN NULL;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

/*
select format_date(to_char(current_date,'DD.MM.YYYY')::TEXT);
select format_date('01.12.2019'::TEXT);

 */