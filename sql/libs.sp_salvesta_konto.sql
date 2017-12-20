DROP FUNCTION IF EXISTS docs.sp_salvesta_konto( JSON, INTEGER, INTEGER );
DROP FUNCTION IF EXISTS libs.sp_salvesta_konto( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_konto(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id         INTEGER;
  userName       TEXT;
  doc_id         INTEGER = data ->> 'id';
  doc_data       JSON = data ->> 'data';
  doc_kood       TEXT = doc_data ->> 'kood';
  doc_nimetus    TEXT = doc_data ->> 'nimetus';
  doc_library    TEXT = 'KONTOD';
  doc_tun1       INTEGER = doc_data ->> 'tun1';
  doc_tun2       INTEGER = doc_data ->> 'tun2';
  doc_tun3       INTEGER = doc_data ->> 'tun3';
  doc_tun4       INTEGER = doc_data ->> 'tun4';
  doc_tyyp       INTEGER = doc_data ->> 'tyyp';
  doc_valid      DATE = doc_data ->> 'valid';
  doc_properties TEXT = doc_data ->> 'properties';
  doc_muud       TEXT = doc_data ->> 'muud';
  new_history    JSONB;
  new_rights     JSONB;
BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;


  SELECT kasutaja
  INTO userName
  FROM userid u
  WHERE u.rekvid = user_rekvid AND u.id = userId;
  IF userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  IF doc_valid IS NOT NULL
  THEN
    doc_properties = coalesce(doc_properties, '') || '{"valid":"' || doc_valid || '"}';
  END IF;

  RAISE NOTICE 'doc_properties %, valid %', doc_properties, doc_valid;
  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS "user") row;
    SELECT row_to_json(row)
    INTO new_rights
    FROM (SELECT
            ARRAY [userId] AS "select",
            ARRAY [userId] AS "update",
            ARRAY [userId] AS "delete") row;

    INSERT INTO libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud, properties)
    VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tyyp, doc_muud,
                         doc_properties :: JSONB)
    RETURNING id
      INTO lib_id;


  ELSE
    -- history
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user) row;

    UPDATE libs.library
    SET
      kood       = doc_kood,
      nimetus    = doc_nimetus,
      library    = doc_library,
      tun1       = doc_tun1,
      tun2       = doc_tun2,
      tun3       = doc_tun3,
      tun4       = doc_tun4,
      tun5       = doc_tyyp,
      properties = doc_properties :: JSONB,
      muud       = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO lib_id;

  END IF;

  RETURN lib_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_konto(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_konto(JSON, INTEGER, INTEGER) TO dbpeakasutaja;



/*


select * from libs.library where id = 23
SELECT libs.sp_salvesta_konto('{
  "params": {
    "userId": 1,
    "asutusId": 1,
    "data": {
      "data": {
        "konto_tyyp": null,
        "id": 22,
        "kood": "5019",
        "nimetus": "Internet",
        "library": "KONTOD              ",
        "tun1": 0,
        "tun2": 0,
        "tun3": 0,
        "tun4": 0,
        "muud": "Прочее",
        "properties": null,
        "userid": 1,
        "doc_type_id": "KONTOD",
        "tyyp": 3,
        "valid": "2017-12-30"
      }
    }
  },
  "result": {
    "result": {
      "error_code": 9,
      "result": null,
      "error_message": "duplicate key value violates unique constraint \"library_kood_status\"",
      "data": []
    }
  },
  "data": [
    {
      "konto_tyyp": null,
      "id": 22,
      "kood": "5019",
      "nimetus": "Internet",
      "library": "KONTOD              ",
      "tun1": 0,
      "tun2": 0,
      "tun3": 0,
      "tun4": 0,
      "muud": "Прочее",
      "properties": null,
      "userid": 1,
      "doc_type_id": "KONTOD",
      "tyyp": 3,
      "valid": "2017-12-30"
    }
  ]
  )
  ;
select * from libs.asutus


select case when l.tun5 = 1 then 'SD' when l.tun5 = 2 then 'SK' when l.tun5 = 3 then ' D ' when l.tun5 = 4 then 'K' else null end::text as konto_tyyp,
                l.id, trim(l.kood) as kood, trim(l.nimetus) as nimetus, l.library, l.tun1, l.tun2, l.tun3, l.tun4, l.muud, l.properties, 1::integer as userid, 'KONTOD' as doc_type_id, l.tun5 as tyyp, 
                (l.properties::jsonb ->> ' VALID ')::text as valid
                from libs.library l 
                where id = 135
*/