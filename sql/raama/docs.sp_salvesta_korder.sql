DROP FUNCTION IF EXISTS docs.sp_salvesta_korder(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_korder(data JSON,
                                                   userid INTEGER,
                                                   user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  korder_id         INTEGER;
  korder1_id        INTEGER;
  userName          TEXT;
  doc_id            INTEGER = data ->> 'id';
  doc_data          JSON    = data ->> 'data';
  doc_tyyp          TEXT    = coalesce(doc_data ->> 'tyyp', '1'); -- 1 -> sorder, 2 -> vorder
  doc_type_kood     TEXT    = CASE
                                WHEN doc_tyyp = '1'
                                  THEN 'SORDER'
                                ELSE 'VORDER' END/*data->>'doc_type_id'*/;
  doc_type_id       INTEGER = (SELECT id
                               FROM libs.library
                               WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood)))
                                 AND library = 'DOK'
                               LIMIT 1);
  doc_details       JSON    = doc_data ->> 'gridData';
  doc_number        TEXT    = coalesce(doc_data ->> 'number', '1');
  doc_kpv           DATE    = doc_data ->> 'kpv';
  doc_asutusid      INTEGER = doc_data ->> 'asutusid';
  doc_kassa_id      INTEGER = doc_data ->> 'kassa_id';
  doc_doklausid     INTEGER = doc_data ->> 'doklausid';
  doc_dokument      TEXT    = doc_data ->> 'dokument';
  doc_nimi          TEXT    = doc_data ->> 'nimi';
  doc_aadress       TEXT    = doc_data ->> 'aadress';
  doc_alus          TEXT    = doc_data ->> 'alus';
  doc_arvid         INTEGER = doc_data ->> 'arvid';
  doc_muud          TEXT    = doc_data ->> 'muud';
  doc_summa         NUMERIC = doc_data ->> 'summa';
  json_object       JSON;
  json_record       RECORD;
  new_history       JSONB;
  ids               INTEGER [];
  docs              INTEGER [];
  arv_parent_id     INTEGER;
  previous_arv_id   INTEGER;
  DOC_STATUS_ACTIVE INTEGER = 1; -- документ открыт для редактирования
  is_import         BOOLEAN = data ->> 'import';
BEGIN

  SELECT kasutaja
         INTO userName
  FROM ou.userid u
  WHERE u.rekvid = user_rekvid
    AND u.id = userId;
  IF is_import IS NULL AND userName IS NULL
  THEN
    RAISE NOTICE 'User not found %', user;
    RETURN 0;
  END IF;

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

  IF doc_kassa_id IS NULL
  THEN
    SELECT id
           INTO doc_kassa_id
    FROM ou.aa
    WHERE parentId = user_rekvid
      AND kassa = 1
    ORDER BY default_ DESC
    LIMIT 1;
    IF NOT found
    THEN
      RAISE NOTICE 'Kassa not found %', doc_kassa_id;
      RETURN 0;
    ELSE
      --      RAISE NOTICE 'kassa: %', doc_kassa_id;
    END IF;
  END IF;

  IF doc_arvid IS NOT NULL
  THEN
    SELECT parentid
           INTO arv_parent_id
    FROM docs.arv
    WHERE id = doc_arvid;
    IF (SELECT count(*)
        FROM (
               SELECT unnest(docs) AS element) qry
        WHERE element = arv_parent_id) = 0
    THEN
      docs = array_append(docs, arv_parent_id);
    END IF;
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
    VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid, DOC_STATUS_ACTIVE)
           RETURNING id
             INTO doc_id;


    INSERT INTO docs.korder1 (parentid, rekvid, userid, kpv, asutusid, tyyp, kassaId, number, dokument, nimi,
                              aadress, alus, muud, summa, arvid, doklausid)
    VALUES
    (doc_id, user_rekvid, userId, doc_kpv, doc_asutusid, doc_tyyp :: INTEGER, doc_kassa_id, doc_number, doc_dokument,
     doc_nimi,
     doc_aadress, doc_alus, doc_muud, doc_summa, doc_arvid, doc_doklausid)
    RETURNING id
      INTO korder_id;

    --    raise notice 'korder_id %,  doc_id %', korder_id,  doc_id;

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

    IF doc_arvid IS NULL OR empty(doc_arvid)
    THEN
      SELECT arvid
             INTO previous_arv_id
      FROM docs.arv
      WHERE parentid = doc_id;
      IF previous_arv_id IS NOT NULL
      THEN
        -- remove from docs_ids
        docs = array_remove(docs, previous_arv_id);
        IF array_length(docs, 1) = 0
        THEN
          docs = NULL;
        END IF;
      END IF;
    ELSE
      docs = array_append(docs, doc_arvid);
    END IF;


    UPDATE docs.doc
    SET
      docs_ids   = docs,
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = doc_id;

    UPDATE docs.korder1
    SET
      kpv       = doc_kpv,
      asutusid  = doc_asutusid,
      dokument  = doc_dokument,
      kassaid   = doc_kassa_id,
      doklausid = doc_doklausid,
      number    = doc_number,
      nimi      = doc_nimi,
      aadress   = doc_aadress,
      muud      = doc_muud,
      alus      = doc_alus,
      summa     = doc_summa,
      arvid     = doc_arvid
    WHERE parentid = doc_id
      RETURNING id
        INTO korder_id;

  END IF;
  -- вставка в таблицы документа


  FOR json_object IN
    SELECT *
    FROM json_array_elements(doc_details)
    LOOP
      SELECT *
             INTO json_record
      FROM json_to_record(
               json_object) AS x (id TEXT, nomid INTEGER, summa NUMERIC(14, 4), nimetus TEXT, tunnus TEXT, proj TEXT,
                                  konto TEXT, kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT, tp TEXT,
                                  muud TEXT);

      IF json_record.nimetus IS NULL
      THEN
        json_record.nimetus = (SELECT nimetus
                               FROM libs.nomenklatuur
                               WHERE id = json_record.nomid);
      END IF;

      IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
         NOT exists(SELECT id
                    FROM docs.journal1
                    WHERE id = json_record.id :: INTEGER)
      THEN
        INSERT INTO docs.korder2 (parentid, nomid, nimetus, summa, tunnus, proj, konto, kood1, kood2, kood3, kood4,
                                  kood5, tp, muud)
        VALUES
        (korder_id, json_record.nomid, json_record.nimetus, json_record.summa, json_record.tunnus, json_record.proj,
         json_record.konto,
         json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5,
         json_record.tp, json_record.muud)

        RETURNING id
          INTO korder1_id;

        -- add new id into array of ids
        ids = array_append(ids, korder1_id);

      ELSE

        UPDATE docs.korder2
        SET
          nomid   = json_record.nomid,
          nimetus = json_record.nimetus,
          summa   = json_record.summa,
          tunnus  = json_record.tunnus,
          proj    = json_record.proj,
          kood1   = json_record.kood1,
          kood2   = json_record.kood2,
          kood3   = json_record.kood3,
          kood4   = json_record.kood4,
          kood5   = json_record.kood5,
          tp      = json_record.tp,
          muud    = json_record.muud
        WHERE id = json_record.id :: INTEGER;

        korder1_id = json_record.id :: INTEGER;

        -- add existing id into array of ids
        ids = array_append(ids, korder1_id);

      END IF;

      -- delete record which not in json

      DELETE
      FROM docs.korder2
      WHERE parentid = korder_id
        AND id NOT IN (SELECT unnest(ids));


    END LOOP;

  IF doc_arvid IS NOT NULL
  THEN
    -- произведем оплату счета
    PERFORM docs.sp_tasu_arv(doc_id, doc_arvid, userid);

  END IF;

  RETURN doc_id;

END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION docs.sp_salvesta_korder(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_korder(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*

select docs.sp_salvesta_korder('{"id": 0, "data": {"id": 0, "kpv": "2018-03-15", "alus": "", "muud": "", "nimi": "1", "tyyp": 1, "arvid": 200513, "summa": 8.3900, "number": "15032018            ", "aadress": "1", "doktyyp": 0, "kassaid": 350, "asutusid": 121507, "dokument": "15032018", "gridData": [{"id": 0, "tp": "800699", "muud": "Raamatukogu tulud majandustegevusest                                                                                    ", "proj": "", "konto": "103000", "kood1": "08201", "kood2": "80", "kood3": "", "kood4": "", "kood5": "3221", "nomid": 8706, "summa": 8.3900, "tunnus": "0820101"}]}, "import": true}',1, 75);


select docs.sp_salvesta_korder('{"id":0,"data": {"arvid":193,"aadress":"Aadress","alus":"Alus","arvid":87,"arvnr":null,"asutus":"Asutus","asutusid":2,"bpm":null,"created":"19.02.2018 09:02:11","doc":"Sissemakse kassaorder","docs_ids":null,"doc_type_id":"SORDER","doklausid":null,"dokprop":null,"dokument":"dok","id":937,"journalid":null,"kassa":"Kassa1","kassa_id":1,"konto":"","kpv":"20180219","lastupdate":"19.02.2018 09:02:11","lausnr":0,"muud":null,"nimi":"Isik","number":"13","regkood":"6543423423423","rekvid":1,"status":"????????","summa":20,"tyyp":1,"gridData":[{"id":159,"id1":159,"konto":"113","kood":"PANK","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kuurs":1,"nimetus":"Raha pankarvele","nimetus1":"Raha pankarvele","nomid":3,"parentid":155,"proj":"","summa":30,"tp":"","tunnus":"","uhik":"","userid":1,"valuuta":"EUR"}]}}
',1, 1);



select * from libs.nomenklatuur where dok = 'SORDER' limit 10
*/
