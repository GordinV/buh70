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
    TAHTAEG     DATE    = make_date((1959 + date_part('year', l_kpv) - 2023)::INTEGER, 7, 1); -- пляшем от 01.07.1959
    tuulemus    BOOLEAN = FALSE;
    l_tahtaeg   INTERVAL;
    l_sunnipaev DATE;
    l_aasta     INTEGER;
    l_age       INTERVAL;
    l_kuu       INTEGER;
    l_paev      INTEGER;
    l_kasutav_kpv date = make_date(year(l_kpv), 12, 31);
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
        l_tahtaeg = age(l_kasutav_kpv::TIMESTAMP, l_sunnipaev::TIMESTAMP);
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
    RAISE NOTICE 'l_sunnipaev %, l_kasutav_kpv %, l_age %, l_tahtaeg %',l_sunnipaev, l_kasutav_kpv , l_age, l_tahtaeg;
/*    select age( l_kpv::timestamp, l_sunnipaev::timestamp), make_interval(years => 64, months =>9),
           age( now(), '1960-04-19'::timestamp)< make_interval(years => 64, months =>9)

*/
    tuulemus = l_age::INTERVAL > l_tahtaeg::INTERVAL;
/*    IF l_soodustus
    THEN
        -- право на применении необлагаемого миниума (29.01.2024)
        IF extract(YEAR FROM l_age) >= 64
        THEN
            -- т.е. пенсионер с этого года
            tuulemus = 1;
        END IF;
    END IF;
*/
    RETURN tuulemus;

END
$$;


GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.kas_soodustus_mvt(TEXT, DATE, BOOLEAN) TO dbvaatleja;

--SELECT palk.kas_soodustus_mvt('45909123717', '2024-06-30'::date)::INTEGER
-- -> 0

/*
SELECT palk.kas_soodustus_mvt_('45909123717', '2024-01-01')::INTEGER -- -> 0
SELECT palk.kas_soodustus_mvt('46004193738', current_date)::INTEGER -- -> 0
*/