DROP FUNCTION IF EXISTS rekl.sp_salvesta_toiming( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION rekl.sp_salvesta_toiming(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  dekl_id          INTEGER;
  userName         TEXT;
  doc_id           INTEGER = data ->> 'id';
  doc_data         JSON = data ->> 'data';
  doc_type_kood    TEXT = 'DEKL';
  doc_type_id      INTEGER = (SELECT id
                              FROM libs.library
                              WHERE ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood))) AND library = 'DOK'
                              LIMIT 1);
  doc_number       INTEGER = coalesce((doc_data ->> 'number') :: INTEGER, 1);
  doc_asutusid     INTEGER = doc_data ->> 'asutusid';
  doc_lubaid       INTEGER = doc_data ->> 'lubaid';
  doc_kpv          DATE = doc_data ->> 'kpv';
  doc_summa        NUMERIC(14, 2) = doc_data ->> 'summa';
  doc_alus         TEXT = doc_data ->> 'alus';
  doc_ettekirjutus TEXT = doc_data ->> 'ettekirjutus';
  doc_tahtaeg      DATE = doc_data ->> 'tahtaeg';
  doc_tyyp         REKL_TOIMING_LIIK = doc_data ->> 'tyyp';
  doc_muud         TEXT = doc_data ->> 'muud';
  doc_dokpropid    INTEGER = doc_data ->> 'dokpropid';
  doc_saadetud     DATE = doc_data ->> 'saadetud';
  doc_staatus      DOK_STATUS = doc_data ->> 'staatus';
  doc_deklid       INTEGER = doc_data ->> 'deklid';
  doc_failid       TEXT = doc_data ->> 'failid';
  l_jsonb          JSONB;
  new_history      JSONB;
  docs             INTEGER [];
  is_import        BOOLEAN = data ->> 'import';
  a_docs_ids       INTEGER [];
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

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;

    -- add new id into docs. ref. array
    a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, doc_lubaid)));


    INSERT INTO docs.doc (doc_type_id, history, rekvid, docs_ids)
    VALUES (doc_type_id, '[]' :: JSONB || new_history, user_rekvid, a_docs_ids)
    RETURNING id
      INTO doc_id;

    INSERT INTO rekl.toiming (parentid, asutusid, kpv, number, alus, muud, lubaid, userid, ettekirjutus, tahtaeg, summa, deklid, tyyp, staatus)
    VALUES
      (doc_id, doc_asutusid, doc_kpv, doc_number, doc_alus, doc_muud, doc_lubaid, userid, doc_ettekirjutus, doc_tahtaeg,
               doc_summa, doc_deklid, doc_tyyp, doc_staatus)
    RETURNING id
      INTO dekl_id;

  ELSE
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user) row;

    -- устанавливаем связи с документами

    -- получим связи документа

    -- lausend
    SELECT docs_ids
    INTO a_docs_ids
    FROM docs.doc
    WHERE id = doc_id;

    -- add new lubaid into docs. ref. array
    a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, doc_lubaid)));

    UPDATE docs.doc
    SET
      docs_ids   = a_docs_ids,
      lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = doc_id;

    UPDATE rekl.toiming
    SET
      kpv          = doc_kpv,
      alus         = doc_alus,
      number       = doc_number,
      muud         = doc_muud,
      summa        = doc_summa,
      ettekirjutus = doc_ettekirjutus,
      tahtaeg      = doc_tahtaeg,
      dokpropid    = doc_dokpropid,
      saadetud     = doc_saadetud,
      deklid       = doc_deklid,
      staatus      = doc_staatus :: DOK_STATUS
    WHERE parentid = doc_id
    RETURNING id
      INTO dekl_id;

  END IF;

  -- add deklid into luba ids

  -- lausend
  SELECT docs_ids
  INTO a_docs_ids
  FROM docs.doc
  WHERE id = doc_lubaid;

  -- add new lubaid into docs. ref. array
  a_docs_ids = array(SELECT DISTINCT unnest(array_append(a_docs_ids, doc_id)));

  UPDATE docs.doc
  SET
    docs_ids   = a_docs_ids,
    lastupdate = now(),
    history    = coalesce(history, '[]') :: JSONB || new_history
  WHERE id = doc_lubaid;


  IF doc_failid IS NOT NULL
  THEN
    -- добавим ссылку на ftp fail
    SELECT row_to_json(row)
    INTO l_jsonb
    FROM (SELECT doc_failid AS failid) row;

    UPDATE rekl.toiming
    SET lisa = coalesce(lisa :: JSONB, '{}' :: JSONB) || l_jsonb :: JSONB
    WHERE parentid = doc_id;
  END IF;

  -- вставка в таблицы документа
  RETURN doc_id;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION rekl.sp_salvesta_toiming(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_salvesta_toiming(JSON, INTEGER, INTEGER) TO dbpeakasutaja;
/*
{"id":294184,"data":{"alus":"test annull","asutusid":1,"bpm":null,"created":"27.06.2018 05:06:39","deklid":null,"doc":null,"docs_ids":"{294181,294112}","doc_type_id":null,"dokprop":"","dokpropid":null,"ettekirjutus":"test ette","id":294184,"jaak":99,"journalid":null,"konto":"","kpv":"20180619","lastupdate":"01.07.2018 04:07:54","lausend":0,"lubaid":294181,"lubaid1":294181,"muud":"3 - 2","number":1,"rekvid":1,"saadetud":null,"staatus":null,"status":"????????","summa":99,"tahtaeg":"20180727","tyyp":"DEKL"}}

SELECT rekl.sp_salvesta_toiming('{"id":294184,"data":{"alus":"test annull","asutusid":1,"bpm":null,"created":"27.06.2018 05:06:39","deklid":null,"doc":null,"docs_ids":"{294181,294112}","doc_type_id":null,"dokprop":"","dokpropid":null,"ettekirjutus":"test ette","id":294184,"jaak":99,"journalid":null,"konto":"","kpv":"20180619","lastupdate":"01.07.2018 04:07:18","lausend":0,"lubaid":294181,"lubaid1":294181,"muud":"3 - 2","number":1,"rekvid":1,"saadetud":null,"staatus":"active","status":"????????","summa":99,"tahtaeg":"20180727","tyyp":"DEKL"}}', 1, 1);
*/