CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_viitenr(data JSONB,
                                                      userid INTEGER,
                                                      user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName        TEXT;
    doc_data        JSON    = data ->> 'data';
    doc_id          INTEGER = doc_data ->> 'id';
    doc_laps_id     INTEGER = doc_data ->> 'laps_id';
    doc_viitenumber TEXT    = doc_data ->> 'viitenumber';
    l_isikukood     TEXT    = (SELECT isikukood
                               FROM lapsed.laps
                               WHERE id = doc_laps_id
                                 AND staatus <> 3
                               LIMIT 1);
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    IF doc_viitenumber IS NULL OR l_isikukood IS NULL
    THEN

    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO lapsed.viitenr (isikukood, rekv_id, viitenumber)
        VALUES (l_isikukood, user_rekvid, doc_viitenumber) RETURNING id
            INTO doc_id;

    ELSE
        if not exists (select id from lapsed.viitenr where id = doc_id and rekv_id = user_rekvid) then
            RAISE exception 'Puudub õigused %', user;
        END IF;

        UPDATE lapsed.viitenr
        SET viitenumber = doc_viitenumber,
            isikukood   = l_isikukood
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

    RETURN doc_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_viitenr(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select lapsed.sp_salvesta_viitenr('{"data":{"id":0,"parentid":7,"asutusid":31825,"arved":"jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id
select lapsed.sp_salvesta_vanem('{"data":{"id":2,"parentid":1,"asutusid":1621,"arved":"Jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/