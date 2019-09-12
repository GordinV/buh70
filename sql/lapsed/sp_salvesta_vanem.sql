CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_vanem(data JSONB,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName      TEXT;
    doc_data      JSON    = data ->> 'data';
    doc_id        INTEGER = doc_data ->> 'id';
    doc_parentid  INTEGER = doc_data ->> 'parentid';
    doc_asutusid  INTEGER = doc_data ->> 'asutusid';
    doc_arved     TEXT    = doc_data ->> 'arved';
    doc_suhtumine TEXT    = doc_data ->> 'suhtumine';
    doc_muud      TEXT    = doc_data ->> 'muud';
    json_props    JSONB;
    json_ajalugu  JSONB;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;
    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;


    json_props = to_jsonb(row)
                 FROM (SELECT doc_arved AS arved, doc_suhtumine AS suhtumine) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.vanemad (parentid, asutusid, muud, properties, ajalugu)
        VALUES (doc_parentid, doc_asutusid, doc_muud, json_props, '[]' :: JSONB || json_ajalugu) RETURNING id
            INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    l.*      AS data
                             FROM lapsed.vanemad l
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.vanemad
        SET asutusid   = doc_asutusid,
            properties = coalesce(properties,'{}'::jsonb)::jsonb || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_vanem(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select lapsed.sp_salvesta_vanem('{"data":{"id":0,"parentid":7,"asutusid":31825,"arved":"jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id
select lapsed.sp_salvesta_vanem('{"data":{"id":2,"parentid":1,"asutusid":1621,"arved":"Jah","muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/