DROP FUNCTION IF EXISTS eelarve.sp_salvesta_eel_config( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.sp_salvesta_eel_config(
  data        JSON,
  user_id     INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id           INTEGER;
  userName         TEXT;
  doc_kassa_kontod JSON = data ->> 'kassaKontod';
  doc_kassa_kulud  JSON = data ->> 'kassaKulud';
  doc_kulu_kontod  JSON = data ->> 'kuluKontod';
  doc_kassa_tulud  JSON = data ->> 'kassaTulud';
  doc_tulu_kontod  JSON = data ->> 'tuluKontod';
  json_object      JSON;
  json_record      RECORD;
  new_history      JSONB;
  ids              INTEGER [];
  docs             INTEGER [];
BEGIN

  SELECT kasutaja
  INTO userName
  FROM ou.userid u
  WHERE u.rekvid = user_rekvid AND u.id = user_id;
  IF userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()    AS updated,
          userName AS user) row;

  -- вставка в таблицы документа

  raise notice 'doc_kassa_kontod %',doc_kassa_kontod;
  -- kassaKontod
  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_kassa_kontod)
  UNION ALL
  SELECT *
  FROM json_array_elements(doc_kassa_kulud)
  UNION ALL
  SELECT *
  FROM json_array_elements(doc_kulu_kontod)
  UNION ALL
  SELECT *
  FROM json_array_elements(doc_kassa_tulud)
  UNION ALL
  SELECT *
  FROM json_array_elements(doc_tulu_kontod)

  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id INTEGER, rekvid INTEGER, kood TEXT, nimetus TEXT, library TEXT, muud TEXT);

    raise notice 'json_record %',json_record;

    IF json_record.id IS NULL OR json_record.id = 0
    THEN
      INSERT INTO libs.library (rekvid, kood, nimetus, library, muud)
      VALUES
        (user_rekvid, json_record.kood, json_record.nimetus, json_record.library, json_record.muud)

      RETURNING id
        INTO lib_id;
    ELSE

      UPDATE libs.library
      SET
        kood = json_record.kood,
        muud = json_record.muud
      WHERE id = json_record.id :: INTEGER
      RETURNING id
        INTO lib_id;

    END IF;

    -- add new id into array of ids
    ids = array_append(ids, lib_id);

    -- delete record which not in json
  END LOOP;

  PERFORM libs.sp_delete_library(user_id, id)
  FROM libs.library l
  WHERE (l.rekvid = user_rekvid OR l.rekvid IS NULL)
        AND library IN ('KASSAKONTOD', 'KASSAKULUD', 'KULUKONTOD', 'KASSATULUD', 'TULUKONTOD')
        AND id NOT IN (SELECT unnest(ids));

  RETURN 1;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    --    error_message = SQLERRM;
    --    result = 0;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_eel_config(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_eel_config(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


SELECT eelarve.sp_salvesta_eel_config('{"id":1,"kassaKontod":[{"doc_type_id":"","id":0,"kood":"50","library":"KASSAKONTOD","muud":"","nimetus":"kassa_kontod","rekvid":0,"rekv_id":0,"status":0,"userid":0}],
"kassaKulud":[{"doc_type_id":"","id":0,"kood":"40","library":"KASSAKULUD","muud":"","nimetus":"kassa_kulud","rekvid":0,"rekv_id":0,"status":0,"userid":0}],
"kuluKontod":[{"doc_type_id":"","id":0,"kood":"30","library":"KULUKONTOD","muud":"","nimetus":"kulu_kontod","rekvid":0,"rekv_id":0,"status":0,"userid":0}],
"kassaTulud":[{"doc_type_id":"","id":0,"kood":"20","library":"KASSATULUD","muud":"","nimetus":"tulu_kontod","rekvid":0,"rekv_id":0,"status":0,"userid":0}],
"tuluKontod":[{"doc_type_id":"","id":0,"kood":"10","library":"KASSAKONTOD","muud":"","nimetus":"tulu_kontod","rekvid":0,"rekv_id":0,"status":0,"userid":0}]}	', 1, 1);
