DROP FUNCTION IF EXISTS libs.sp_salvesta_valuuta( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_salvesta_valuuta(
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
  FROM userid u
  WHERE u.rekvid = user_rekvid AND u.id = userId;
  IF userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO libs.library (rekvid, kood, nimetus, library,  tun1, tun2, tun3, tun4, tun5, muud)
    VALUES (user_rekvid, doc_kood, doc_nimetus, doc_library,  doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tun5, doc_muud)
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

  raise notice 'doc_details %',doc_details;

  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM jsonb_to_record(json_object) AS x(id text, parentid INTEGER, kuurs NUMERIC(14, 4), alates date, kuni date);

    raise notice 'json_to_record %',json_record;

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
    THEN

      INSERT INTO libs.valuuta (parentid, kuurs, alates, kuni)
      values (lib_id, json_record.kuurs, json_record.alates, json_record.kuni)
      RETURNING id
        INTO detail_id;
    else
      update libs.valuuta set
        kuurs = json_record.kuurs,
        alates = json_record.alates,
        kuni = json_record.kuni
      RETURNING id
        INTO detail_id;
    end if;

    -- add new id into array of ids
    ids = array_append(ids, detail_id);
  end loop;

  -- delete record which not in json

  DELETE FROM libs.valuuta
  WHERE parentid = doc_id AND id NOT IN (SELECT unnest(ids));

  RETURN lib_id;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;


END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_valuuta(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_valuuta(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT libs.sp_salvesta_valuuta('{"id":0,"data":{"doc_type_id":"VALUUTA","id":0,"kood":"__test7686","library":"VALUUTA","muud":null,"nimetus":"vfp test","rekvid":1,"status":0,"userid":1},"gridData":[{"alates":"20180128","id":0,"kuni":"20190128","kuurs":1,"muud":"","parentid":0,"userid":0}]}'
,1, 1)
*/