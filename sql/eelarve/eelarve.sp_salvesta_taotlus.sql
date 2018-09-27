DROP FUNCTION IF EXISTS eelarve.sp_salvesta_taotlus( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.sp_salvesta_taotlus(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  taotlus_id     INTEGER;
  taotlus1_id    INTEGER;
  userName       TEXT;
  doc_id         INTEGER = data ->> 'id';
  doc_data       JSON = data ->> 'data';
  doc_type_kood  TEXT = 'TAOTLUS';
  doc_type_id    INTEGER = (SELECT id
                            FROM libs.library
                            WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood))) AND library = 'DOK'
                            LIMIT 1);
  doc_details    JSON = doc_data ->> 'gridData';
  doc_number     TEXT = coalesce(doc_data ->> 'number', '1');
  doc_kpv        DATE = doc_data ->> 'kpv';
  doc_koostajaid INTEGER = doc_data ->> 'koostajaid';
  doc_ametnikid  INTEGER = doc_data ->> 'ametnikid';
  doc_aktseptid  INTEGER = doc_data ->> 'aktseptid';
  doc_aasta      INTEGER = doc_data ->> 'aasta';
  doc_kuu        INTEGER = doc_data ->> 'kuu';
  doc_allkiri    INTEGER = coalesce((doc_data ->> 'allkiri') :: INTEGER, 0);
  doc_tunnus     INTEGER = doc_data ->> 'tunnus';
  doc_muud       TEXT = doc_data ->> 'muud';
  json_object    JSON;
  json_record    RECORD;
  new_history    JSONB;
  ids            INTEGER [];
  docs           INTEGER [];
  is_import      BOOLEAN = data ->> 'import';
BEGIN

  SELECT kasutaja
  INTO userName
  FROM userid u
  WHERE u.rekvid = user_rekvid AND u.id = userId;
  IF is_import IS NULL AND userName IS NULL
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

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;

    INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
    VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid,
            array_position((enum_range(NULL :: DOK_STATUS)), 'active'))
    RETURNING id
      INTO doc_id;

    INSERT INTO eelarve.taotlus (parentid, rekvid, kpv, number, koostajaid, ametnikId, aktseptid, allkiri, tunnus, muud, status, aasta)
    VALUES
      (doc_id, user_rekvid, doc_kpv, doc_number, doc_koostajaid, doc_ametnikId, doc_aktseptid, doc_allkiri, doc_tunnus,
               doc_muud, 1, doc_aasta)
    RETURNING id
      INTO taotlus_id;

  ELSE
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user) row;

    -- устанавливаем связи с документами

    -- получим связи документа
    SELECT docs_ids
    INTO docs
    FROM docs.doc
    WHERE id = doc_id;

    -- will check if arvId exists
    UPDATE docs.doc
    SET
      docs_ids   = docs,
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = doc_id;

    UPDATE eelarve.taotlus
    SET
      kpv        = doc_kpv,
      koostajaid = doc_koostajaid,
      ametnikid  = doc_ametnikid,
      aasta      = doc_aasta,
      kuu        = doc_kuu,
      allkiri    = doc_allkiri,
      tunnus     = doc_tunnus,
      number     = doc_number,
      muud       = doc_muud
    WHERE parentid = doc_id
    RETURNING id
      INTO taotlus_id;

  END IF;
  -- вставка в таблицы документа


  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id TEXT, summa NUMERIC(14, 4), tunnus TEXT, proj TEXT,
         kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT, muud TEXT, selg TEXT, eelarveid INTEGER, eelprojid INTEGER);

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
       NOT exists(SELECT id
                  FROM eelarve.taotlus1
                  WHERE id = json_record.id :: INTEGER)
    THEN
      INSERT INTO eelarve.taotlus1 (parentid, summa, tunnus, proj, kood1, kood2, kood3, kood4, kood5, muud, selg, eelarveid, eelprojid)
      VALUES
        (taotlus_id, json_record.summa, json_record.tunnus, json_record.proj,
                     json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5,
                     json_record.muud, json_record.selg, json_record.eelarveid, json_record.eelprojid)

      RETURNING id
        INTO taotlus1_id;

      -- add new id into array of ids
      ids = array_append(ids, taotlus1_id);

    ELSE

      UPDATE eelarve.taotlus1
      SET
        summa  = json_record.summa,
        tunnus = json_record.tunnus,
        proj   = json_record.proj,
        kood1  = json_record.kood1,
        kood2  = json_record.kood2,
        kood3  = json_record.kood3,
        kood4  = json_record.kood4,
        kood5  = json_record.kood5,
        muud   = json_record.muud,
        selg   = json_record.selg
      WHERE id = json_record.id :: INTEGER;

      taotlus1_id = json_record.id :: INTEGER;

      -- add existing id into array of ids
      ids = array_append(ids, taotlus1_id);

    END IF;

    -- delete record which not in json

    DELETE FROM eelarve.taotlus1
    WHERE parentid = taotlus_id AND id NOT IN (SELECT unnest(ids));

  END LOOP;

  RETURN doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_taotlus(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_taotlus(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT eelarve.sp_salvesta_taotlus('{"id":0,"data": {"aasta":2018,"aktseptid":null,"aktseptja":null,"allkiri":null,"ametnikid":null,"bpm":null,"created":"17.03.2018 05:03:42","doc":"Eelarve taotlus","doc_status":0,"doc_type_id":"TAOTLUS","esitaja":null,"id":0,"koostaja":null,"koostajaid":1,"kpv":"20180317","kuu":0,"lastupdate":"17.03.2018 05:03:42","muud":null,"number":"1","rekvid":1,"status":"????????","summa":100,"tunnus":null,"userid":1,"gridData":[{"eelarveid":0,"eelprojid":0,"id":0,"kood1":"test","kood2":"LE-P","kood3":"","kood4":"","kood5":"123","markused":"","muud":"","parentid":0,"proj":"","selg":"test","selgrea":"","status":0,"summa":100,"tunnus":"","userid":0}]}}', 1, 1);
*/
