DROP FUNCTION IF EXISTS palk.kas_soodustus_mvt(INTEGER, DATE);
DROP FUNCTION IF EXISTS palk.kas_soodustus_mvt(TEXT, DATE);
DROP FUNCTION IF EXISTS palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN);

CREATE FUNCTION palk.kas_soodustus_mvt(l_isikukood TEXT, l_kpv DATE DEFAULT current_date,
                                       l_soodustus BOOLEAN DEFAULT FALSE)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    tuulemus      BOOLEAN = FALSE;
    l_tahtaeg     INTERVAL;
    l_sunnipaev   DATE;
    l_aasta       INTEGER;
    l_age         INTERVAL;
    l_kasutav_kpv date    = make_date(year(l_kpv), 12, 31);
BEGIN
    IF l_isikukood IS NULL OR l_isikukood = '' OR len(l_isikukood) < 7
    THEN
        RETURN FALSE;
    END IF;

    -- расчитываем день рождения
    -- aasta
    l_sunnipaev = palk.get_sunnipaev(l_isikukood);
    l_aasta = year(l_sunnipaev);
    -- уточняем расчет срока наступления льготы

    IF l_aasta = 1958
    THEN
        l_tahtaeg = make_interval(years => 64, months =>3);
    ELSIF l_aasta = 1956
    THEN
        l_tahtaeg = make_interval(years => 63, months =>9);
    ELSIF l_aasta = 1957
    THEN
        l_tahtaeg = make_interval(years => 64);
    ELSIF l_aasta = 1959
    THEN
        l_tahtaeg = make_interval(years => 64, months =>6);
    ELSIF l_aasta = 1960
    THEN
        l_tahtaeg = make_interval(years => 64, months =>9);
    ELSE
        l_tahtaeg = make_interval(years => 65);

        --        l_tahtaeg = age(l_kasutav_kpv::TIMESTAMP, l_sunnipaev::TIMESTAMP);
    END IF;

    IF l_aasta < 1956
    THEN
        l_tahtaeg = make_interval(years => 65);
    END IF;
    l_age = age(l_kasutav_kpv::TIMESTAMP, l_sunnipaev::TIMESTAMP);
    --    1958. aastal, siis on tema vanaduspensioniiga 64 aastat ja 3 kuud
--1959. aastal, siis 64 aastat ja 6 kuud
--1960. aastal, siis 64 aastat ja 9 kuud
--1961. aastal, siis 65 aastat

    tuulemus = l_age::INTERVAL > l_tahtaeg::INTERVAL;

    RETURN tuulemus;

END
$$;


GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbvaatleja;

--
SELECT palk.kas_soodustus_mvt('46102213714', '2024-01-06'::date)::INTEGER
-- -> 0

/*
SELECT palk.kas_soodustus_mvt('45909123717', '2024-01-01')::INTEGER -- -> 0
SELECT palk.kas_soodustus_mvt('46004193738', current_date)::INTEGER -- -> 0
*/