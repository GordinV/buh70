DROP FUNCTION IF EXISTS create_date_range(DATE, DATE);

 DROP FUNCTION IF EXISTS create_date_range(date, date, boolean);

CREATE OR REPLACE FUNCTION public.create_date_range(
    kpv_1 date,
    kpv_2 date,
    kas_include boolean DEFAULT false)
    RETURNS daterange
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

declare
    l_kpv_1 date = case when kpv_1 < kpv_2 then kpv_1 else kpv_2 end;
    l_kpv_2 date = case when kpv_1 > kpv_2 then kpv_1 else kpv_2 end;
BEGIN
    RETURN ('[' || l_kpv_1::TEXT || ',' || l_kpv_2::TEXT  || case when kas_include then ']' else ')' end) ::DATERANGE;
END
$BODY$;

ALTER FUNCTION public.create_date_range(date, date, boolean)
    OWNER TO vlad;

GRANT EXECUTE ON FUNCTION public.create_date_range(date, date, boolean) TO PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_date_range(date, date, boolean) TO vlad;



SELECT create_date_range('2025-01-01'::DATE, current_date);