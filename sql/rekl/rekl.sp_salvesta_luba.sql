DROP FUNCTION IF EXISTS rekl.sp_salvesta_luba( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION rekl.sp_salvesta_luba(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  luba_id       INTEGER;
  luba1_id      INTEGER;
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_data      JSON = data ->> 'data';
  doc_type_kood TEXT = 'LUBA';
  doc_type_id   INTEGER = (SELECT id
                           FROM libs.library
                           WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood))) AND library = 'DOK'
                           LIMIT 1);
  doc_details   JSON = doc_data ->> 'gridData';
  doc_number    TEXT = coalesce(doc_data ->> 'number', '1');
  doc_asutusid  INTEGER = doc_data ->> 'asutusid';
  doc_algkpv    DATE = doc_data ->> 'algkpv';
  doc_loppkpv   DATE = doc_data ->> 'loppkpv';
  doc_summa     NUMERIC(14, 2) = doc_data ->> 'summa';
  doc_jaak      NUMERIC(14, 2) = doc_data ->> 'jaak';
  doc_volg      NUMERIC(14, 2) = doc_data ->> 'volg';
  doc_alus      TEXT = doc_data ->> 'alus';
  doc_kord      TEXT = doc_data ->> 'kord';
  doc_muud      TEXT = doc_data ->> 'muud';
  doc_staatus   INTEGER = doc_data ->> 'staatus';
  json_object   JSON;
  json_record   RECORD;
  new_history   JSONB;
  ids           INTEGER [];
  docs          INTEGER [];
  is_import     BOOLEAN = data ->> 'import';
  is_new BOOLEAN = FALSE;
BEGIN

  SELECT kasutaja
  INTO userName
  FROM ou.userid u
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
    is_new = TRUE;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;

    INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
    VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid, 1)
    RETURNING id
      INTO doc_id;

    INSERT INTO rekl.luba (parentid, asutusid, rekvid, algkpv, loppkpv, number, alus, muud, kord, summa, staatus)
    VALUES
      (doc_id, doc_asutusid, user_rekvid, doc_algkpv, doc_loppkpv, doc_number, doc_alus, doc_muud, doc_kord, doc_summa,
               CASE WHEN is_import IS NOT NULL
                 THEN doc_staatus
               ELSE 1 END)
    RETURNING id
      INTO luba_id;

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
      history    = coalesce(history, '[]') :: JSONB || new_history,
      status = CASE WHEN is_import IS NOT NULL THEN 1 ELSE status END
    WHERE id = doc_id;

    UPDATE rekl.luba
    SET
      algkpv   = doc_algkpv,
      loppkpv  = doc_loppkpv,
      asutusid = doc_asutusid,
      alus     = doc_alus,
      kord     = doc_kord,
      number   = doc_number,
      muud     = doc_muud,
      summa    = doc_summa,
      jaak     = CASE WHEN is_import IS NOT NULL
        THEN doc_jaak
                 ELSE jaak END,
      volg     = CASE WHEN is_import IS NOT NULL
        THEN doc_volg
                 ELSE volg END,
      staatus = CASE WHEN is_import IS NOT NULL THEN doc_staatus ELSE staatus END
    WHERE parentid = doc_id
    RETURNING id
      INTO luba_id;

  END IF;

  -- вставка в таблицы документа

  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id TEXT, nomid INTEGER, summa NUMERIC(14, 4), kogus NUMERIC(14, 4),
         maksumaar NUMERIC(12, 2), soodus_tyyp INTEGER, soodus NUMERIC(14, 2), staatus INTEGER, muud TEXT);

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
       NOT exists(SELECT id
                  FROM rekl.luba1
                  WHERE id = json_record.id :: INTEGER)
    THEN
      INSERT INTO rekl.luba1 (parentid, nomid, summa, kogus, maksumaar, soodus_tyyp, soodus, staatus, muud)
      VALUES
        (luba_id, json_record.nomid, json_record.summa, coalesce(json_record.kogus, 1), json_record.maksumaar,
         json_record.soodus_tyyp, json_record.soodus, coalesce(json_record.staatus, 1), json_record.muud)
      RETURNING id
        INTO luba1_id;

      -- add new id into array of ids
      ids = array_append(ids, luba1_id);

    ELSE

      UPDATE rekl.luba1
      SET
        nomid       = json_record.nomid,
        summa       = json_record.summa,
        kogus       = json_record.kogus,
        maksumaar   = json_record.maksumaar,
        soodus_tyyp = json_record.soodus_tyyp,
        soodus      = json_record.soodus,
        muud        = json_record.muud
      WHERE id = json_record.id :: INTEGER;

      luba1_id = json_record.id :: INTEGER;

      -- add existing id into array of ids
      ids = array_append(ids, luba1_id);

    END IF;


  END LOOP;
  -- delete record which not in json

  DELETE FROM rekl.luba1
  WHERE parentid = luba_id AND id NOT IN (SELECT unnest(ids));

  -- uuendame dekl list

  IF is_import IS NULL
  THEN
    PERFORM rekl.sp_calc_dekl(doc_id, userid);
  END IF;
  RETURN doc_id;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION rekl.sp_salvesta_luba(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_salvesta_luba(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT docs.sp_salvesta_avans('{
  "id": 0,
  "data": {
    "asutusid": 1,
    "bpm": null,
    "created": "09.03.2018 11:03:10",
    "doc": "Avansiaruanne",
    "docs_ids": "",
    "doc_type_id": "AVANS",
    "dokprop": "Avans",
    "dokpropid": 21,
    "id": 1,
    "jaak": 0,
    "journalid": null,
    "konto": "114",
    "kpv": "20180309",
    "lastupdate": "09.03.2018 11:03:10",
    "lausend": null,
    "muud": null,
    "number": "10",
    "rekvid": null,
    "selg": "test",
    "status": "????????",
    "summa": 0,
    "gridData": [
      {
        "id": 0,
        "kbm": 0,
        "kokku": 0,
        "konto": "114",
        "kood": "AVANS",
        "kood1": "test",
        "kood2": "__test9088",
        "kood3": "",
        "kood4": "",
        "kood5": "123",
        "kuurs": 1,
        "muud": "",
        "nimetus": "Avans",
        "nomid": 75,
        "parentid": 0,
        "proj": "",
        "summa": 22,
        "tunnus": "",
        "userid": 0,
        "valuuta": "EUR"
      }
    ]
  }
}', 1, 1);


select * from libs.nomenklatuur where dok = 'SORDER' limit 10
*/
