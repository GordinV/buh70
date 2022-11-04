DROP TRIGGER IF EXISTS trigU_laps_after
    ON lapsed.laps CASCADE;

DROP FUNCTION IF EXISTS lapsed.trigu_laps_after_logger();

CREATE FUNCTION lapsed.trigu_laps_after_logger()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    json_new         JSONB = to_jsonb(new.*);
    json_old         JSONB = to_jsonb(old.*);
    json_differances JSONB;
    json_props       JSONB;
BEGIN
    json_differances = public.jsonb_diff(json_old::JSONB, json_new::JSONB);
    json_differances = json_differances - 'ajalugu';
    json_differances = json_differances - 'timestamp';

    SELECT to_jsonb(row)
    INTO json_props
    FROM (SELECT now()  AS updated,
                 'laps' AS table) row;


    IF json_differances IS NOT NULL and json_differances::text <> '{}'
    THEN
        INSERT INTO ou.logs (rekvid, user_id, doc_id, propertis, changes)
        VALUES (0, 0, old.id, json_props, json_differances);
    END IF;


    RETURN NULL;

END;
$$;

CREATE TRIGGER trigU_laps_after
    AFTER UPDATE
    ON lapsed.laps
    FOR EACH ROW
EXECUTE PROCEDURE lapsed.trigu_laps_after_logger();
