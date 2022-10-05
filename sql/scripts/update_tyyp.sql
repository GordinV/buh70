DROP FUNCTION IF EXISTS lapsed.update_tyyp();

CREATE FUNCTION lapsed.update_tyyp()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_tyyp    RECORD;
    l_tyyp_id INTEGER;
BEGIN
    FOR v_tyyp IN
        SELECT id, kood, rekvid, l.properties::JSONB ->> 'tyyp' AS tyyp
        FROM libs.library l
        WHERE l.library = 'LAPSE_GRUPP'
          AND l.status < 3
          AND NOT empty(kood)
          AND l.properties::JSONB ->> 'tyyp' IS NULL
        LOOP
            l_tyyp_id = (SELECT id
                         FROM libs.library
                         WHERE library.library = 'KOOLITUSE_TYYP'
                           AND rekvid = v_tyyp.rekvid
                           AND ltrim(rtrim(kood)) = left(v_tyyp.kood, 8)
                           AND status < 3
                         LIMIT 1
            );

            RAISE NOTICE 'tyyp %, l_tyyp_id %', v_tyyp.kood, l_tyyp_id;

            IF l_tyyp_id IS NOT NULL
            THEN
                UPDATE libs.library
                SET properties = properties::JSONB || jsonb_build_object('tyyp', l_tyyp_id)
                WHERE id = v_tyyp.id;
            END IF;


        END LOOP;
    RETURN 1;

END;
$$;

SELECT lapsed.update_tyyp();

DROP FUNCTION IF EXISTS lapsed.update_tyyp();


