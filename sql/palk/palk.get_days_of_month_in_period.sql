DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE);
DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN);
DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN,
                                                          BOOLEAN);

DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN,
                                                          BOOLEAN, BOOLEAN);

DROP FUNCTION IF EXISTS palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN,
                                                          BOOLEAN, BOOLEAN, BOOLEAN);

CREATE FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE,
                                                  kas_pidu BOOLEAN DEFAULT FALSE, kas_puhkus BOOLEAN DEFAULT FALSE,
                                                  kas_ainult_pidu_paevad boolean DEFAULT FALSE)
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_result      INTEGER = 0; -- tulemus, paevad
    l_pidu_paevad INTEGER = 0;
    v_kalendar    record;
BEGIN

    -- вычислим даты, если не заданы
    if l_kpv1 is null and aasta is not null and kuu is not null then
        l_kpv1 = make_date(aasta, kuu, 1);
    end if;
    if l_kpv2 is null and aasta is not null and kuu is not null then
        l_kpv2 = get_last_day(l_kpv1);
    end if;

    SELECT
        count(*) filter (where is_tahtpaev)                as is_tahtpaev,
        count(*) filter (where is_toopaev and is_tahtpaev) as is_toopaev_and_is_tahtpaev
    into v_kalendar
    FROM
        public.cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63);


    IF date_part('year', l_kpv1) = date_part('year', l_kpv2) AND
       date_part('month', l_kpv2) = date_part('month', l_kpv1) AND aasta = date_part('year', l_kpv1)
        AND kuu = date_part('month', l_kpv1)
    THEN
        -- ajavahemik samas kuu ja aastas
        l_result = (l_kpv2 - l_kpv1) + 1;
        IF (kas_puhkus)
        THEN

            -- Календарные дни минус праздники
            l_result = l_result - v_kalendar.is_tahtpaev;

/*                       (
                                      SELECT
                                          count(*)
                                      FROM
                                          public.cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                      WHERE
                                          is_tahtpaev
                                  );
*/        END IF;

        IF kas_pidu and kas_ainult_pidu_paevad
        THEN
            l_pidu_paevad = v_kalendar.is_tahtpaev;

/*                (
                                SELECT
                                    count(*)
                                FROM
                                    public.cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                WHERE
                                    is_tahtpaev
--                                  AND is_toopaev
                            );
*/        else
            l_pidu_paevad = v_kalendar.is_toopaev_and_is_tahtpaev;

/*                (
                                SELECT
                                    count(*)
                                FROM
                                    public.cur_calender(l_kpv1::DATE, l_kpv2::DATE, 63)
                                WHERE
                                      is_tahtpaev
                                  AND is_toopaev
                            );
*/
        END IF;

    ELSIF date_part('year', l_kpv1) = aasta AND date_part('month', l_kpv1) = kuu AND l_kpv2 > l_kpv1
    THEN

        l_result = (public.get_last_day(l_kpv1) - l_kpv1) + 1;
        IF (kas_puhkus)
        THEN
            l_result = l_result - v_kalendar.is_tahtpaev;

/*                       (
                                      SELECT
                                          count(*)
                                      FROM
                                          public.cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                      WHERE
                                          is_tahtpaev
                                  );
*/        END IF;


        IF kas_pidu
        THEN
            if kas_puhkus and kas_ainult_pidu_paevad then
                l_pidu_paevad = v_kalendar.is_toopaev_and_is_tahtpaev;
/*                    (
                                    SELECT
                                        count(*)
                                    FROM
                                        public.cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                    WHERE
                                        is_tahtpaev
--                                      AND is_toopaev
                                );
*/            else
                l_pidu_paevad = v_kalendar.is_toopaev_and_is_tahtpaev;
/*                    (
                                    SELECT
                                        count(*)
                                    FROM
                                        public.cur_calender(l_kpv1::DATE, get_last_day(l_kpv1)::DATE, 63)
                                    WHERE
                                          is_tahtpaev
                                      AND is_toopaev
                                );
*/            end if;

        END IF;
    ELSIF date_part('year', l_kpv2) = aasta AND date_part('month', l_kpv2) = kuu AND l_kpv2 > l_kpv1
    THEN

        l_result = (l_kpv2 - make_date(aasta, kuu, 1)) + 1;

        IF (kas_puhkus)
        THEN
            l_result = l_result - v_kalendar.is_tahtpaev;
/*                       (
                                      SELECT
                                          count(*)
                                      FROM
                                          public.cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                                      WHERE
                                          is_tahtpaev
                                  );
*/        END IF;

        IF kas_pidu
        THEN

            if kas_puhkus and kas_ainult_pidu_paevad then
                l_pidu_paevad = v_kalendar.is_tahtpaev;
/*                    (
                                    SELECT
                                        count(*)
                                    FROM
                                        public.cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                                    WHERE
                                        is_tahtpaev
                                );
*/
            else
                l_pidu_paevad = v_kalendar.is_toopaev_and_is_tahtpaev;
/*                    (
                                    SELECT
                                        count(*)
                                    FROM
                                        public.cur_calender(make_date(aasta, kuu, 1)::DATE, l_kpv2::DATE, 63)
                                    WHERE
                                          is_tahtpaev
                                      AND is_toopaev
                                );
*/            end if;

        END IF;
    END IF;

    l_result = l_result - CASE when kas_puhkus then 0 WHEN kas_pidu THEN coalesce(l_pidu_paevad, 0) ELSE 0 END;

    if kas_pidu and kas_ainult_pidu_paevad then
        -- вернем только праздники
        l_result = coalesce(l_pidu_paevad, 0);
    end if;

    RETURN l_result;
END

$$;

GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN,BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN, BOOLEAN) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_days_of_month_in_period(kuu INTEGER, aasta INTEGER, l_kpv1 DATE, l_kpv2 DATE, BOOLEAN, BOOLEAN, BOOLEAN) TO dbkasutaja;


/*
select palk.get_days_of_month_in_period(9::integer, 2025::integer,make_date(2025,09,04), make_date(2025,09,07), false, false, true);


*/