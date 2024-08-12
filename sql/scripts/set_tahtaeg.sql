DROP FUNCTION IF EXISTS lapsed.set_tahtaeg();

CREATE FUNCTION lapsed.set_tahtaeg()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_arved RECORD;
    l_count INTEGER = 0;
    v_arv   RECORD;
    l_tahtaeg date;
BEGIN

    FOR v_arved IN
        SELECT a.id,
               to_jsonb(a.properties -> 'doc_kreedit_arved') AS arved
        FROM docs.arv a
--                 INNER JOIN lapsed.liidestamine l ON a.parentid = l.docid
        WHERE a.rekvid = 9
          AND a.tahtaeg >= '2024-06-30'
        LOOP
            SELECT a.id, (a.properties->'alus_arve_id')::INTEGER as alus_arve_id
            INTO v_arv
            FROM docs.arv a
            WHERE a.parentid IN (
                SELECT jsonb_array_elements(v_arved.arved::JSONB)::INTEGER
            );
            RAISE NOTICE 'v_arv %', v_arv;

            select tahtaeg into l_tahtaeg
            from docs.arv
            where parentid = v_arv.alus_arve_id;

            raise notice 'l_taht %', l_tahtaeg;

            update docs.arv set tahtaeg = l_tahtaeg
            where rekvid = 9 and id = v_arved.id
            and tahtaeg > l_tahtaeg;

        END LOOP;
    RETURN l_count;
END;
$$;

SELECT lapsed.set_tahtaeg();

DROP FUNCTION IF EXISTS lapsed.set_tahtaeg();

