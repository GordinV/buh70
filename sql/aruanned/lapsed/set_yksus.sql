-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS set_yksus();

CREATE OR REPLACE FUNCTION set_yksus()
    RETURNS BOOLEAN AS
$BODY$

DECLARE
    tulemus BOOLEAN = FALSE;
    v_arv   RECORD;
    l_yksus text;
BEGIN
    FOR v_arv IN
        SELECT a.parentid as id, a.properties->>'viitenr' as viitenr, a1.id as a1_id
        FROM docs.arv a
                 INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
        WHERE rekvid = 85
          AND kpv = date(2020, 08, 31)
          AND a1.properties ->> 'yksus' IS NULL
        LOOP
            l_yksus = (select (SELECT lk.properties ->> 'yksus'
                               FROM lapsed.lapse_kaart lk
                               WHERE lk.parentid = l.parentid
                                 AND lk.staatus <> 3
                               ORDER BY id DESC
                               LIMIT 1) AS yksus
                       FROM docs.arv a
                                INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                                INNER JOIN lapsed.liidestamine l ON l.docid = a.parentid
                       WHERE a.parentid = v_arv.id);
            raise notice 'yksys %, v_arv.id %, v_arv.viitenr %', l_yksus, v_arv.id, v_arv.viitenr;
            update docs.arv1 set properties = properties::jsonb || ('{"yksus":"' || l_yksus || '"}')::jsonb
                where id = v_arv.a1_id;
        END LOOP;

    RETURN tulemus;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

--select set_yksus();