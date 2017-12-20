DROP FUNCTION IF EXISTS libs.sp_salvesta_library( DATA JSON, userid INTEGER, user_rekvid INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_library(data JSON, userid INTEGER, user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id       INTEGER;
  userName     TEXT;
  doc_id       INTEGER = data ->> 'id';
  doc_data     JSON = data ->> 'data';
  doc_kood     TEXT = doc_data ->> 'kood';
  doc_nimetus  TEXT = doc_data ->> 'nimetus';
  doc_library  TEXT = doc_data ->> 'library';
  doc_muud     TEXT = doc_data ->> 'muud';
  doc_type     TEXT = (doc_data ->> 'type');
  doc_module   TEXT = doc_data ->> 'module';
  doc_props    JSONB = doc_data ->> 'properties';
  json_object  JSONB;
  new_history  JSONB;
  new_rights   JSONB;

  v_dokvaluuta RECORD;
  lrCurRec     RECORD;
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

  IF doc_library = 'DOK' AND doc_module IS NULL AND doc_type = 'library'
  THEN
    -- @todo hardcode,
    doc_module = '["Libraries"]';
    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT doc_module AS module) row;
  END IF;

  doc_props = CASE WHEN doc_props IS NULL
    THEN json_object
              ELSE doc_props || json_object END;


  IF doc_id IS NULL OR doc_id = 0
  THEN

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;
    SELECT row_to_json(row)
    INTO new_rights
    FROM (SELECT
            ARRAY [userId] AS "select",
            ARRAY [userId] AS "update",
            ARRAY [userId] AS "delete") row;

    -- uus kiri
    INSERT INTO libs.library (rekvid, library, kood, nimetus, muud, properties)
    VALUES (user_rekvid, doc_library, doc_kood, doc_nimetus, doc_muud, doc_props)
    RETURNING id
      INTO lib_id;

  ELSE
    -- muuda

    UPDATE libs.library
    SET
      kood       = doc_kood,
      nimetus    = doc_nimetus,
      muud       = doc_muud,
      properties = doc_props
    WHERE id = doc_id
    RETURNING id
      INTO lib_id;
  END IF;

  RETURN lib_id;

END;$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(data JSON, userid INTEGER, user_rekvid INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(data JSON, userid INTEGER, user_rekvid INTEGER) TO dbpeakasutaja;
