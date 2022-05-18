DROP FUNCTION IF EXISTS lapsed.update_lapse_kaart();

CREATE FUNCTION lapsed.update_lapse_kaart()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_kaart RECORD;
    l_vn    TEXT;
    l_count INTEGER = 0;
BEGIN
    FOR v_kaart IN
        SELECT *
        FROM lapsed.lapse_kaart lk
        WHERE lk.staatus <> 3
          AND exists(SELECT v.id
                     FROM lapsed.viitenr v
                              INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
                     WHERE l.id = lk.parentid)
--        and lk.id = 21623
        LOOP

            SELECT v.viitenumber
            INTO l_vn
            FROM lapsed.viitenr v
                     INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
            WHERE l.id = v_kaart.parentid
            ORDER BY v.id DESC
            LIMIT 1;

            IF l_vn IS NOT NULL
            THEN
                UPDATE lapsed.lapse_kaart
                SET properties = properties || ('{"viitenr": "' || l_vn || '"}')::JSONB
                WHERE id = v_kaart.id;

                l_count = l_count + 1;

            END IF;

            IF l_count > 0
            THEN
                RAISE NOTICE 'Deleted total: l_count %', l_count;
            END IF;
        END LOOP;
    RETURN l_count;

END ;
$$;

SELECT lapsed.update_lapse_kaart();

DROP FUNCTION IF EXISTS lapsed.update_lapse_kaart();

