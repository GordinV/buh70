--DROP FUNCTION IF EXISTS lapsed.get_viitenumber(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.get_viitenumber(IN rekv_id INTEGER, IN laps_id INTEGER, OUT viitenumber TEXT)
AS
$BODY$
DECLARE
    l_rekv_osa  TEXT    = lpad(rekv_id::TEXT, 3, '0');
    l_lapse_osa TEXT    = lpad(laps_id::TEXT, 6, '0');
    l_control   INTEGER;
    l_731       TEXT    = '137137137';
    l_multiple  INTEGER = 0;
    l_summa     INTEGER = 0;
    i           INTEGER = 1;
    l_saja      INTEGER; -- Lähim suurem kümnekordne (4)
BEGIN
    -- структура
    viitenumber = l_rekv_osa || l_lapse_osa;
    -- должна быть длина 9 знаков, если меняется необходимо пометь 731

    -- перемножаем в цикле
    FOR i IN 1 .. length(l_731)
        LOOP
            l_multiple = substring(viitenumber FROM i FOR 1)::INTEGER * substring(l_731 FROM i FOR 1)::INTEGER;
            l_summa = l_summa + l_multiple;
        END LOOP;

    -- arvestame Lähim suurem kümnekordne (4)
    l_saja = l_summa;
    WHILE right(l_saja::TEXT, 1) <> '0'
        LOOP
            l_saja = l_saja + 1;
        END LOOP;
    l_control = l_saja - l_summa;
    viitenumber = viitenumber || l_control::TEXT;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber(INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber(INTEGER, INTEGER) TO arvestaja;


SELECT lapsed.get_viitenumber(0, 804521)

