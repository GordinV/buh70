DROP FUNCTION IF EXISTS lapsed.set_kov();

CREATE FUNCTION lapsed.set_kov()
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
        SELECT DISTINCT v.parentid AS laps_id
                        --, (a.properties->>'kas_teiste_kov')::BOOLEAN
        FROM lapsed.vanemad v
                 INNER JOIN libs.asutus a ON a.id = v.asutusid
        WHERE v.staatus <> 3
          AND (a.properties ->> 'kas_teiste_kov')::BOOLEAN

        LOOP

            UPDATE lapsed.laps
            SET properties = properties || jsonb_build_object('kas_teiste_kov', TRUE)
            WHERE id = v_kaart.laps_id
              AND staatus < 3;

            l_count = l_count + 1;

            IF l_count > 0
            THEN
                RAISE NOTICE 'Updated total: l_count %', l_count;
            END IF;
        END LOOP;
    RETURN l_count;

END ;
$$;

SELECT lapsed.set_kov();

DROP FUNCTION IF EXISTS lapsed.set_kov();

