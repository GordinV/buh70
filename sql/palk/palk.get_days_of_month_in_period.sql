DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE);
DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN);
DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN);

CREATE FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                 kas_pidu BOOLEAN DEFAULT FALSE, kas_puhkus BOOLEAN DEFAULT FALSE)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_result      INTEGER = 0; -- tulemus, paevad
    l_pidu_paevad INTEGER = 0;
BEGIN
    IF date_part('year',l_kpv1) = date_part('year',l_kpv2) AND date_part('month',l_kpv2) = date_part('month',l_kpv1) AND aasta = date_part('year',l_kpv1)
           AND kuu = date_part('month',l_kpv1)
    THEN
        -- ajavahemik samas kuu ja aastas
        l_result = (l_kpv2 - l_kpv1) + 1;
        IF (kas_puhkus)
        THEN

            -- Календарные дни минус праздники
            l_result = l_result - (SELECT count(*)
                                   FROM public.cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                   WHERE is_tahtpaev);
        END IF;

        IF kas_pidu
        THEN
            l_pidu_paevad = (SELECT count(*)
                                        FROM public.cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                        WHERE is_tahtpaev
                                          AND is_toopaev
            );

        END IF;

    ELSIF date_part('year',l_kpv1) = aasta AND date_part('month',l_kpv1) = kuu AND l_kpv2 > l_kpv1
    THEN
        l_result = (public.get_last_day(l_kpv1) - l_kpv1) + 1;
        IF (kas_puhkus)
        THEN
            l_result = l_result - (SELECT count(*)
                                   FROM public.cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                   WHERE is_tahtpaev);
        END IF;


        IF kas_pidu
        THEN

            l_pidu_paevad =  (SELECT count(*)
                                        FROM public.cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                        WHERE is_tahtpaev
                                          AND is_toopaev
            );
        END IF;
    ELSIF date_part('year',l_kpv2) = aasta AND date_part('month',l_kpv2) = kuu AND l_kpv2 > l_kpv1
    THEN
        l_result = (l_kpv2 - make_date(aasta, kuu, 1)) + 1;

        IF (kas_puhkus)
        THEN
            l_result = l_result - (SELECT count(*)
                                   FROM public.cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                                   WHERE is_tahtpaev);
        END IF;

        IF kas_pidu
        THEN

            l_pidu_paevad = (SELECT count(*)
                             FROM public.cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                             WHERE is_tahtpaev
                               AND is_toopaev
            );
        END IF;
    END IF;

    RETURN l_result - CASE when kas_puhkus then 0 WHEN kas_pidu THEN coalesce(l_pidu_paevad, 0) ELSE 0 END;
END
$$;

GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN) TO dbkasutaja;


/*
select palk.get_days_of_month_in_period(11, 2022, make_date(2022,11,01), make_date(2022,11,30), true, true);


*/