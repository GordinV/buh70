DROP FUNCTION IF EXISTS public.get_date_from_string(TEXT, TEXT);

CREATE FUNCTION get_date_from_string(l_date text, l_format text default 'DD.MM.YYYY') RETURNS DATE
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_Day   text;
    l_kuu   text;
    l_aasta text;
    l_kpv   date;
BEGIN
    l_date = ltrim(rtrim(l_date));
    case
        when l_format = 'DD.MM.YYYY' then l_day = left(l_date, 2);
                                          l_kuu = substring(l_date from 4 for 2);
                                          l_aasta = substring(l_date from 7 for 4);
                                          l_kpv = to_date(l_aasta + l_kuu + l_day, 'YYYYMMDD');
        when l_format = 'DD.MM.YY' then l_day = left(l_date, 2);
                                          l_kuu = substring(l_date from 4 for 2);
                                          l_aasta = '20' || substring(l_date from 7 for 2);
                                          l_kpv = to_date(l_aasta + l_kuu + l_day, 'YYYYMMDD');
        when l_format = 'YYYY-MM-DD' then
            l_kpv = l_date::date;
        end case;

    RETURN l_kpv;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_date_from_string (text, text) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION public.get_date_from_string (text, text) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION public.get_date_from_string (text, text) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION public.get_date_from_string (text, text) TO dbadmin;

select get_date_from_string('01.10.2024') as kpv, get_date_from_string('2024-10-01', 'YYYY-MM-DD') as kpv2;

