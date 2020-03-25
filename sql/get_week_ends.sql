DROP FUNCTION IF EXISTS get_week_ends(kuu INTEGER, aasta INTEGER);
DROP FUNCTION IF EXISTS get_week_ends(kuu INTEGER, aasta INTEGER, INTEGER);

CREATE FUNCTION get_week_ends(l_kuu INTEGER, l_aasta INTEGER, l_rekvid INTEGER DEFAULT NULL)
    RETURNS INTEGER[]
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_last_day INTEGER = day(get_last_day(make_date(l_aasta, l_kuu, 1)));
    l_return   INTEGER[];
    l_kpv      DATE;
BEGIN
    FOR i IN 1..l_last_day
        LOOP
            l_kpv = make_date(l_aasta, l_kuu, i);
            IF dow(l_kpv) IN (0, 6)
            THEN
                l_return = array_append(l_return, i);
            ELSE
                IF exists(
                        SELECT id, *
                        FROM cur_tahtpaevad t
                        WHERE t.kuu = l_kuu
                          AND t.aasta = l_aasta
                          AND paev = i
                          AND (rekvid = l_rekvid OR l_rekvid IS NULL)
                    )
                THEN
                    l_return = array_append(l_return, i);
                END IF;
            END IF;
        END LOOP;
    RETURN l_return;
END;
$$;

/*
SELECT get_week_ends(3, 2019, 63);

 */