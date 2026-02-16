-- FUNCTION: public.gomonth(date, integer)

-- DROP FUNCTION IF EXISTS public.gomonth(date, integer);

CREATE OR REPLACE FUNCTION gomonth(
    date,
    integer)
    RETURNS date
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$


declare

    tdKpv alias for $1;
    tnPeriod alias for $2;

begin
    return  (tdKpv + (tnPeriod::text || ' month')::interval)::date ;
end;

$BODY$;

GRANT EXECUTE ON FUNCTION gomonth(date, integer) TO PUBLIC;

select gomonth('2025-10-31',1)