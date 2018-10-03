-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_salvesta_mk( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_salvesta_mk(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  mk_id         INTEGER;
  mk1_id        INTEGER;
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_data      JSON = data ->> 'data';
  doc_details   JSON = doc_data ->> 'gridData';
  doc_opt       TEXT = coalesce((doc_data ->> 'opt'), '1'); -- 1 -> smk, 2 -> vmk
  doc_type_kood TEXT = coalesce((doc_data ->> 'doc_type_id'), CASE WHEN doc_opt = '1'
    THEN 'SMK'
                                                              ELSE 'VMK' END);
  doc_typeId    INTEGER = (SELECT id
                           FROM libs.library
                           WHERE ltrim(rtrim(kood)) = ltrim(rtrim(upper(doc_type_kood))) AND library = 'DOK'
                           LIMIT 1);
  doc_number    TEXT = coalesce(doc_data ->> 'number', '1');
  doc_kpv       DATE = doc_data ->> 'kpv';
  doc_aa_id     INTEGER = doc_data ->> 'aaid';
  doc_arvid     INTEGER = doc_data ->> 'arvid';
  doc_muud      TEXT = doc_data ->> 'muud';
  tcValuuta     TEXT = coalesce(doc_data ->> 'valuuta', 'EUR');
  tnKuurs       NUMERIC(14, 8) = coalesce(doc_data ->> 'kuurs', '1');
  doc_doklausid INTEGER = doc_data ->> 'doklausid';
  doc_maksepaev DATE = doc_data ->> 'maksepaev';
  doc_selg      TEXT = doc_data ->> 'selg';
  doc_viitenr   TEXT = doc_data ->> 'viitenr';
  json_object   JSON;
  json_record   RECORD;
  new_history   JSONB;
  ids           INTEGER [];
  docs          INTEGER [];
  arv_parent_id INTEGER;
  a_dokvaluuta  TEXT [] = enum_range(NULL :: DOK_VALUUTA);
  is_import     BOOLEAN = data ->> 'import';

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

  IF doc_aa_id IS NULL
  THEN
    SELECT id
    INTO doc_aa_id
    FROM ou.aa
    WHERE parentId = user_rekvid AND pank = 1
    ORDER BY default_ DESC
    LIMIT 1;
    IF NOT found
    THEN
      RAISE NOTICE 'pank not found %', doc_aa_id;
      RETURN 0;
    ELSE
      RAISE NOTICE 'pank: %', doc_aa_id;
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
    VALUES (doc_typeId, '[]' :: JSONB || new_history, user_rekvid, 1)
    RETURNING id
      INTO doc_id;


    INSERT INTO docs.mk (parentid, rekvid, kpv, opt, aaId, number, muud, arvid, doklausid, maksepaev, selg, viitenr)
    VALUES (doc_id, user_rekvid, doc_kpv, doc_opt :: INTEGER, doc_aa_id, doc_number, doc_muud, coalesce(doc_arvid, 0),
                    coalesce(doc_doklausid, 0), coalesce(doc_maksepaev, doc_kpv), coalesce(doc_selg, ''),
            coalesce(doc_viitenr, ''))
    RETURNING id
      INTO mk_id;


    RAISE NOTICE 'mk created doc_id %, mk_id %', doc_id, mk_id;
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

    IF doc_arvid IS NOT NULL
    THEN
      docs = array_append(docs, doc_arvid);
    END IF;

    UPDATE docs.doc
    SET
      doc_type_id = doc_typeId,
      docs_ids    = docs,
      lastupdate  = now(),
      history     = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = doc_id;

    UPDATE docs.mk
    SET
      kpv       = doc_kpv,
      aaid      = doc_aa_id,
      number    = doc_number,
      muud      = doc_muud,
      arvid     = coalesce(doc_arvid, 0),
      doklausid = coalesce(doc_doklausid, 0),
      maksepaev = coalesce(doc_maksepaev, doc_kpv),
      selg      = coalesce(doc_selg, ''),
      viitenr   = coalesce(doc_viitenr, '')
    WHERE parentid = doc_id
    RETURNING id
      INTO mk_id;

  END IF;
  -- вставка в таблицы документа

  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id TEXT, asutusid INTEGER, nomid INTEGER, summa NUMERIC(14, 4), aa TEXT, pank TEXT,
         tunnus TEXT, proj TEXT, konto TEXT, kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT, tp TEXT, valuuta TEXT, kuurs NUMERIC(14, 8),
         journalid INTEGER);

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW' OR
       NOT exists(SELECT id
                  FROM docs.mk1
                  WHERE id = json_record.id :: INTEGER)
    THEN

      INSERT INTO docs.mk1 (parentid, asutusid, nomid, summa, aa, pank, tunnus, proj, konto,
                            kood1, kood2, kood3, kood4, kood5, tp, journalid)
      VALUES (mk_id, json_record.asutusid, json_record.nomid, json_record.summa, json_record.aa, json_record.pank,
                     json_record.tunnus, json_record.proj, json_record.konto,
                     json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5,
              json_record.tp, json_record.journalid)

      RETURNING id
        INTO mk1_id;

      -- add new id into array of ids
      ids = array_append(ids, mk1_id);

    ELSE

      UPDATE docs.mk1
      SET
        nomid    = json_record.nomid,
        asutusid = json_record.asutusid,
        summa    = json_record.summa,
        aa       = json_record.aa,
        pank     = json_record.pank,
        tunnus   = json_record.tunnus,
        proj     = json_record.proj,
        kood1    = json_record.kood1,
        kood2    = json_record.kood2,
        kood3    = json_record.kood3,
        kood4    = json_record.kood4,
        kood5    = json_record.kood5,
        tp       = json_record.tp
      WHERE id = json_record.id :: INTEGER;

      mk1_id = json_record.id :: INTEGER;

      -- add existing id into array of ids
      ids = array_append(ids, mk1_id);

    END IF;

    -- delete record which not in json

    DELETE FROM docs.mk1
    WHERE parentid = mk_id AND id NOT IN (SELECT unnest(ids));


  END LOOP;

  RAISE NOTICE 'arvid %, doc_id %, userid %', doc_arvid, doc_id, userid;

  IF doc_arvid IS NOT NULL
  THEN
    -- произведем оплату счета
    PERFORM docs.sp_tasu_arv(doc_id, doc_arvid, userid);

  END IF;

  RETURN doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
/*
SELECT docs.sp_salvesta_mk('{
  "id": 928,
  "data": {
    "aaid": 2,
    "aa_id": 0,
    "arvid": 5,
    "arvnr": null,
    "bpm": null,
    "created": "15.02.2018 03:02:41",
    "doc": null,
    "docs_ids": null,
    "doc_type_id": null,
    "doklausid": 0,
    "dokprop": null,
    "id": 928,
    "konto": null,
    "kpv": "20180215",
    "lastupdate": "15.02.2018 03:02:41",
    "maksepaev": "20180215",
    "muud": "",
    "number": "001",
    "opt": 1,
    "pank": null,
    "rekvid": 1,
    "selg": "",
    "status": "????????",
    "summa": 0,
    "viitenr": "123455",
    "gridData": [
      {
        "aa": "",
        "asutus": "Asutus",
        "asutusid": 2,
        "id": 150,
        "id1": 150,
        "journalid": null,
        "konto": "111",
        "kood": "pank",
        "kood1": "",
        "kood2": "",
        "kood3": "",
        "kood4": "",
        "kood5": "",
        "kuurs": 1,
        "nimetus": "Raha arvele",
        "nomid": 5,
        "pank": "",
        "parentid": 163,
        "proj": "test",
        "summa": 0,
        "tp": "",
        "tunnus": "1343205",
        "userid": 1,
        "valuuta": "EUR"
      }
    ]
  }
}', 1, 1);

*/