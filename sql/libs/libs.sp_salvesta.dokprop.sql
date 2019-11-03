DROP FUNCTION IF EXISTS libs.sp_salvesta_dokprop(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_dokprop(data JSON,
                                                    userid INTEGER,
                                                    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id        INTEGER;
    userName      TEXT;
    doc_id        INTEGER = data ->> 'id';
    doc_data      JSON    = data ->> 'data';
    doc_dok       TEXT    = doc_data ->> 'dok';
    doc_selg      TEXT    = doc_data ->> 'selg';
    doc_muud      TEXT    = doc_data ->> 'muud';
    doc_rekvid    INTEGER = doc_data ->> 'rekvid';
    doc_registr   INTEGER = doc_data ->> 'registr';
    doc_vaatalaus INTEGER = doc_data ->> 'vaatalaus';
    doc_konto     TEXT    = doc_data ->> 'konto';
    doc_kbmkonto  TEXT    = doc_data ->> 'kbmkonto';
    doc_asutusid  INTEGER = doc_data ->> 'asutusid';
    doc_kood1     TEXT    = doc_data ->> 'kood1';
    doc_kood2     TEXT    = doc_data ->> 'kood2';
    doc_kood3     TEXT    = doc_data ->> 'kood3';
    doc_kood5     TEXT    = doc_data ->> 'kood5';
    doc_proc_     TEXT    = doc_data ->> 'proc_';
    doc_type      INTEGER = doc_data ->> 'type';
    doc_parentid  INTEGER = coalesce((doc_data ->> 'parentid')::INTEGER, (SELECT id
                                                                          FROM libs.library
                                                                          WHERE LIbrary = 'DOK'
                                                                            AND kood = doc_dok
                                                                          ORDER BY id DESC
                                                                          LIMIT 1));
    l_parentId    INTEGER = COALESCE(doc_parentid, (SELECT id
                                                    FROM libs.library
                                                    WHERE library = 'DOK'
                                                      AND kood = doc_dok
                                                      AND (rekvid = doc_rekvid OR rekvid IS NULL)
                                                    LIMIT 1));
    json_object   JSONB;
    is_import     BOOLEAN = data ->> 'import';

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
    FROM (SELECT doc_konto    AS konto,
                 doc_kbmkonto AS kbmkonto,
                 doc_kood1    AS kood1,
                 doc_kood2    AS kood2,
                 doc_kood3    AS kood3,
                 doc_kood5    AS kood5) row;

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.dokprop (parentId, rekvid, registr, vaatalaus, selg, muud, asutusId, details, proc_, status)
        VALUES (l_parentId, user_rekvid, doc_registr, doc_vaatalaus, doc_selg, doc_muud, doc_asutusId, json_object,
                doc_proc_, 1) RETURNING id
                   INTO lib_id;
    ELSE

        UPDATE libs.dokprop
        SET parentid  = l_parentId,
            registr   = doc_registr,
            vaatalaus = doc_vaatalaus,
            selg      = doc_selg,
            asutusid  = doc_asutusid,
            details   = json_object,
            proc_     = doc_proc_,
            muud      = doc_muud
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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_dokprop(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_dokprop(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_dokprop('{"data":{"asutusid":0,"id":0,"kbmkonto":null,"konto":"100100","kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"muud":null,"parentid":null,"proc_":"","registr":1,"selg":"","vaatalaus":1}}'
,70, 63)

{ data:
      { docTypeId: 'DOKPROPS',
        userId: 70,
        uuid: '48d96e20-fe3d-11e9-a2c6-5d20989ba3f1',
        docId: 0,
        context: null,
        id: 0,
        selg: 'SMK ',
        nimetus: null,
        parentid: null,
        dok: 'SMK',
        rekvid: null,
        userid: 70,
        konto: '100100',
        kbmkonto: null,
        kood1: null,
        kood2: null,
        kood3: null,
        kood5: null,
        proc_: null,
        registr: 0,
        vaatalaus: 0,
        muud: null,
        asutusid: 0,
        row: [Array],
        bpm: [],
        requiredFields: [Array] } } }
{"id":1,"data":{"asutusid":0,"id":1,"kbmkonto":"","kbmlausend":0,"konto":"111","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","muud":"","parentid":1,"proc_":"","registr":1,"selg":"","vaatalaus":1}}
{"id":0,"data":{"asutusid":null,"dok":"ARV","id":0,"kbmkonto":null,"konto":null,"kood1":null,"kood2":null,"kood3":null,"kood5":null,"muud":null,"nimetus":null,"proc_":null,"registr":0,"rekvid":1,"selg":"__test8514","userid":1,"vaatalaus":0}}
{"id":1,"data":{"asutusid":2,"id":1,"kbmkonto":"113","kbmlausend":0,"konto":"111","kood1":"test","kood2":"","kood3":"","kood4":"","kood5":"","muud":"","parentid":1,"proc_":"","registr":1,"selg":"","vaatalaus":1}}
*/