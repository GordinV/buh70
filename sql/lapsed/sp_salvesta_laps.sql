DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapsed(JSONB, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.sp_salvesta_laps(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_laps(data JSONB,
                                                     userid INTEGER,
                                                     user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    doc_data      JSON    = data ->> 'data';
    doc_isikukood TEXT    = doc_data ->> 'isikukood';
    doc_nimi      TEXT    = doc_data ->> 'nimi';
    doc_viitenr   TEXT    = doc_data ->> 'viitenumber';
    doc_vanemad   JSON    = doc_data ->> 'vanemad';
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
                 FROM (SELECT doc_viitenr AS viitenumber) row;

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

    ELSE

        -- логгирование

        json_ajalugu = to_jsonb(row)
                       FROM (SELECT now()    AS updated,
                                    userName AS user,
                                    l.*      AS data
                             FROM lapsed.laps l
                             WHERE id = doc_id
                            ) row;

        UPDATE libs.library
        SET isikukood  = doc_isikukood,
            nimi       = doc_nimi,
            properties = properties ||  json_props,
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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_laps(JSONB, INTEGER, INTEGER) TO arvestaja;


/*

select * from ou.userid where rekvid = 63
SELECT lapsed.sp_salvesta_laps('{"id":0,"data":{"isikukood":"37303023721","id":0,"nimi":"Vlad","viitenumber":"123456789", "muud":"test"}}'::jsonb,70, 63)

select * from lapsed.laps
*/