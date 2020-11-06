DROP FUNCTION IF EXISTS docs.sp_salvesta_amet(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_salvesta_amet(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_amet(data JSON,
                                                 userid INTEGER,
                                                 user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id        INTEGER;
    userName      TEXT;
    doc_id        INTEGER        = data ->> 'id';
    doc_data      JSON           = data ->> 'data';
    doc_kood      TEXT           = doc_data ->> 'kood';
    doc_nimetus   TEXT           = doc_data ->> 'nimetus';
    doc_library   TEXT           = 'AMET';
    doc_osakondId INTEGER        = doc_data ->> 'osakondid';
    doc_kogus     NUMERIC(18, 2) = doc_data ->> 'kogus';
    doc_palgamaar INTEGER        = doc_data ->> 'palgamaar';
    doc_tunnusId  INTEGER        = doc_data ->> 'tunnusid';
    doc_muud      TEXT           = doc_data ->> 'muud';
    doc_valid     DATE           = CASE
                                       WHEN empty(doc_data ->> 'valid') THEN NULL::DATE
                                       ELSE (doc_data ->> 'valid')::DATE END;
    is_import     BOOLEAN        = data ->> 'import';
    json_object   JSONB;
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
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    SELECT row_to_json(row) INTO json_object
    FROM (SELECT doc_osakondId AS osakondId,
                 doc_kogus     AS kogus,
                 doc_palgamaar AS palgamaar,
                 doc_tunnusId  AS tunnusId,
                 doc_valid     AS valid) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_muud,
                json_object) RETURNING id
                   INTO lib_id;


    ELSE

        UPDATE libs.library
        SET kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            properties = json_object,
            muud       = doc_muud
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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_amet(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_amet(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_konto('{"id":38,"data":{"doc_type_id":"KONTOD","id":38,"konto_tyyp":null,"kood":"620","library":"KONTOD","muud":"test kontod","nimetus":"Sotsiaalmaks töötasult","rekvid":1,"tun1":1,"tun2":1,"tun3":0,"tun4":0,"tyyp":1,"userid":1,"valid":"20181231"}}'
,1, 1)
*/