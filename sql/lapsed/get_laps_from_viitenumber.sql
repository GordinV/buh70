DROP FUNCTION IF EXISTS lapsed.get_laps_from_viitenumber(TEXT);

CREATE OR REPLACE FUNCTION lapsed.get_laps_from_viitenumber(IN viitenr TEXT, OUT laps_id INTEGER)
AS
$BODY$
DECLARE
    l_rekv_id INTEGER;
BEGIN
    l_rekv_id = lapsed.get_rekv_id_from_viitenumber(viitenr);

    IF laps_id IS NULL
    THEN
        -- получим ид ребенка
        -- 0710055785
        SELECT id
        INTO laps_id
        FROM lapsed.laps
        WHERE id = public.left(right(viitenr::TEXT, 7), 6)::INTEGER;
    END IF;

    IF laps_id IS NULL
    THEN
        -- ищем в старых
        SELECT l.id AS laps_id
        INTO laps_id
        FROM lapsed.viitenr v
                 INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
        WHERE v.viitenumber = viitenr
        LIMIT 1;
    END IF;

    IF len(ltrim(rtrim(viitenr))::TEXT) > 10
    THEN
        RAISE NOTICE 'VN > 10';
        laps_id = NULL;
    END IF;

    IF laps_id IS NOT NULL
    THEN
        -- если нет услуг в учреждении, то обнуляем


        IF NOT exists(
                SELECT id
                FROM lapsed.lapse_kaart
                WHERE parentid = laps_id
                  AND staatus < 3
                  AND rekvid = l_rekv_id
            )
        THEN
            RAISE NOTICE 'Puudub teenused l_rekv_id %, laps_id %', l_rekv_id, laps_id;
            laps_id = NULL;
        END IF;

    END IF;

    RETURN;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.get_laps_from_viitenumber(TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_laps_from_viitenumber(TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.get_laps_from_viitenumber(TEXT) TO arvestaja;


SELECT lapsed.get_laps_from_viitenumber('1000000030');
/*
SELECT *
FROM lapsed.laps
WHERE id = 3
SELECT *
FROM lapsed.lapse_kaart
WHERE parentid = 3*/