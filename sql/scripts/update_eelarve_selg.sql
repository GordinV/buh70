DROP FUNCTION IF EXISTS eelarve.update_eelarve_selg();

CREATE FUNCTION eelarve.update_eelarve_selg()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    eelarve_ RECORD;
BEGIN
    FOR eelarve_ IN
        SELECT t1.selg,
               t.muud,
               e.id
        FROM eelarve.eelarve e
                 INNER JOIN eelarve.taotlus1 t1 ON t1.eelarveid = e.id
                 INNER JOIN eelarve.taotlus t ON t.id = t1.parentid
        WHERE t.aasta = 2021
    --              e.muud IS NULL
--           OR empty(e.muud)
--            AND
        LOOP
            UPDATE eelarve.eelarve SET muud = eelarve_.muud WHERE id = eelarve_.id;
        END LOOP;
    RETURN 1;

END;
$$;

SELECT eelarve.update_eelarve_selg();

DROP FUNCTION IF EXISTS eelarve.update_eelarve_selg();
