DROP FUNCTION IF EXISTS docs.sp_salvesta_library( JSON, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS libs.sp_salvesta_library( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_library(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id      INTEGER;
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
  json_object JSONB;
BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;


/*
  SELECT kasutaja
  INTO userName
  FROM userid u
  WHERE u.rekvid = user_rekvid AND u.id = userId;
  IF userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;
*/

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud)
    VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tun5, doc_muud)
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
      muud       = doc_muud
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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_konto('{"id":38,"data":{"doc_type_id":"KONTOD","id":38,"konto_tyyp":null,"kood":"620","library":"KONTOD","muud":"test kontod","nimetus":"Sotsiaalmaks töötasult","rekvid":1,"tun1":1,"tun2":1,"tun3":0,"tun4":0,"tyyp":1,"userid":1,"valid":"20181231"}}'
,1, 1)
*/