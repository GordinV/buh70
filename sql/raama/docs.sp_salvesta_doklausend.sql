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
  FROM ou.userid u
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

raise notice 'doc_id %, doc_details %', doc_id, doc_details ;

  -- вставка в таблицы документа
  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP

      raise notice 'json_object %', json_object;
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
  END LOOP;

  -- delete record which not in json
  DELETE FROM docs.doklausend
  WHERE parentid = doc_id AND id NOT IN (SELECT unnest(ids));


  RETURN doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_salvesta_doklausend(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_doklausend(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


select docs.sp_salvesta_doklausend('{"id":6691,"data":{"dok":"","id":6691,"muud":"","rekvid":63,"selg":"arve, Importeeritud e-arvete registrist teenused","status":1,"userid":2477,"gridData":[{"deebet":"601000","id":17470,"id1":17470,"kood1":"01112","kood2":"LE-P","kood3":"01","kood4":"RF","kood5":"5513","kreedit":"201000","lisa_d":"014001","lisa_k":"800599","muud":null,"parentid":6691,"properties":null,"summa":2,"userid":2477},{"deebet":"551307","id":17471,"id1":17471,"kood1":"01112","kood2":"LE-P","kood3":"02","kood4":"RF","kood5":"5513","kreedit":"201000","lisa_d":"800599","lisa_k":"800599","muud":null,"parentid":6691,"properties":null,"summa":10,"userid":2477}]},{"dok":"","id":6691,"muud":"","rekvid":63,"selg":"arve, Importeeritud e-arvete registrist teenused","status":1,"userid":2477,"gridData":[{"deebet":"601000","id":17470,"id1":17470,"kood1":"01112","kood2":"LE-P","kood3":"01","kood4":"RF","kood5":"5513","kreedit":"201000","lisa_d":"014001","lisa_k":"800599","muud":null,"parentid":6691,"properties":null,"summa":2,"userid":2477},{"deebet":"551307","id":17471,"id1":17471,"kood1":"01112","kood2":"LE-P","kood3":"02","kood4":"RF","kood5":"5513","kreedit":"201000","lisa_d":"800599","lisa_k":"800599","muud":null,"parentid":6691,"properties":null,"summa":10,"userid":2477}]}}',2477, 63);

/*


select * from docs.doklausheader
select * from docs.doklausend
*/
