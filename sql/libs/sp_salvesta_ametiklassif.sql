DROP FUNCTION IF EXISTS libs.sp_salvesta_ametiklassif( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_ametiklassif(
    data        JSON,
    userid      INTEGER,
    user_rekvid INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    lib_id      INTEGER;
    detail_id integer;
    userName    TEXT;
    doc_id      INTEGER = data ->> 'id';
    doc_data    JSON = data ->> 'data';
    doc_kood    TEXT = doc_data ->> 'kood';
    doc_nimetus TEXT = doc_data ->> 'nimetus';
    doc_library TEXT = doc_data ->> 'library';
    doc_tun1    INTEGER = doc_data ->> 'tun1'; --liik
    doc_tun2    INTEGER = doc_data ->> 'tun2'; -- tegev
    doc_tun3    INTEGER = doc_data ->> 'tun3'; -- allikas
    doc_tun4    INTEGER = doc_data ->> 'tun4'; -- rahavoog
    doc_tun5    INTEGER = doc_data ->> 'tun5';

    doc_muud    TEXT = doc_data ->> 'muud';
    doc_details   JSON = doc_data ->> 'gridData';
    json_object JSONB;
    json_record   RECORD;
    ids           INTEGER [];

BEGIN

    IF (doc_id IS NULL)
    THEN
        doc_id = doc_data ->> 'id';
    END IF;

    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid AND u.id = userId;

    IF userName IS NULL
    THEN
        RAISE NOTICE 'User not found %, user_rekvid %, userId %', user, user_rekvid, userId;
        RETURN 0;
    END IF;

    json_object = jsonb_build_object('palgaastmed',doc_details);

    -- вставка или апдейт docs.doc
    IF doc_id IS NULL OR doc_id = 0
    THEN

        INSERT INTO libs.library (rekvid, kood, nimetus, library,  tun1, tun2, tun3, tun4, tun5, muud, properties)
        VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library,  doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tun5, doc_muud, json_object)
        RETURNING id
            INTO lib_id;
    ELSE

        UPDATE libs.library
        SET
            kood       = doc_kood,
            nimetus    = doc_nimetus,
            library    = doc_library,
            tun1       = doc_tun1,
            tun2       = doc_tun2,
            tun3       = doc_tun3,
            tun4       = doc_tun4,
            tun5       = doc_tun5,
            muud       = doc_muud,
            properties = coalesce((properties::jsonb),'{}'::jsonb) || json_object
        WHERE id = doc_id
        RETURNING id
            INTO lib_id;
    END IF;


    RETURN lib_id;

EXCEPTION WHEN OTHERS
    THEN
        RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
        RETURN 0;


END;$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_ametiklassif(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_ametiklassif(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

select * from ou.userid where rekvid = 63 and kasutaja = 'vlad'

SELECT libs.sp_salvesta_ameti_klassif('{"id":284541,"data": {"alates":null,"doc_type_id":"PALGASTMED","id":284541,"kood":"2","library":"PALGAASTMED","muud":null,"nimetus":"2","rekvid":63,"status":1,"summa":null,"userid":2477,"valid":null,"gridData":[{"alates":"20250116","id":0,"summa":200}]}}'
,2477, 63)
*/