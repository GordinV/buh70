DROP FUNCTION IF EXISTS lapsed.get_viitenumber_from_old(TEXT);

CREATE OR REPLACE FUNCTION lapsed.get_viitenumber_from_old(IN old_viitenr TEXT, OUT viitenumber TEXT)
AS
$BODY$
DECLARE
    laps_id INTEGER;
    rekv_id INTEGER;
BEGIN
    SELECT v.rekv_id,
           l.id AS laps_id
           INTO rekv_id, laps_id
    FROM lapsed.viitenr v
             INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
    WHERE v.viitenumber = old_viitenr
    LIMIT 1;

    viitenumber = lapsed.get_viitenumber(rekv_id, laps_id);
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber_from_old(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber_from_old(TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber_from_old(TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_viitenumber_from_old(TEXT) TO arvestaja;


SELECT lapsed.get_viitenumber_from_old('1010096511');

