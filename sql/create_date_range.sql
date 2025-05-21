DROP FUNCTION IF EXISTS create_date_range(DATE, DATE);

CREATE FUNCTION create_date_range(kpv_1 DATE, kpv_2 DATE)
    RETURNS daterange
    LANGUAGE plpgsql
AS
$$
    declare
        l_kpv_1 date = case when kpv_1 < kpv_2 then kpv_1 else kpv_2 end;
        l_kpv_2 date = case when kpv_1 > kpv_2 then kpv_1 else kpv_2 end;
BEGIN
    RETURN ('[' || l_kpv_1::TEXT || ',' || l_kpv_2::TEXT  || ')') ::DATERANGE;
END
$$;


SELECT create_date_range('2025-01-01'::DATE, current_date);