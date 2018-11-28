DROP FUNCTION IF EXISTS docs.sp_salvesta_vara_grupp( JSON, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS libs.sp_salvesta_vara_grupp( JSON, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS libs.sp_salvesta_ladu( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_ladu(
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
  doc_library TEXT = 'LADU';
  doc_konto varchar(20) = doc_data ->> 'konto';
  doc_muud text = doc_data ->> 'muud';
  json_object JSONB;
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
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  SELECT row_to_json(row)
  INTO json_object
  FROM (SELECT doc_konto as konto) row;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO libs.library (rekvid, kood, nimetus, library, muud, properties)
    VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library,  doc_muud, json_object)
    RETURNING id
      INTO lib_id;

  ELSE

    UPDATE libs.library
    SET
      kood       = doc_kood,
      nimetus    = doc_nimetus,
      library    = doc_library,
      properties = json_object,
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

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_ladu(JSON, INTEGER, INTEGER) TO ladukasutaja;


/*

SELECT libs.sp_salvesta_pv_grupp('{"id":0,"data":{"doc_type_id":"PVGRUPP","id":0,"konto":"5001","kood":"__test3367","kulum_konto":"1901","library":"PVGRUPP","muud":null,"nimetus":"vfp test PVGRUPP","rekvid":1,"status":0,"tun1":null,"tun2":null,"userid":1}}'
,1, 1)

*/