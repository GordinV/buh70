DROP FUNCTION IF EXISTS docs.sp_salvesta_pv_grupp(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_salvesta_pv_grupp(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_pv_grupp(data JSON,
                                                     userid INTEGER,
                                                     user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id          INTEGER;
    userName        TEXT;
    doc_id          INTEGER     = data ->> 'id';
    doc_data        JSON        = data ->> 'data';
    doc_kood        TEXT        = doc_data ->> 'kood';
    doc_nimetus     TEXT        = doc_data ->> 'nimetus';
    doc_library     TEXT        = 'PVGRUPP';
    doc_tun1        INTEGER     = doc_data ->> 'tun1';
    doc_tun2        INTEGER     = doc_data ->> 'tun2';
    doc_konto       VARCHAR(20) = doc_data ->> 'konto';
    doc_kulum_konto VARCHAR(20) = doc_data ->> 'kulum_konto';
    doc_muud        TEXT        = doc_data ->> 'muud';
    doc_valid       DATE        = CASE
                                      WHEN empty(doc_data ->> 'valid') THEN NULL::DATE
                                      ELSE (doc_data ->> 'valid')::DATE END;

    is_import       BOOLEAN     = data ->> 'import';
    json_object     JSONB;

    v_pv_kaart      RECORD;
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
    FROM (SELECT doc_kulum_konto AS kulum_konto,
                 doc_konto       AS konto,
                 doc_valid       AS valid) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_muud, json_object) RETURNING id
            INTO lib_id;


    ELSE

        UPDATE libs.library
        SET kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            properties = json_object,
            tun1       = doc_tun1,
            tun2       = doc_tun2,
            muud       = doc_muud
        WHERE id = doc_id RETURNING id
            INTO lib_id;

        -- uuenda pv_kaart konto

        FOR v_pv_kaart IN
            SELECT l.*
            FROM libs.library l
            WHERE l.rekvid = user_rekvid
              AND l.library = 'POHIVARA'
              AND (l.properties :: JSONB ->> 'gruppid') :: INTEGER = lib_id
            LOOP
                SELECT row_to_json(row) INTO json_object
                FROM (SELECT doc_konto AS konto) row;

                json_object = v_pv_kaart.properties :: JSONB || json_object;
                UPDATE libs.library
                SET properties = json_object :: TEXT
                WHERE id = v_pv_kaart.id;
            END LOOP;

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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_pv_grupp(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_pv_grupp(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_pv_grupp('{"id":0,"data":{"doc_type_id":"PVGRUPP","id":0,"konto":"5001","kood":"__test8331943","kulum_konto":"1901","library":"PVGRUPP","muud":null,"nimetus":"vfp test PVGRUPP","rekvid":1,"status":0,"tun1":null,"tun2":null,"userid":1}}'
,1, 1)

*/