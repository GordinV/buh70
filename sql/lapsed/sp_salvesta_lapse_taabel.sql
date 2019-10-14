DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_taabel(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_taabel(data JSONB,
                                                           userid INTEGER,
                                                           user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName           TEXT;
    doc_data           JSON    = data ->> 'data';
    doc_id             INTEGER = doc_data ->> 'id';
    doc_parentid       INTEGER = doc_data ->> 'parentid';
    doc_lapse_kaart_id INTEGER = doc_data ->> 'lapse_kaart_id';
    doc_nomid          INTEGER = (SELECT nomid
                                  FROM lapsed.lapse_kaart
                                  WHERE id = doc_lapse_kaart_id);
    doc_kogus          NUMERIC = doc_data ->> 'kogus';
    doc_kuu            INTEGER = doc_data ->> 'kuu';
    doc_aasta          INTEGER = doc_data ->> 'aasta';
    doc_muud           TEXT    = doc_data ->> 'muud';
    doc_staatus        INTEGER = 1;
    json_props         JSONB;
    json_ajalugu       JSONB;
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


    -- поиск удаленной записи
    IF doc_id IS NULL OR doc_id = 0
    THEN
        SELECT id,
               staatus
               INTO doc_id, doc_staatus
        FROM lapsed.lapse_taabel lt
        WHERE parentid = doc_parentid
          AND rekvid = user_rekvid
          AND nomid = doc_nomid
          AND kuu = doc_kuu
          AND aasta = doc_aasta;

        IF doc_id IS NULL
        THEN
            doc_id = 0;
            doc_staatus = 1;
        ELSE
            IF doc_staatus = 3
            THEN
                doc_staatus = 1; -- запись была удалена, восстанавливаем
            END IF;
        END IF;

    END IF;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS created,
                                    userName AS user) row;

        INSERT INTO lapsed.lapse_taabel (parentid, lapse_kaart_id, nomid, rekvid, kogus, kuu, aasta, muud, ajalugu)
        VALUES (doc_parentid, doc_lapse_kaart_id, doc_nomid, user_rekvid, doc_kogus, doc_kuu, doc_aasta, doc_muud,
                '[]' :: JSONB || json_ajalugu) RETURNING id
                   INTO doc_id;

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    lt.*     AS data
                             FROM lapsed.lapse_taabel lt
                             WHERE id = doc_id
                            ) row;

        UPDATE lapsed.lapse_taabel
        SET nomid          = doc_nomid,
            lapse_kaart_id = doc_lapse_kaart_id,
            kogus          = doc_kogus,
            kuu            = doc_kuu,
            aasta          = doc_aasta,
            muud           = doc_muud,
            ajalugu        = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu,
            staatus        = doc_staatus
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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_taabel(JSONB, INTEGER, INTEGER) TO arvestaja;


/*
id: 0,
         parentid: 16,
         nomid: 17748,
         kuu: 9,
         aasta: 2019,
         kogus: 1,
         muud: 'test muud' } } 70


select lapsed.sp_salvesta_lapse_taabel('{"data":{"id":0,"parentid":16,"nomid":17748,"kuu":9,"aasta":2019,"kogus":1,"muud":"test","userid":70}}'::jsonb, 70::integer, 63::integer) as id

*/