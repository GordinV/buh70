DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapsed(JSONB, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.sp_salvesta_laps(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_laps(data JSONB,
                                                   userid INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName         TEXT;
    doc_data         JSON    = data ->> 'data';
    doc_id           INTEGER = doc_data ->> 'id';
    doc_isikukood    TEXT    = doc_data ->> 'isikukood';
    doc_nimi         TEXT    = doc_data ->> 'nimi';
    doc_viitenr      TEXT    = doc_data ->> 'viitenumber';
    doc_vanemId      INTEGER = doc_data ->> 'vanemid';
    doc_muud         TEXT    = doc_data ->> 'muud';
    is_import        BOOLEAN = coalesce((doc_data ->> 'import')::BOOLEAN, FALSE);
    v_vanem          RECORD;
    json_props       JSONB;
    json_props_vanem JSONB;
    json_ajalugu     JSONB;
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
                 FROM (SELECT doc_viitenr AS viitenumber) row;


    -- поиск на наличие в регистре
    doc_id = (SELECT id FROM lapsed.laps l WHERE l.isikukood = doc_isikukood LIMIT 1);
    IF doc_id IS NOT NULL AND is_import = TRUE
    THEN
        RETURN 0;
    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.laps (isikukood, nimi, muud, properties, ajalugu)
        VALUES (doc_isikukood, doc_nimi, doc_muud, json_props, '[]' :: JSONB || json_ajalugu) RETURNING id
            INTO doc_id;


        IF doc_id > 0 AND doc_vanemId IS NOT NULL
        THEN
            -- will save parents

            SELECT 0                          AS id,
                   doc_id                     AS parentid,
                   asutusId,
                   properties ->> 'arved'     AS arved,
                   properties ->> 'suhtumine' AS suhtumine
                   INTO v_vanem
            FROM lapsed.vanemad v
            WHERE id = doc_vanemId;

            json_props_vanem = to_jsonb(row)
                               FROM (SELECT v_vanem AS data) row;

            PERFORM lapsed.sp_salvesta_vanem(json_props_vanem::JSONB, userid::INTEGER, user_rekvid::INTEGER) AS id;


        END IF;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user
                            ) row;

        UPDATE lapsed.laps
        SET isikukood  = doc_isikukood,
            nimi       = doc_nimi,
            properties = properties || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus    = CASE WHEN staatus = 3 THEN 1 ELSE staatus END
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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_laps(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select lapsed.sp_salvesta_laps('{"data":{"id":0,"isikukood":"1178901234456","nimi":"Lasp 17","viitenumber":null,"muud":"test 17","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/