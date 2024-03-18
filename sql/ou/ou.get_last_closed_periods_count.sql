DROP FUNCTION IF EXISTS ou.is_last_kvartal_opened(l_rekvid INTEGER, l_kpv DATE);
DROP FUNCTION IF EXISTS ou.is_last_quarter_opened(l_rekvid INTEGER, l_kpv DATE);

CREATE OR REPLACE FUNCTION ou.is_last_quarter_opened(l_rekvid INTEGER, l_kpv DATE DEFAULT current_date) RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_return             BOOLEAN DEFAULT FALSE;
    l_period_start       DATE;
    l_period_finish      DATE;
    l_last_opened_period DATE;
    v_period             RECORD;
BEGIN
    l_period_start = CASE
                         WHEN month(l_kpv) >= 1 AND month(l_kpv) < 4 THEN make_date(year(l_kpv), 01, 01)
                         WHEN month(l_kpv) >= 4 AND month(l_kpv) < 7 THEN make_date(year(l_kpv), 04, 01)
                         WHEN month(l_kpv) >= 7 AND month(l_kpv) < 10 THEN make_date(year(l_kpv), 07, 01)
                         ELSE
                             make_date(year(l_kpv), 10, 01)
        END;
    l_period_finish = CASE
                          WHEN month(l_kpv) >= 1 AND month(l_kpv) < 4 THEN make_date(year(l_kpv), 03, 31)
                          WHEN month(l_kpv) >= 4 AND month(l_kpv) < 7 THEN make_date(year(l_kpv), 06, 30)
                          WHEN month(l_kpv) >= 7 AND month(l_kpv) < 10 THEN make_date(year(l_kpv), 09, 30)
                          ELSE
                              make_date(year(l_kpv), 12, 31)
        END;


    SELECT kinni
    INTO v_period
    FROM ou.aasta a
    WHERE rekvid = l_rekvid
      AND make_date(a.aasta, a.kuu, 01) = make_date(year(l_period_finish), MONTH(l_period_finish), 01);

    RAISE NOTICE 'l_kpv %, l_period_finish %, v_period %, empty %', l_kpv, l_period_finish, v_period, empty(coalesce(v_period.kinni, 0)::INTEGER);

    IF v_period IS NOT NULL AND empty(coalesce(v_period.kinni, 0)::INTEGER)
    THEN
        l_return = TRUE;
    ELSE
        l_return = FALSE;

    END IF;

    RETURN l_return;
END
$$;

--ALTER FUNCTION ou.get_last_closed_periods_count(INTEGER, DATE) OWNER TO vlad;

GRANT EXECUTE ON FUNCTION ou.is_last_quarter_opened(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.is_last_quarter_opened(INTEGER, DATE) TO dbkasutaja;


SELECT ou.is_last_quarter_opened(63, DATE(aasta, kuu, 01)), *
FROM ou.aasta
WHERE rekvid = 63
  AND aasta.aasta >= 2023
ORDER BY aasta, kuu DESC

--update ou.aasta set kinni = 1 where id = 9564