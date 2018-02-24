DROP FUNCTION IF EXISTS docs.sp_salvesta_arv( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arv(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  arv_id        INTEGER;
  arv1_id       INTEGER;
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_type_kood TEXT = 'ARV'/*data->>'doc_type_id'*/;
  doc_type_id   INTEGER = (SELECT id
                           FROM libs.library
                           WHERE kood = doc_type_kood AND library = 'DOK'
                           LIMIT 1);
  doc_data      JSON = data ->> 'data';
  doc_details   JSON = doc_data ->> 'gridData';
  doc_arvid     INTEGER = doc_data ->> 'arvid';
  doc_number    TEXT = doc_data ->> 'number';
  doc_summa     NUMERIC(14, 4) = coalesce((doc_data ->> 'summa') :: NUMERIC, 0);
  doc_liik      INTEGER = doc_data ->> 'liik';
  doc_operid    INTEGER = doc_data ->> 'operid';
  doc_asutusid  INTEGER = doc_data ->> 'asutusid';
  doc_lisa      TEXT = doc_data ->> 'lisa';
  doc_kpv       DATE = doc_data ->> 'kpv';
  doc_tahtaeg   DATE = doc_data ->> 'tahtaeg';
  doc_kbmta     NUMERIC(14, 4) = coalesce((doc_data ->> 'kbmta') :: NUMERIC, 0);
  doc_kbm       NUMERIC(14, 4) = coalesce((doc_data ->> 'kbm') :: NUMERIC, 0);
  doc_muud      TEXT = doc_data ->> 'muud';
  doc_objektid  INTEGER = doc_data ->> 'objektid';
  doc_objekt    TEXT = doc_data ->> 'objekt';
  tcValuuta     TEXT = coalesce(doc_data ->> 'valuuta', 'EUR');
  tnKuurs       NUMERIC(14, 8) = coalesce(doc_data ->> 'kuurs', '1');
  tnDokLausId   INTEGER = coalesce((doc_data ->> 'doklausid') :: INTEGER, 1);
  json_object   JSON;
  json_record   RECORD;
  new_history   JSONB;
  new_rights    JSONB;
  ids           INTEGER [];
BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

  RAISE NOTICE 'doc_id: %', doc_id;

  IF doc_number IS NULL OR doc_number = ''
  THEN
    -- присвоим новый номер
    doc_number = docs.sp_get_number(user_rekvid, 'ARV', YEAR(doc_kpv), tnDokLausId);
  END IF;

  RAISE NOTICE 'data.doc_details: %, jsonb_array_length %, data: %', doc_details, json_array_length(doc_details), data;

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


    INSERT INTO docs.doc (doc_type_id, history, rigths, rekvId)
    VALUES (doc_type_id, '[]' :: JSONB || new_history, new_rights, user_rekvid)
    RETURNING id
      INTO doc_id;

    INSERT INTO docs.arv (parentid, rekvid, userid, liik, operid, number, kpv, asutusid, lisa, tahtaeg, kbmta, kbm, summa, muud, objektid, objekt, doklausid)
    VALUES (doc_id, user_rekvid, userId, doc_liik, doc_operid, doc_number, doc_kpv, doc_asutusid, doc_lisa, doc_tahtaeg,
                    doc_kbmta, doc_kbm, doc_summa,
            doc_muud, doc_objektid, doc_objekt, tnDokLausId)
    RETURNING id
      INTO arv_id;

    INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
    VALUES (arv_id, 3, tcValuuta, tnKuurs);


  ELSE
    -- history
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user) row;


    RAISE NOTICE 'new_history %', new_history;

    UPDATE docs.doc
    SET lastupdate = now(),
      history      = coalesce(history, '[]') :: JSONB || new_history,
      rekvid       = user_rekvid
    WHERE id = doc_id;

    UPDATE docs.arv
    SET
      liik      = doc_liik,
      operid    = doc_operid,
      number    = doc_number,
      kpv       = doc_kpv,
      asutusid  = doc_asutusid,
      lisa      = doc_lisa,
      tahtaeg   = doc_tahtaeg,
      kbmta     = coalesce(doc_kbmta, 0),
      kbm       = coalesce(doc_kbm, 0),
      summa     = coalesce(doc_summa, 0),
      muud      = doc_muud,
      objektid  = doc_objektid,
      objekt    = doc_objekt,
      doklausid = tnDokLausId
    WHERE parentid = doc_id
    RETURNING id
      INTO arv_id;

    -- arv jaak

    PERFORM docs.sp_update_arv_jaak(arv_id, doc_kpv);

  END IF;
  -- вставка в таблицы документа


  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM json_to_record(
             json_object) AS x(id TEXT, nomId INTEGER, kogus NUMERIC(14, 4), hind NUMERIC(14, 4), kbm NUMERIC(14, 4),
         summa NUMERIC(14, 4), kood TEXT, nimetus TEXT, kood1 TEXT, kood2 TEXT, kood3 TEXT, kood4 TEXT, kood5 TEXT,
         valuuta TEXT, kuurs NUMERIC(14, 4), konto TEXT);

    RAISE NOTICE 'json_record: %, nomid %', json_record, json_record.nomid;
    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
    THEN
      INSERT INTO docs.arv1 (parentid, nomid, kogus, hind, kbm, summa, kood1, kood2, kood3, kood4, kood5, konto)
      VALUES (arv_id, json_record.nomid,
                      coalesce(json_record.kogus, 0),
                      coalesce(json_record.hind, 0),
                      coalesce(json_record.kbm, 0),
                      coalesce(json_record.summa, 0),
                      coalesce(json_record.kood1, ''),
                      coalesce(json_record.kood2, ''),
                      coalesce(json_record.kood3, ''),
                      coalesce(json_record.kood4, ''),
                      coalesce(json_record.kood5, ''),
              coalesce(json_record.konto, '')
      )
      RETURNING id
        INTO arv1_id;

      -- valuuta
      INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
      VALUES (arv1_id, 2, tcValuuta, tnKuurs);

      -- add new id into array of ids
      ids = array_append(ids, arv1_id);

    ELSE
      UPDATE docs.arv1
      SET
        parentid = arv_id,
        nomid    = json_record.nomid,
        kogus    = coalesce(json_record.kogus, 0),
        hind     = coalesce(json_record.hind, 0),
        kbm      = coalesce(json_record.kbm, 0),
        summa    = coalesce(json_record.summa, kogus * hind),
        kood1    = coalesce(json_record.kood1, ''),
        kood2    = coalesce(json_record.kood2, ''),
        kood3    = coalesce(json_record.kood3, ''),
        kood4    = coalesce(json_record.kood4, ''),
        kood5    = coalesce(json_record.kood5, ''),
        konto    = coalesce(json_record.konto, '')
      WHERE id = json_record.id :: INTEGER
      RETURNING id
        INTO arv1_id;

      -- add new id into array of ids
      ids = array_append(ids, arv1_id);

      IF NOT exists(SELECT id
                    FROM docs.dokvaluuta1
                    WHERE dokid = arv1_id AND dokliik = 2)
      THEN
        -- if record does
        INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
        VALUES (arv1_id, 2, tcValuuta, tnKuurs);

      END IF;
    END IF;

  END LOOP;

  -- delete record which not in json

  DELETE FROM docs.arv1
  WHERE parentid = arv_id AND id NOT IN (SELECT unnest(ids));

  -- update arv summad
  SELECT
    sum(summa) AS summa,
    sum(kbm)   AS kbm
  INTO doc_summa, doc_kbm
  FROM docs.arv1
  WHERE parentid = arv_id;

  UPDATE docs.arv
  SET
    kbmta = coalesce(doc_summa, 0) - coalesce(doc_kbm, 0),
    kbm   = coalesce(doc_kbm, 0),
    summa = coalesce(doc_summa, 0)
  WHERE parentid = doc_id;


  /*
  perform docs.sp_updatearvjaak(arv_id, date());
    perform sp_updatearvjaak(tnParentId, date());

  -- Ladu

    if (select count(id) from ladu_grupp where ladu_grupp.nomId = tnnomId) > 0 then
      select rekvid into lnRekvid from arv where id = tnParentid;
      perform sp_recalc_ladujaak(lnRekvId, tnNomId, 0);
    end if;
  */
  RETURN doc_id;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
select docs.sp_salvesta_arv('{"id":900,"data": {"arvid":0,"asutus":"Asutus","asutusid":2,"bpm":null,"created":"10.02.2018 12:02:07","doc":"Arved","doc_status":0,"doc_type_id":"ARV","doklausid":1,"doklausid1":1,"dokprop":"Arved","id":900,"jaak":30,"journalid":0,"kbm":0,"kbmta":20,"kpv":"20180210","lastupdate":"10.02.2018 02:02:56","laus_nr":0,"liik":0,"lisa":"lisa","muud":"","number":"2","objekt":"","objektid":0,"operid":0,"regkood":"6543423423423","rekvid":1,"status":"????????","summa":30,"summa1":10,"tahtaeg":"20180210","tasud":null,"tasudok":null,"userid":1,
"gridData":[{"formula":"","hind":0,"id":0,"kbm":0,"kbmta":0,"km":"","kogus":0,"konto":"","kood":"","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kuurs":0,"nimetus":"","nomid":0,"proj":"","soodus":0,"summa":0,"tp":"","tunnus":"","userid":0,"valuuta":"","vastisik":""}]},
"gridData":[{"formula":"","hind":0,"id":0,"kbm":0,"kbmta":0,"km":"","kogus":0,"konto":"","kood":"","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kuurs":0,"nimetus":"","nomid":0,"proj":"","soodus":0,"summa":0,"tp":"","tunnus":"","userid":0,"valuuta":"","vastisik":""}]}'
, 1, 1);


select * from docs.arv where parentid = 900
select * from docs.arv1 where parentid = 331

"gridData":[{"formula":"","hind":0,"id":0,"kbm":0,"kbmta":0,"km":"","kogus":0,"konto":"","kood":"","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","kuurs":0,"nimetus":"","nomid":0,"proj":"","soodus":0,"summa":0,"tp":"","tunnus":"","userid":0,"valuuta":"","vastisik":""}]
*/
