DROP TRIGGER IF EXISTS trigu_nomenklatuur_after_logger
    ON libs.nomenklatuur CASCADE;

DROP FUNCTION IF EXISTS lapsed.trigu_nomenklatuur_after_logger();

CREATE  FUNCTION libs.trigu_nomenklatuur_after_logger()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    json_new         JSONB = to_jsonb(new.*);
    json_old         JSONB = to_jsonb(old.*);
    json_differances JSONB;
    json_props       JSONB;
    l_user_id        INTEGER;
BEGIN
    json_differances = public.jsonb_diff(json_old::JSONB, json_new::JSONB);
    json_differances = json_differances - 'ajalugu';
    json_differances = json_differances - 'timestamp';

    SELECT to_jsonb(row)
    INTO json_props
    FROM (SELECT now()     AS updated,
                 'nomenklatuur' AS table) row;

    l_user_id = (select id from ou.userid where userid.rekvid = coalesce(old.rekvid,0) and kasutaja = current_user and userid.status < 3);
    if (l_user_id is null) then
        l_user_id = (select id from ou.userid where kasutaja = current_user and status < 3 order by last_login desc limit 1);
    END IF;


    IF json_differances IS NOT NULL AND json_differances::TEXT <> '{}'
    THEN
        INSERT INTO ou.logs (rekvid, user_id, doc_id, propertis, changes)
        VALUES (0, l_user_id, old.id, json_props, json_differances);
    END IF;


    RETURN NULL;

END;
$$;

CREATE TRIGGER trigu_nomenklatuur_after_logger
    AFTER UPDATE
    ON libs.nomenklatuur
    FOR EACH ROW
EXECUTE PROCEDURE libs.trigu_nomenklatuur_after_logger();
