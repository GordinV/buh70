CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_vanem(data JSONB,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName         TEXT;
    doc_data         JSON    = data ->> 'data';
    doc_id           INTEGER = doc_data ->> 'id';
    doc_parentid     INTEGER = doc_data ->> 'parentid';
    doc_asutusid     INTEGER = doc_data ->> 'asutusid';
    doc_arved        BOOLEAN = coalesce((doc_data ->> 'arved')::BOOLEAN, FALSE);
    doc_suhtumine    TEXT    = doc_data ->> 'suhtumine';
    doc_kas_paberil  BOOLEAN = coalesce((doc_data ->> 'kas_paberil')::BOOLEAN, FALSE);
    doc_kas_email    BOOLEAN = coalesce((doc_data ->> 'kas_email')::BOOLEAN, FALSE);
    doc_kas_earve    BOOLEAN = coalesce((doc_data ->> 'kas_earve')::BOOLEAN, FALSE);
    doc_pank         TEXT    = doc_data ->> 'pank';
    doc_kas_esindaja BOOLEAN = coalesce((doc_data ->> 'kas_esindaja')::BOOLEAN, FALSE);
    doc_muud         TEXT    = doc_data ->> 'muud';
    json_props       JSONB;
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
                 FROM (SELECT doc_suhtumine    AS suhtumine,
                              doc_arved        AS arved,
                              doc_kas_paberil  AS kas_paberil,
                              doc_kas_email    AS kas_email,
                              doc_kas_esindaja AS kas_esindaja,
                              doc_pank         AS pank,
                              doc_kas_earve    AS kas_earve) row;

    -- ищем ранее удаленные записи
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT id INTO doc_id
        FROM lapsed.vanemad
        WHERE parentid = doc_parentid
          AND asutusid = doc_asutusid;
    END IF;


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
                                    userName AS user
                            ) row;

        UPDATE lapsed.vanemad
        SET asutusid   = doc_asutusid,
            properties = coalesce(properties, '{}'::JSONB)::JSONB || json_props,
            muud       = doc_muud,
            ajalugu    = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus    = CASE WHEN staatus = 3 THEN 1 ELSE staatus END
        WHERE id = doc_id RETURNING id
            INTO doc_id;

    END IF;

-- проверим наличие статус ответственного у родителей
    IF doc_kas_esindaja AND exists(SELECT id
                                   FROM lapsed.vanemad
                                   WHERE parentid = doc_parentid
                                     AND (properties ->> 'kas_esindaja')::BOOLEAN
                                     AND id <> doc_id)
    THEN
        -- убираем этот статус , если есть у других роделей ребенка
        UPDATE lapsed.vanemad
        SET properties = properties::JSONB || '{
          "kas_esindaja": false
        }'::JSONB
        WHERE parentid = doc_parentid
          AND id <> doc_id
          AND (properties ->> 'kas_esindaja')::BOOLEAN;
    END IF;

-- arveldused
    IF exists(SELECT id
              FROM lapsed.vanem_arveldus
              WHERE parentid = doc_parentid
                AND asutusid = doc_asutusid
                AND rekvid = user_rekvid)
    THEN

        UPDATE lapsed.vanem_arveldus
        SET arveldus = doc_arved
        WHERE parentid = doc_parentid
          AND asutusid = doc_asutusid
          AND rekvid = user_rekvid;
    ELSE
        INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus)
        VALUES (doc_parentid, doc_asutusid, user_rekvid, doc_arved);

    END IF;

    -- уберем статус у других родителей, если надо
    IF (doc_arved)
    THEN
        UPDATE lapsed.vanem_arveldus
        SET arveldus = FALSE
        WHERE parentid = doc_parentid
          AND rekvid = user_rekvid
          AND asutusid <> doc_asutusid
          AND arveldus = TRUE;
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