DROP FUNCTION IF EXISTS ou.sp_salvesta_menupohi( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_salvesta_menupohi(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  menu_id     INTEGER;
  userName    TEXT;
  doc_id      INTEGER = data ->> 'id';
  doc_data    JSON = data ->> 'data';
  doc_pad     TEXT = doc_data ->> 'pad';
  doc_bar     TEXT = doc_data ->> 'bar';
  doc_idx     INTEGER = doc_data ->> 'idx';
  doc_name    TEXT = doc_data ->> 'name';
  doc_eesti   TEXT = doc_data ->> 'eesti';
  doc_vene    TEXT = doc_data ->> 'vene';
  doc_proc    TEXT = doc_data ->> 'proc';
  doc_groups  JSON = doc_data ->> 'groups';
  doc_users   JSON = doc_data ->> 'users';
  doc_modules JSON = doc_data ->> 'modules';
  doc_level   INTEGER = doc_data ->> 'level';
  json_object JSONB;
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

  SELECT row_to_json(row)
  INTO json_object
  FROM (SELECT
          now()       AS created,
          userName    AS user,
          doc_name    AS name,
          doc_eesti   AS eesti,
          doc_vene    AS vene,
          doc_groups  AS groups,
          doc_modules AS modules,
          doc_users   AS users,
          doc_proc    AS proc,
          doc_level   AS level) row;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO ou.menupohi (pad, bar, idx, properties, status)
    VALUES (doc_pad, doc_bar, doc_idx, json_object, 'active')
    RETURNING id
      INTO menu_id;
  ELSE

    UPDATE ou.menupohi
    SET
      pad        = doc_pad,
      bar        = doc_bar,
      idx        = doc_idx,
      properties = json_object
    WHERE id = doc_id
    RETURNING id
      INTO menu_id;

  END IF;

  RETURN menu_id;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;


END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION ou.sp_salvesta_menupohi(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_menupohi(JSON, INTEGER, INTEGER) TO dbadmin;


/*

SELECT ou.sp_salvesta_menupohi('{"id":4,"data":{"pad":"test","bar":"","idx":1,"name":"Test", "vene": "Тест", "eesti": "Testid", "level": 1, "users": ["vlad"], "groups": ["KASUTAJA", "PEAKASUTAJA"], "modules": ["EELARVE"]}}'
,1, 1)

select * from ou.menupohi
*/