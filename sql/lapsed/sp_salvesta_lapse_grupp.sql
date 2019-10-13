DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_grupp(JSONB, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS lapsed.sp_salvesta_lapse_grupp(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_salvesta_lapse_grupp(data JSONB,
                                                          user_id INTEGER,
                                                          user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id          INTEGER;
    userName        TEXT;
    doc_id          INTEGER = data ->> 'id';
    doc_data        JSON    = data ->> 'data';
    doc_kood        TEXT    = doc_data ->> 'kood';
    doc_nimetus     TEXT    = doc_data ->> 'nimetus';
    doc_library     TEXT    = 'LAPSE_GRUPP';
    doc_muud        TEXT    = doc_data ->> 'muud';
    doc_all_yksus_1 TEXT    = coalesce((doc_data ->> 'all_yksus_1'),'');
    doc_all_yksus_2 TEXT    = coalesce((doc_data ->> 'all_yksus_2'),'');
    doc_all_yksus_3 TEXT    = coalesce((doc_data ->> 'all_yksus_3'),'');
    doc_all_yksus_4 TEXT    = coalesce((doc_data ->> 'all_yksus_4'),'');
    doc_all_yksus_5 TEXT    = coalesce((doc_data ->> 'all_yksus_5'),'');
    is_import       BOOLEAN = data ->> 'import';
    all_yksused     TEXT[]  = ARRAY [doc_all_yksus_1, doc_all_yksus_2, doc_all_yksus_3, doc_all_yksus_4, doc_all_yksus_5];
    json_object     JSONB;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
        RETURN 0;
    END IF;

-- prepairing all yksused

    SELECT to_jsonb(row) INTO json_object
    FROM (SELECT all_yksused AS all_yksused) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_muud, json_object) RETURNING id
            INTO lib_id;
    ELSE

        UPDATE libs.library
        SET kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            muud       = doc_muud,
            properties = json_object
        WHERE id = doc_id RETURNING id
            INTO lib_id;

    END IF;

    RETURN lib_id;

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

GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_grupp(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_salvesta_lapse_grupp(JSONB, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT lapsed.sp_salvesta_lapse_grupp('{"id":214107,"data":{"id":214107,"kood":"grupp 2","muud":"test all_yksused","nimetus":"grupp 2 nimetus ","all_yksus_1":"1","all_yksus_2":"2"}}'
,70, 63)
*/