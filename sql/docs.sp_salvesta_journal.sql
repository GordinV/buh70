DROP FUNCTION IF EXISTS docs.sp_salvesta_journal( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_salvesta_journal(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  journal_id    INTEGER;
  journal1_id   INTEGER;
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_type_kood TEXT = 'JOURNAL'/*data->>'doc_type_id'*/;
  doc_type_id   INTEGER = (SELECT id
                           FROM libs.library
                           WHERE kood = doc_type_kood AND library = 'DOK'
                           LIMIT 1);
  doc_details   JSON = data ->> 'gridData';
  doc_data      JSON = data ->> 'data';
  doc_number    TEXT = doc_data ->> 'number';
  doc_asutusid  INTEGER = doc_data ->> 'asutusid';
  doc_dok       TEXT = doc_data ->> 'dok';
  doc_kpv       DATE = doc_data ->> 'kpv';
  doc_selg      TEXT = doc_data ->> 'selg';
  doc_muud      TEXT = doc_data ->> 'muud';
  tcValuuta     TEXT = coalesce(doc_data ->> 'valuuta', 'EUR');
  tnKuurs       NUMERIC(14, 8) = coalesce(doc_data ->> 'kuurs', '1');
  json_object   JSON;
  json_record   RECORD;
  new_history   JSONB;
  ids           INTEGER [];
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

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;


    INSERT INTO docs.doc (doc_type_id, history, rekvid)
    VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid)
    RETURNING id
      INTO doc_id;

    INSERT INTO docs.journal (parentid, rekvid, userid, kpv, asutusid, dok, selg, muud)
    VALUES (doc_id, user_rekvid, userId, doc_kpv, doc_asutusid, doc_dok, doc_selg, doc_muud)
    RETURNING id
      INTO journal_id;

    INSERT INTO docs.journalid (journalid, rekvid, aasta, number)
    VALUES (journal_id, user_rekvid, (date_part('year' :: TEXT, doc_kpv) :: INTEGER), (SELECT max(number) + 1
                                                                                       FROM docs.journalid
                                                                                       WHERE rekvId = user_rekvid AND
                                                                                             aasta =
                                                                                             (date_part('year' :: TEXT,
                                                                                                        doc_kpv) :: INTEGER)));


  ELSE
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user) row;

    UPDATE docs.doc
    SET lastupdate = now(),
      history      = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = doc_id;

    UPDATE docs.journal
    SET
      kpv      = doc_kpv,
      asutusid = doc_asutusid,
      dok      = doc_dok,
      muud     = doc_muud,
      selg     = doc_selg
    WHERE parentid = doc_id
    RETURNING id
      INTO journal_id;

  END IF;
  -- вставка в таблицы документа


  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id TEXT, summa NUMERIC(14, 4), deebet TEXT, kreedit TEXT, tunnus TEXT, proj TEXT,
         kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT, lisa_d TEXT, lisa_k TEXT, valuuta TEXT, kuurs NUMERIC(14, 8));

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
       NOT exists(SELECT id
                  FROM docs.journal1
                  WHERE id = json_record.id :: INTEGER)
    THEN
      INSERT INTO docs.journal1 (parentid, deebet, kreedit, summa, tunnus, proj, kood1, kood2, kood3, kood4, kood5, lisa_d, lisa_k, valuuta, kuurs, valsumma)
      VALUES
        (journal_id, json_record.deebet, json_record.kreedit, json_record.summa, json_record.tunnus, json_record.proj,
                     json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5,
         json_record.lisa_d, json_record.lisa_k,
         coalesce(json_record.valuuta, 'EUR'), coalesce(json_record.kuurs, 1),
         coalesce(json_record.kuurs, 1) * json_record.summa)
      RETURNING id
        INTO journal1_id;

      RAISE NOTICE 'journal1_id %', journal1_id;

      -- add new id into array of ids
      ids = array_append(ids, journal1_id);

      -- valuuta
      INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
      VALUES (journal1_id, 1, tcValuuta, tnKuurs);


    ELSE

      UPDATE docs.journal1
      SET
        deebet   = json_record.deebet,
        kreedit  = json_record.kreedit,
        summa    = json_record.summa,
        tunnus   = json_record.tunnus,
        proj     = json_record.proj,
        kood1    = json_record.kood1,
        kood2    = json_record.kood2,
        kood3    = json_record.kood3,
        kood4    = json_record.kood4,
        kood5    = json_record.kood5,
        lisa_d   = json_record.lisa_d,
        lisa_k   = json_record.lisa_k,
        kuurs    = json_record.kuurs,
        valuuta  = json_record.valuuta,
        valsumma = json_record.kuurs * json_record.summa
      WHERE id = json_record.id :: INTEGER;

      journal1_id = json_record.id :: INTEGER;

      -- add existing id into array of ids
      ids = array_append(ids, journal1_id);


      RAISE NOTICE 'for update journal1_id %', journal1_id;


      IF NOT exists(SELECT id
                    FROM docs.dokvaluuta1
                    WHERE dokid = journal1_id AND dokliik = 1)
      THEN
        -- if record does 
        INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
        VALUES (journal1_id, 1, tcValuuta, tnKuurs);

      END IF;
    END IF;

    -- delete record which not in json

    DELETE FROM docs.journal1
    WHERE parentid = journal_id AND id NOT IN (SELECT unnest(ids));


  END LOOP;

  RETURN doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_salvesta_journal(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_journal(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
sasaving data:{"id":40,"doc_type_id":"JOURNAL","data":{"id":40,"created":"2016-05-24T14:49:46.198805","lastupdate":"2016-05-25T14:15:08.329755","bpm":null,"doc":"Lausendid","doc_type_id":"JOURNAL","status":"Черновик","number":2,"rekvid":1,"kpv":"2016-05-21","asutusid":1,"dok":"lisa 3","selg":"selg parandus","muud":"muud","summa":122.01,"regkood":"123456789           ","asutus":"isik, töötaja"},"details":[
{"id":16,"parentid":14,"summa":"100.0000","dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"113","lisa_k":null,"kreedit":"122","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"100.0000","tunnus":"tunnus","proj":"proj"},
{"id":21,"parentid":14,"summa":22.01,"dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"111","lisa_k":null,"kreedit":"222","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"22.0000","tunnus":null,"proj":null}]}

select docs.sp_salvesta_journal('{"id":40,"doc_type_id":"JOURNAL","data":{"id":40,"created":"2016-05-24T14:49:46.198805","lastupdate":"2016-05-25T14:15:08.329755","bpm":null,"doc":"Lausendid","doc_type_id":"JOURNAL","status":"Черновик","number":2,"rekvid":1,"kpv":"2016-05-21","asutusid":1,"dok":"lisa 3","selg":"selg parandus","muud":"muud","summa":122.01,"regkood":"123456789           ","asutus":"isik, töötaja"},"details":[
{"id":16,"parentid":14,"summa":"100.0000","dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"113","lisa_k":null,"kreedit":"122","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"100.0000","tunnus":"tunnus","proj":"proj"},
{"id":21,"parentid":14,"summa":22.01,"dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"111","lisa_k":null,"kreedit":"222","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"22.0000","tunnus":null,"proj":null}]}',1, 1);

select * from docs.journal1 where parentid = 14

*/
