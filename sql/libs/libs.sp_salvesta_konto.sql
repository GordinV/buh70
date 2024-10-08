﻿DROP FUNCTION IF EXISTS docs.sp_salvesta_konto(JSON, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_salvesta_konto(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_konto(data JSON,
                                                  userid INTEGER,
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
    doc_library     TEXT    = 'KONTOD';
    doc_tun1        INTEGER = doc_data ->> 'tun1'; --liik
    doc_tun2        INTEGER = doc_data ->> 'tun2'; -- tegev
    doc_tun3        INTEGER = doc_data ->> 'tun3'; -- allikas
    doc_tun4        INTEGER = doc_data ->> 'tun4'; -- rahavoog
    doc_tyyp        INTEGER = doc_data ->> 'tyyp';
    doc_tp_req      TEXT    = doc_data ->> 'tp_req';
    doc_tt_req      TEXT    = doc_data ->> 'tt_req';
    doc_a_req       TEXT    = doc_data ->> 'a_req';
    doc_rv_req      TEXT    = doc_data ->> 'rv_req';
    doc_valid       DATE    = CASE
                                  WHEN empty(doc_data ->> 'valid') THEN NULL::DATE
                                  ELSE (doc_data ->> 'valid')::DATE END;
    doc_muud        TEXT    = doc_data ->> 'muud';
    doc_kas_virtual INTEGER = doc_data ->> 'kas_virtual';
    is_import       BOOLEAN = data ->> 'import';
    json_object     JSONB;
    is_peakasutaja  BOOLEAN = FALSE;
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

    IF is_import IS NULL AND (userName IS NULL OR NOT is_peakasutaja)
    THEN
        RAISE NOTICE 'User not found %', user;
        RETURN 0;
    END IF;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT doc_valid       AS valid,
                 doc_kas_virtual AS kas_virtual,
                 doc_tp_req      AS tp_req,
                 doc_tt_req      AS tt_req,
                 doc_a_req       AS a_req,
                 doc_rv_req      AS rv_req
         ) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tyyp,
                doc_muud,
                json_object) RETURNING id
                   INTO lib_id;


    ELSE

        UPDATE libs.library
        SET kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            tun1       = doc_tun1,
            tun2       = doc_tun2,
            tun3       = doc_tun3,
            tun4       = doc_tun4,
            tun5       = doc_tyyp,
            properties = json_object,
            muud       = doc_muud
        WHERE id = doc_id RETURNING id
            INTO lib_id;

    END IF;
    RAISE NOTICE 'konto nimi %', doc_nimetus;
    RETURN lib_id;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % % %', MESSAGE_TEXT, PG_EXCEPTION_DETAIL, PG_EXCEPTION_HINT;
            RETURN 0;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_konto(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_konto(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_konto('{"id":38,"data":{"doc_type_id":"KONTOD","id":38,"konto_tyyp":null,"kood":"620","library":"KONTOD","muud":"test kontod","nimetus":"Sotsiaalmaks töötasult","rekvid":1,"tun1":1,"tun2":1,"tun3":0,"tun4":0,"tyyp":1,"userid":1,"valid":"20181231"}}'
,1, 1)
*/