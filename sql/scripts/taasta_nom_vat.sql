DROP FUNCTION IF EXISTS taasta_nom();

CREATE FUNCTION taasta_nom()
    RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_nom RECORD;
BEGIN
    FOR v_nom IN
        SELECT l.changes -> 'properties' ->> 'vat' AS eelmine_vat,
               n.properties ->> 'vat'              AS vat,
               n.id
        FROM ou.logs l
                 INNER JOIN libs.nomenklatuur n ON n.id = l.doc_id
        WHERE propertis ->> 'table' = 'nomenklatuur'
          AND propertis ->> 'updated' = '2024-05-15T08:41:54.21478+00:00'
--          AND l.changes -> 'properties' ->> 'vat' <> '22'
          AND l.changes -> 'properties' ->> 'vat' IS NULL
          AND n.properties ->> 'vat' = '22'
        LOOP
            UPDATE libs.nomenklatuur
            SET properties = properties || jsonb_build_object('vat', NULL)
            WHERE id = v_nom.id;
        END LOOP;
    RETURN 1;

END ;
$$;

SELECT taasta_nom();

DROP FUNCTION IF EXISTS taasta_nom();

