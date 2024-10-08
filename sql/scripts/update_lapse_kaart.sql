DROP FUNCTION IF EXISTS lapsed.update_viitenumber_lapse_kaart();

CREATE FUNCTION lapsed.update_viitenumber_lapse_kaart()
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
          AND rekvid <> 92
          AND lk.properties ->> 'viitenr' IS NULL
    /*          AND exists(SELECT v.id
                         FROM lapsed.viitenr v
                                  INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood
                         WHERE l.id = lk.parentid)
    */
--          AND lk.parentid = 7367
        LOOP

            IF (SELECT count(v.id)
                FROM lapsed.viitenr v
                         INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood AND v.rekv_id = v_kaart.rekvid
                WHERE l.id = v_kaart.parentid) = 1
            THEN

                SELECT v.viitenumber
                INTO l_vn
                FROM lapsed.viitenr v
                         INNER JOIN lapsed.laps l ON l.isikukood = v.isikukood AND v.rekv_id = v_kaart.rekvid
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


            END IF;


            IF l_count > 0
            THEN
                RAISE NOTICE 'Updated total: l_count %', l_count;
            END IF;
        END LOOP;
    RETURN l_count;

END ;
$$;

SELECT lapsed.update_viitenumber_lapse_kaart();

DROP FUNCTION IF EXISTS lapsed.update_viitenumber_lapse_kaart();

