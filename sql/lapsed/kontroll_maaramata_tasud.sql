DROP FUNCTION IF EXISTS lapsed.kontroll_maaramata_tasud();

CREATE FUNCTION lapsed.kontroll_maaramata_tasud()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_mk RECORD;
BEGIN
    FOR v_mk IN
        SELECT d.id,
               d.rekvid,
               (SELECT id
                FROM ou.userid u
                WHERE u.rekvid = d.rekvid AND kasutaja = 'temp' AND u.status < 3
                LIMIT 1) AS user_id
        FROM docs.doc d
                 INNER JOIN docs.mk mk ON mk.parentid = d.id
                 INNER JOIN lapsed.liidestamine l ON l.docid = d.id
        WHERE mk.jaak <> 0
          AND kpv >= '2023-11-01'
          AND NOT exists(SELECT id FROM docs.arvtasu WHERE doc_tasu_id = d.id)
--          AND d.id = 5583924
        LOOP
            PERFORM docs.sp_loe_tasu(v_mk.id, v_mk.user_id);

        END LOOP;
    RETURN 1;

END;
$$;

--SELECT lapsed.kontroll_maaramata_tasud();

--DROP FUNCTION IF EXISTS lapsed.kontroll_maaramata_tasud();


