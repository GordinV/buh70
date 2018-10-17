DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE );

CREATE FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  l_result INTEGER = 0; -- tulemus, paevad
BEGIN
  IF year(l_kpv1) = year(l_kpv2) AND month(l_kpv2) = month(l_kpv1) AND aasta = year(l_kpv1) AND kuu = month(l_kpv1)
  THEN
    -- ajavahemik samas kuu ja aastas
    l_result = (l_kpv2 - l_kpv1) + 1;
  ELSIF year(l_kpv1) = aasta AND month(l_kpv1) = kuu AND l_kpv2 > l_kpv1
    THEN
      l_result = (get_last_day(l_kpv1) - l_kpv1) + 1;
  ELSIF year(l_kpv2) = aasta AND month(l_kpv2) = kuu AND l_kpv2 > l_kpv1
    THEN
      l_result = (l_kpv2 - make_date(aasta, kuu, 1)) + 1;
  END IF;

  RETURN l_result;
END;
$$;

/*
select palk.get_days_of_month_in_period(1, 2018, date(2018,01,15), date(2018,02,18));

*/