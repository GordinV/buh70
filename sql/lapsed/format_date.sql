-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS format_date(TEXT );
DROP FUNCTION IF EXISTS format_date(DATE);

CREATE OR REPLACE FUNCTION format_date(l_kpv TEXT
)
    RETURNS date AS

    $BODY$

DECLARE
    return_date date;
BEGIN

    IF (isfinite(l_kpv::DATE)) THEN
        return_date = l_kpv;
    END IF;
    RETURN return_date;

EXCEPTION WHEN OTHERS
    THEN
        RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
        RETURN null;

END;$BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100;

/*
select format_date(to_char(current_date,'DD.MM.YYYY')::TEXT);
select format_date('01.12.2019'::TEXT);

 */