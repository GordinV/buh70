DROP FUNCTION IF EXISTS libs.sp_salvesta_objekt(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_objekt(data JSON,
                                                   userid INTEGER,
                                                   user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id       INTEGER;
    userName     TEXT;
    doc_id       INTEGER = data ->> 'id';
    doc_data     JSON    = data ->> 'data';
    doc_kood     TEXT    = doc_data ->> 'kood';
    doc_nimetus  TEXT    = doc_data ->> 'nimetus';
    doc_library  TEXT    = 'OBJEKT';
    doc_parentid INTEGER = doc_data ->> 'parentid';
    doc_asutusid INTEGER = doc_data ->> 'asutusid';
    doc_nait02   NUMERIC = doc_data ->> 'nait02';
    doc_nait03   NUMERIC = doc_data ->> 'nait03';
    doc_nait04   NUMERIC = doc_data ->> 'nait04';
    doc_nait05   NUMERIC = doc_data ->> 'nait05';
    doc_nait06   NUMERIC = doc_data ->> 'nait06';
    doc_nait07   NUMERIC = doc_data ->> 'nait07';
    doc_nait08   NUMERIC = doc_data ->> 'nait08';
    doc_nait09   NUMERIC = doc_data ->> 'nait09';
    doc_nait10   NUMERIC = doc_data ->> 'nait10';
    doc_nait11   NUMERIC = doc_data ->> 'nait11';
    doc_nait14   NUMERIC = doc_data ->> 'nait14';
    doc_nait15   NUMERIC = doc_data ->> 'nait15';
    doc_valid    DATE    = CASE WHEN empty(doc_data ->> 'valid') THEN NULL::DATE ELSE (doc_data ->> 'valid')::DATE END;
    doc_muud     TEXT    = doc_data ->> 'muud';
    is_import    BOOLEAN = data ->> 'import';
    json_object  JSONB;
BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;


    SELECT kasutaja INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE EXCEPTION 'User not found %', user;
        RETURN 0;
    END IF;


    SELECT row_to_json(row) INTO json_object
    FROM (SELECT doc_parentid AS parentid,
                 doc_asutusid AS asutusid,
                 doc_nait02   AS nait02,
                 doc_nait03   AS nait03,
                 doc_nait04   AS nait04,
                 doc_nait05   AS nait05,
                 doc_nait06   AS nait06,
                 doc_nait07   AS nait07,
                 doc_nait08   AS nait08,
                 doc_nait09   AS nait09,
                 doc_nait10   AS nait10,
                 doc_nait11   AS nait11,
                 doc_nait14   AS nait14,
                 doc_valid    AS valid,
                 doc_nait15   AS nait15) row;

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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_objekt(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_objekt(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_objekt('{"id":0,"data":{"kood":"test","muud":"test kontod","nimetus":"Objekt nimi"}}'
,1, 1)
*/