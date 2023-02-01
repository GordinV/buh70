DROP FUNCTION IF EXISTS set_yksus_to_mk();

CREATE FUNCTION set_yksus_to_mk()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_mk    RECORD;
    l_yksus TEXT;
BEGIN
    FOR v_mk IN
        SELECT mk.parentid, l.parentid AS isik_id, rekvid
        FROM docs.mk mk
                 INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
        LOOP
            l_yksus = (SELECT properties ->> 'yksus'
                       FROM lapsed.lapse_kaart
                       WHERE parentid = v_mk.isik_id
                         AND rekvid = v_mk.rekvid
                         AND staatus < 3
                       ORDER BY (properties ->> 'lopp_kpv')::DATE DESC
                       LIMIT 1);

            UPDATE docs.mk
            SET properties = coalesce(properties, '{}'::JSONB) || jsonb_build_object('yksus', l_yksus)
            WHERE parentid = v_mk.parentid;
        END LOOP;

/*    FOR v_mk IN
        SELECT coalesce(n.properties ->> 'tunnus', '')   AS tunnus,
               coalesce(n.properties ->> 'tegev', '')    AS tegev,
               coalesce(n.properties ->> 'konto', '')    AS konto,
               coalesce(n.properties ->> 'artikkel', '') AS artikkel,
               coalesce(n.properties ->> 'allikas', '')  AS allikas,
               mk1.id                                    AS mk1_id
        FROM docs.mk1 mk1
                 INNER JOIN docs.mk mk ON mk.id = mk1.parentid
                 INNER JOIN lapsed.liidestamine l ON l.docid = mk.parentid
                 INNER JOIN libs.nomenklatuur n ON n.id = mk1.nomid
        WHERE mk1.kood1 IS NULL
        LOOP
            UPDATE docs.mk1
            SET kood1  = v_mk.tegev,
                kood2  = v_mk.allikas,
                kood3  = v_mk.artikkel,
                tunnus = v_mk.tunnus
            WHERE id = v_mk.mk1_id;
        END LOOP;

*/ RETURN 1;
END;

$$;

SELECT set_yksus_to_mk();

DROP FUNCTION IF EXISTS set_yksus_to_mk();;

