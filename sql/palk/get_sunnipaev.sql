DROP FUNCTION IF EXISTS palk.get_sunnipaev(TEXT);

CREATE FUNCTION palk.get_sunnipaev(l_isikukood TEXT)
    RETURNS DATE
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_sunnipaev DATE;
    l_aasta     INTEGER;
    l_kuu       INTEGER;
    l_paev      INTEGER;
BEGIN
    IF l_isikukood IS NULL OR l_isikukood = '' OR len(l_isikukood) < 7 OR l_paev < 1 OR l_paev > 31 OR l_kuu < 1 OR
       l_kuu > 12
    THEN
        RETURN current_date;
    END IF;
    -- расчитываем день рождения
    -- aasta

    l_aasta = CASE WHEN left(l_isikukood, 1) IN ('3', '4') THEN 1900 ELSE 2000 END + val(substr(l_isikukood, 2, 2));
    l_kuu = val(substr(l_isikukood, 4, 2));
    l_paev = val(substr(l_isikukood, 6, 2));

    IF coalesce(l_paev, 0) < 1 OR coalesce(l_paev, 0) > 31 OR coalesce(l_kuu, 0) < 1 OR coalesce(l_kuu, 0) > 12
    THEN
        RETURN current_date;
    END IF;


    l_sunnipaev = make_date(l_aasta, l_kuu, l_paev);


    RETURN l_sunnipaev;

END
$$;


GRANT EXECUTE ON FUNCTION palk.get_sunnipaev(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_sunnipaev(TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_sunnipaev(TEXT) TO dbvaatleja;


/*
SELECT palk.get_sunnipaev('48912303712')
*/