DROP FUNCTION IF EXISTS lapsed.set_ko_aa();

CREATE FUNCTION lapsed.set_ko_aa()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_pv RECORD;
BEGIN
    FOR v_pv IN
        SELECT aa.arve,
               pv.aa,
               mk.aaid,
               mk.rekvid,
               (SELECT id FROM ou.aa WHERE aa.parentid = mk.rekvid AND arve = 'EE712200221023241719' LIMIT 1) AS aa_id,
               mk.id
        FROM lapsed.pank_vv pv
                 INNER JOIN docs.mk mk ON mk.parentid = pv.doc_id
                 INNER JOIN ou.aa aa ON aa.id = mk.aaid
        WHERE pv.aa = 'EE712200221023241719'
        LOOP
            -- update
            UPDATE docs.mk
            SET aaid = v_pv.aa_id
            WHERE id = v_pv.id;
        END LOOP;
    RETURN 1;

END;
$$;

SELECT lapsed.set_ko_aa();

DROP FUNCTION IF EXISTS lapsed.set_ko_aa();


