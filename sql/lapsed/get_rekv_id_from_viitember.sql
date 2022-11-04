DROP FUNCTION IF EXISTS lapsed.get_rekv_id_from_viitenumber(TEXT);

CREATE OR REPLACE FUNCTION lapsed.get_rekv_id_from_viitenumber(IN viitenr TEXT, OUT rekv_id INTEGER)
AS
$BODY$
DECLARE
    viitenumber TEXT = viitenr;
BEGIN
    IF public.len(viitenr) < 10
    THEN
        -- старый номер
        viitenumber = lapsed.get_viitenumber_from_old(viitenr);
    END IF;
    rekv_id = (select id from ou.rekv where id = left(viitenumber, 3)::INTEGER limit 1);

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.get_rekv_id_from_viitenumber(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_rekv_id_from_viitenumber(TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_rekv_id_from_viitenumber(TEXT) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION lapsed.get_rekv_id_from_viitenumber(TEXT) TO arvestaja;


/*SELECT lapsed.get_rekv_id_from_viitenumber('1010096511');
*/
