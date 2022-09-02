DROP FUNCTION IF EXISTS update_soodus_lopp();

CREATE FUNCTION update_soodus_lopp()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_kaart       RECORD;
    l_count_kaart INTEGER = 0;
BEGIN
    FOR v_kaart IN
        SELECT DISTINCT id,
                        parentid                  AS laps_id,
                        properties ->> 'lopp_kpv' AS lopp_kpv,
                        properties ->> 'sooduse_lopp'
        FROM lapsed.lapse_kaart lk
        WHERE (properties ->> 'sooduse_lopp') IS NOT NULL
          AND (properties ->> 'sooduse_lopp')::DATE > (properties ->> 'lopp_kpv')::DATE
          AND staatus < 3
        LOOP
            RAISE NOTICE 'found  %', v_kaart;
            UPDATE lapsed.lapse_kaart
            SET properties = properties::JSONB || jsonb_build_object('sooduse_lopp', v_kaart.lopp_kpv)
            WHERE id = v_kaart.id;

            l_count_kaart = l_count_kaart + 1;
        END LOOP;


    RETURN l_count_kaart;
END;

$$;

SELECT update_soodus_lopp();

DROP FUNCTION IF EXISTS update_soodus_lopp();;

