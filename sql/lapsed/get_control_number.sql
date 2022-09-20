--DROP FUNCTION IF EXISTS lapsed.get_viitenumber(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.get_control_number(IN code text , OUT viitenumber TEXT)
AS
$BODY$
DECLARE
    l_control   INTEGER;
    l_multiple  INTEGER = 0;
    l_summa     INTEGER = 0;
    i           INTEGER = 1;
    l_saja      INTEGER; -- Lähim suurem kümnekordne (4)
    l_len integer = len(code);
    l_731       TEXT    = case when l_len = 4 then '7137' when l_len = 5 then '37137' when l_len = 6 then '137137' when l_len = 7 then '7137137' when l_len = 8 then '37137137' end;

BEGIN
    raise notice 'start';
    -- структура
    viitenumber = code;
    -- должна быть длина 9 знаков, если меняется необходимо пометь 731
    raise notice 'viitenumber %',viitenumber;

    -- перемножаем в цикле
    FOR i IN 1 .. length(l_731)
        LOOP
            l_multiple = substring(viitenumber FROM i FOR 1)::INTEGER * substring(l_731 FROM i FOR 1)::INTEGER;
            raise notice 'l_multiple %',l_multiple;

            l_summa = l_summa + l_multiple;
            raise notice 'l_summa %, i %',l_summa, i;
        END LOOP;
    raise notice 'lopp l_summa %',l_summa;

    -- arvestame Lähim suurem kümnekordne (4)
    l_saja = l_summa;
    raise notice 'l_saja %',l_saja;

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

GRANT EXECUTE ON FUNCTION lapsed.get_control_number(text) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_control_number(text) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_control_number(text) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_control_number(text) TO arvestaja;


SELECT lapsed.get_control_number('1000011')

