DROP FUNCTION IF EXISTS ou.store_user_uuid(JSONB);

CREATE OR REPLACE FUNCTION ou.store_user_uuid(data JSONB)
    RETURNS INTEGER AS
$BODY$


DECLARE
    l_uuid      TEXT    = data ->> 'uuid';
    l_userId    INTEGER = data ->> 'userId';
    l_asutusId  INTEGER = data ->> 'asutusId';
    l_user_data JSONB   = data ->> 'user_data';

    v_asutus    RECORD;
    l_id        INTEGER;

BEGIN
    -- удаляем "старые сессии"
    DELETE
    FROM ou.session_uuid
    WHERE timestamp::DATE < current_date
       OR uuid = l_uuid;

    SELECT * INTO v_asutus FROM ou.rekv WHERE id = l_asutusId LIMIT 1;

    INSERT INTO ou.session_uuid (userid, asutusid, uuid, user_data)
    VALUES (l_userId, l_asutusId, l_uuid, l_user_data) RETURNING id
        INTO l_id;
    RETURN l_id;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.store_user_uuid(JSONB) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.store_user_uuid(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.store_user_uuid(JSONB) TO dbpeakasutaja;

