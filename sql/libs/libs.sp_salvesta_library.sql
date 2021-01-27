DROP FUNCTION IF EXISTS docs.sp_salvesta_library(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_salvesta_library(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_library(data JSON,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id         INTEGER;
    userName       TEXT;
    doc_id         INTEGER = data ->> 'id';
    doc_data       JSON    = data ->> 'data';
    doc_kood       TEXT    = doc_data ->> 'kood';
    doc_nimetus    TEXT    = doc_data ->> 'nimetus';
    doc_library    TEXT    = doc_data ->> 'library';
    doc_tun1       INTEGER = doc_data ->> 'tun1'; --liik
    doc_tun2       INTEGER = doc_data ->> 'tun2'; -- tegev
    doc_tun3       INTEGER = doc_data ->> 'tun3'; -- allikas
    doc_tun4       INTEGER = doc_data ->> 'tun4'; -- rahavoog
    doc_tun5       INTEGER = doc_data ->> 'tun5';
    doc_muud       TEXT    = doc_data ->> 'muud';
    doc_valid      DATE    = CASE WHEN empty(doc_data ->> 'valid') THEN NULL::DATE ELSE (doc_data ->> 'valid')::DATE END;
    is_import      BOOLEAN = data ->> 'import';
    v_doc          RECORD;
    is_peakasutaja BOOLEAN = FALSE;
    json_object    JSON;

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;


    SELECT kasutaja,
           (u.roles ->> 'is_peakasutaja')::BOOLEAN AS is_peakasutaja
           INTO userName, is_peakasutaja
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = userId;

    IF is_import IS NULL AND userName IS NULL
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    -- проверка на тип справочника и роль
    IF NOT is_peakasutaja AND doc_library IN ('ALLIKAD', 'TEGEV', 'TULUDEALLIKAD', 'RAHA')
    THEN
        RAISE NOTICE 'Puudub õigused';
        RETURN 0;
    END IF;

    SELECT row_to_json(row) INTO json_object
    FROM (SELECT doc_valid AS valid) row;


    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tun5,
                doc_muud, json_object) RETURNING id
                   INTO lib_id;

        -- для отдела культуры
        IF user_rekvid = 119 AND doc_library = 'PROJ' AND lib_id IS NOT NULL AND lib_id > 0
        THEN
            --копируем  данные во все под организации
            INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud, properties)
            SELECT rekv.id,
                   l.kood,
                   l.nimetus,
                   l.library,
                   l.tun1,
                   l.tun2,
                   l.tun3,
                   l.tun4,
                   l.tun5,
                   l.muud,
                   l.properties
            FROM libs.library l,
                 ou.rekv rekv
            WHERE l.id = lib_id
              AND rekv.parentid = 119;
        END IF;

    ELSE
        -- check is this code in use
        -- проверим на использование кода в справочниках
        SELECT * INTO v_doc FROM libs.library l WHERE l.id = doc_id;
        IF v_doc.library = 'ASUTUSE_LIIK'
            AND v_doc.kood::TEXT <> doc_kood::TEXT
            AND exists(SELECT id
                       FROM ou.rekv r
                       WHERE r.properties ->> 'liik' IS NOT NULL
                         AND r.properties ->> 'liik' = v_doc.kood::TEXT)
        THEN
            RAISE EXCEPTION 'Есть связанные доку менты. удалять нельзя';

        END IF;


        UPDATE libs.library
        SET kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            tun1       = doc_tun1,
            tun2       = doc_tun2,
            tun3       = doc_tun3,
            tun4       = doc_tun4,
            tun5       = doc_tun5,
            muud       = doc_muud,
            properties = json_object
        WHERE id = doc_id RETURNING id
            INTO lib_id;

        IF user_rekvid = 119 AND doc_library = 'PROJ' AND lib_id IS NOT NULL AND lib_id > 0
        THEN
            UPDATE libs.library
            SET kood       = doc_kood,
                nimetus    = doc_nimetus,
                tun1       = doc_tun1,
                tun2       = doc_tun2,
                tun3       = doc_tun3,
                tun4       = doc_tun4,
                tun5       = doc_tun5,
                muud       = doc_muud,
                properties = json_object
            WHERE kood = v_doc.kood
              AND library.library = 'PROJ'
              AND rekvid IN (SELECT id FROM ou.rekv WHERE parentid = 119);

        END IF;

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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_konto('{"id":38,"data":{"doc_type_id":"KONTOD","id":38,"konto_tyyp":null,"kood":"620","library":"KONTOD","muud":"test kontod","nimetus":"Sotsiaalmaks töötasult","rekvid":1,"tun1":1,"tun2":1,"tun3":0,"tun4":0,"tyyp":1,"userid":1,"valid":"20181231"}}'
,1, 1)
*/