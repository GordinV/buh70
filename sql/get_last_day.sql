DROP FUNCTION IF EXISTS get_last_day(kpv DATE );

CREATE FUNCTION get_last_day(kpv DATE)
  RETURNS DATE
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN ((make_date(year(kpv), month(kpv), 1) + INTERVAL '1 month') :: DATE - 1);
END;
$$;


select get_last_day(current_date);