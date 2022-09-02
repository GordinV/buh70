DROP TRIGGER IF EXISTS trigu_lapse_kaart_after_logger
    ON lapsed.lapse_kaart CASCADE;

DROP FUNCTION IF EXISTS lapsed.trigu_lapse_kaart_after_logger();

CREATE FUNCTION lapsed.trigu_lapse_kaart_after_logger()
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
    json_differances = jsonb_diff(json_old::JSONB, json_new::JSONB);
    json_differances = json_differances - 'ajalugu';
    json_differances = json_differances - 'timestamp';

    SELECT to_jsonb(row)
    INTO json_props
    FROM (SELECT now()  AS updated,
                 'lapse_kaart' AS table) row;


    IF (json_differances ) IS NOT NULL
    THEN
        INSERT INTO ou.logs (rekvid, user_id, doc_id, propertis, changes)
        VALUES (0, 0, old.id, json_props, json_differances);
    END IF;


    RETURN NULL;

END;
$$;

CREATE TRIGGER trigu_lapse_kaart_after_logger
    AFTER UPDATE
    ON lapsed.lapse_kaart
    FOR EACH ROW
EXECUTE PROCEDURE lapsed.trigu_lapse_kaart_after_logger();
