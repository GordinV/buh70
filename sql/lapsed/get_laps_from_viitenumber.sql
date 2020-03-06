DROP FUNCTION IF EXISTS lapsed.get_laps_from_viitenumber(TEXT);

CREATE OR REPLACE FUNCTION lapsed.get_laps_from_viitenumber(IN viitenr TEXT, OUT laps_id INTEGER)
AS
$BODY$
BEGIN
    IF laps_id IS NULL AND exists(SELECT id FROM ou.rekv WHERE id = left(viitenr, 3)::INTEGER)
    THEN
        -- получим ид ребенка
        -- 0710055785
        SELECT id INTO laps_id FROM lapsed.laps WHERE id = left(right(viitenr::TEXT, 7), 6)::INTEGER;
    END IF;

    IF laps_id IS NULL
    THEN
        -- ищем в старых
        SELECT l.id AS laps_id INTO laps_id
        FROM lapsed.viitenr v
                 INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
        WHERE v.viitenumber = viitenr
        LIMIT 1;
    END IF;

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.get_laps_from_viitenumber(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_laps_from_viitenumber(TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_laps_from_viitenumber(TEXT) TO arvestaja;


SELECT lapsed.get_laps_from_viitenumber('0630000412');

