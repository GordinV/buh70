-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.update_eelarve_from_taotlus();

CREATE OR REPLACE FUNCTION docs.update_eelarve_from_taotlus()
    RETURNS INTEGER AS
$BODY$

DECLARE
    v_eelarve RECORD;
    l_count   INTEGER = 0;
BEGIN
    FOR v_eelarve IN
        SELECT e.muud AS e_muud, t.muud AS dok_muud, e.*
        FROM eelarve.taotlus t
                 INNER JOIN eelarve.taotlus1 t1 ON t1.parentid = t.id
                 INNER JOIN eelarve.eelarve e ON e.id = t1.eelarveid
        WHERE e.muud <> t.muud
          AND t.aasta = 2021
        LOOP
            UPDATE eelarve.eelarve
            SET muud = v_eelarve.dok_muud
            WHERE id = v_eelarve.id;
            l_count = l_count + 1;
        END LOOP;
    RETURN l_count;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


SELECT *
FROM docs.update_eelarve_from_taotlus();

DROP FUNCTION IF EXISTS docs.update_eelarve_from_taotlus();
