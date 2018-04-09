DROP FUNCTION IF EXISTS docs.sp_salvesta_doklausend( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_salvesta_doklausend(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_data      JSON = data ->> 'data';
  doc_type_kood TEXT = 'DOKLAUSEND';
  doc_type_id   INTEGER = (SELECT id
                           FROM libs.library
                           WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood))) AND library = 'DOK'
                           LIMIT 1);
  doc_details   JSON = doc_data ->> 'gridData';
  doc_dok       TEXT = doc_data ->> 'dok';
  doc_selg      TEXT = doc_data ->> 'selg';
  doc_muud      TEXT = doc_data ->> 'muud';
  json_object   JSON;
  json_record   RECORD;
  d1_id         INTEGER;
  new_history   JSONB;
  ids           INTEGER [];
  docs          INTEGER [];
BEGIN

  SELECT kasutaja
  INTO userName
  FROM userid u
  WHERE u.rekvid = user_rekvid AND u.id = userId;
  IF userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN

    INSERT INTO docs.doklausheader (rekvid, dok, selg, muud, status, userid)
    VALUES
      (user_rekvid, coalesce(doc_dok,''), doc_selg, doc_muud, 1, userid)
    RETURNING id
      INTO doc_id;
  ELSE

    UPDATE docs.doklausheader
    SET
      dok  = doc_dok,
      selg = doc_selg,
      muud = doc_muud
    WHERE id = doc_id;

  END IF;

  -- вставка в таблицы документа
  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id TEXT, summa NUMERIC(14, 4), deebet TEXT, kreedit TEXT, lisa_d TEXT,
         lisa_k TEXT, kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT );

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
    THEN
      INSERT INTO docs.doklausend (parentid, deebet, kreedit, summa, lisa_d, lisa_k, kood1, kood2, kood3, kood4, kood5)
      VALUES
        (doc_id, json_record.deebet, json_record.kreedit, json_record.summa, json_record.lisa_d, json_record.lisa_k,
                 json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5)

      RETURNING id
        INTO d1_id;

      -- add new id into array of ids
      ids = array_append(ids, d1_id);

    ELSE

      UPDATE docs.doklausend
      SET
        deebet  = json_record.deebet,
        kreedit = json_record.kreedit,
        lisa_d  = json_record.lisa_d,
        lisa_k  = json_record.lisa_k,
        summa   = json_record.summa,
        kood1   = json_record.kood1,
        kood2   = json_record.kood2,
        kood3   = json_record.kood3,
        kood4   = json_record.kood4,
        kood5   = json_record.kood5
      WHERE id = json_record.id :: INTEGER;

      d1_id = json_record.id :: INTEGER;

      -- add existing id into array of ids
      ids = array_append(ids, d1_id);
    END IF;
    -- delete record which not in json

    DELETE FROM docs.doklausend
    WHERE parentid = doc_id AND id NOT IN (SELECT unnest(ids));

  END LOOP;

  RETURN doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_salvesta_doklausend(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_doklausend(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*

select docs.sp_salvesta_doklausend('{"id":3,"data": {"dok":"test model","id":0,"muud":null,"rekvid":1,"selg":"__test5548","status":1,"userid":1,"gridData":[{"deebet":"111","id":0,"id1":0,"kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kreedit":"113","lisa_d":"","lisa_k":"","muud":"","parentid":0,"properties":"","summa":100,"userid":0}]}}
',1, 1);

select * from docs.doklausheader
select * from docs.doklausend
*/
