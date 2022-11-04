-- FUNCTION: public.empty(integer)

-- DROP FUNCTION IF EXISTS public.empty(integer);

CREATE OR REPLACE FUNCTION empty(
    integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$


begin

    if $1 is null or $1 = 0 then

        return true;

    else

        return false;

    end if;

end;

$BODY$;

ALTER FUNCTION public.empty(integer)
    OWNER TO vlad;

GRANT EXECUTE ON FUNCTION public.empty(integer) TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.empty(integer) TO dbadmin;

GRANT EXECUTE ON FUNCTION public.empty(integer) TO vlad;

