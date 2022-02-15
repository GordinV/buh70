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
    RAISE NOTICE 'kuu %, l_kpv1 %, l_kpv2 %', kuu, l_kpv1, l_kpv2;
    IF year(l_kpv1) = year(l_kpv2) AND month(l_kpv2) = month(l_kpv1) AND aasta = year(l_kpv1) AND kuu = month(l_kpv1)
    THEN
        -- ajavahemik samas kuu ja aastas
        l_result = (l_kpv2 - l_kpv1) + 1;
        IF (kas_puhkus)
        THEN
            -- Календарные дни минус праздники
            l_result = l_result - (SELECT count(*)
                                   FROM cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                   WHERE is_tahtpaev);
            RAISE NOTICE 'l_result %',l_result;
        END IF;

        IF kas_pidu
        THEN
            l_pidu_paevad = (SELECT count(*)
                                        FROM cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                        WHERE is_tahtpaev
                                          AND is_toopaev
            );

        END IF;

    ELSIF year(l_kpv1) = aasta AND month(l_kpv1) = kuu AND l_kpv2 > l_kpv1
    THEN
        l_result = (get_last_day(l_kpv1) - l_kpv1) + 1;
        IF (kas_puhkus)
        THEN
            l_result = l_result - (SELECT count(*)
                                   FROM cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                   WHERE is_tahtpaev);
            RAISE NOTICE 'l_result %',l_result;
        END IF;

        IF kas_pidu
        THEN

            l_pidu_paevad =  (SELECT count(*)
                                        FROM cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                        WHERE is_tahtpaev
                                          AND is_toopaev
            );
        END IF;
    ELSIF year(l_kpv2) = aasta AND month(l_kpv2) = kuu AND l_kpv2 > l_kpv1
    THEN
        l_result = (l_kpv2 - make_date(aasta, kuu, 1)) + 1;

        IF (kas_puhkus)
        THEN
            l_result = l_result - (SELECT count(*)
                                   FROM cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                                   WHERE is_tahtpaev);
            RAISE NOTICE 'l_result %',l_result;
        END IF;

        IF kas_pidu
        THEN

            l_pidu_paevad = (SELECT count(*)
                             FROM cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                             WHERE is_tahtpaev
                               AND is_toopaev
            );
        END IF;
    END IF;

    RAISE NOTICE 'l_pidu_paevad %', l_pidu_paevad;
    RETURN l_result - CASE when kas_puhkus then 0 WHEN kas_pidu THEN coalesce(l_pidu_paevad, 0) ELSE 0 END;
END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN) TO dbkasutaja;


/*
select palk.get_days_of_month_in_period(4, 2021, date(2021,04,01), date(2021,04,09), true, true);

*/