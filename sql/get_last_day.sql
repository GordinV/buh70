DROP FUNCTION IF EXISTS public.get_last_day(kpv DATE);

CREATE FUNCTION public.get_last_day(kpv DATE)
    RETURNS DATE
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN ((make_date(date_part('year', kpv)::INTEGER, date_part('month', kpv)::INTEGER, 1) +
             INTERVAL '1 month') :: DATE - 1);
END
$$;


SELECT public.get_last_day(current_date);