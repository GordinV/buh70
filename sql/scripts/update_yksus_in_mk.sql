DROP FUNCTION IF EXISTS update_yksus_in_mk();

CREATE FUNCTION update_yksus_in_mk()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_mk    RECORD;
    l_yksus TEXT;
BEGIN
    /*    FOR v_mk IN
            SELECT mk.parentid, l.parentid AS isik_id
            FROM docs.mk mk
                     INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
            LOOP
                l_yksus = (SELECT properties ->> 'yksus'
                           FROM lapsed.lapse_kaart
                           WHERE parentid = v_mk.isik_id
                             AND staatus < 3
                           ORDER BY (properties ->> 'lopp_kpv')::DATE DESC
                           LIMIT 1);

                UPDATE docs.mk
                SET properties = coalesce(properties, '{}'::JSONB) || jsonb_build_object('yksus', l_yksus)
                WHERE parentid = v_mk.parentid;
            END LOOP;
    */
    FOR v_mk IN
        SELECT
               mk.id, l.parentid as laps_id, mk.rekvid
        FROM docs.mk mk
                 INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
        WHERE mk.properties->>'yksus' is not null

        LOOP
            l_yksus = (SELECT properties ->> 'yksus'
             FROM lapsed.lapse_kaart
             WHERE parentid = v_mk.laps_id
               AND staatus < 3
               AND rekvid = v_mk.rekvid
             ORDER BY id
             LIMIT 1);

            UPDATE docs.mk
            SET properties = properties || jsonb_build_object('yksus', l_yksus)
            WHERE id = v_mk.id;
        END LOOP;

    RETURN 1;
END;

$$;

SELECT update_yksus_in_mk();

DROP FUNCTION IF EXISTS update_yksus_in_mk();;

