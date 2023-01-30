DROP FUNCTION IF EXISTS palk.kas_soodustus_mvt(INTEGER, DATE);
DROP FUNCTION IF EXISTS palk.kas_soodustus_mvt(TEXT, DATE);

CREATE FUNCTION palk.kas_soodustus_mvt(l_isikukood TEXT, l_kpv DATE DEFAULT current_date)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    TAHTAEG     DATE    = make_date((1959 + date_part('year', l_kpv) - 2023)::INTEGER, 7, 1); -- пляшем от 01.07.1959
    tuulemus    BOOLEAN = FALSE;
    l_sunnipaev DATE;
    l_aasta     INTEGER;
    l_kuu       INTEGER;
    l_paev      INTEGER;
BEGIN
    IF l_isikukood IS NULL OR l_isikukood = '' OR len(l_isikukood) < 7
    THEN
        RETURN FALSE;
    END IF;
    -- расчитываем день рождения
    -- aasta
    l_sunnipaev = palk.get_sunnipaev(l_isikukood);

    -- уточняем расчет срока наступления льготы

    IF l_aasta = 1958
    THEN
        TAHTAEG = make_date(1958, 04, 01);
    ELSIF l_aasta = 1959
    THEN
        TAHTAEG = make_date(1959, 07, 01);
    ELSIF l_aasta = 1960
    THEN
        TAHTAEG = make_date(1960, 10, 01);
    ELSIF l_aasta = 1961
    THEN
        TAHTAEG = make_date(1961, 12, 31);

    END IF;
    --    1958. aastal, siis on tema vanaduspensioniiga 64 aastat ja 3 kuud
--1959. aastal, siis 64 aastat ja 6 kuud
--1960. aastal, siis 64 aastat ja 9 kuud
--1961. aastal, siis 65 aastat
    raise notice 'l_sunnipaev %, TAHTAEG %',l_sunnipaev, TAHTAEG ;
    tuulemus = l_sunnipaev <= TAHTAEG;

    RETURN tuulemus;

END
$$;


GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE) TO dbvaatleja;


/*
SELECT palk.kas_soodustus_mvt('44701313718', '2023-01-01')::INTEGER -- -> 0
SELECT palk.kas_soodustus_mvt('37303023721', current_date)::INTEGER -- -> 0
*/