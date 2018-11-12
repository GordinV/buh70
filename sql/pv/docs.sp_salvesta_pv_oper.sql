-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.sp_salvesta_pv_oper( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_salvesta_pv_oper(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  pv_oper_id      INTEGER;
  userName        TEXT;
  doc_id          INTEGER = data ->> 'id';
  doc_data        JSON = data ->> 'data';
  doc_typeId      INTEGER = (SELECT id
                             FROM libs.library
                             WHERE ltrim(rtrim(kood)) = ltrim(rtrim(upper('PV_OPER'))) AND library = 'DOK'
                             LIMIT 1);
  doc_asutusid    INTEGER = doc_data ->> 'asutusid';
  doc_kpv         DATE = doc_data ->> 'kpv';
  doc_pv_kaart_id INTEGER = doc_data ->> 'pv_kaart_id';
  doc_nomid       INTEGER = doc_data ->> 'nomid';
  doc_muud        TEXT = doc_data ->> 'muud';
  tcValuuta       TEXT = coalesce(doc_data ->> 'valuuta', 'EUR');
  tnKuurs         NUMERIC(14, 8) = coalesce(doc_data ->> 'kuurs', '1');
  doc_liik        INTEGER = doc_data ->> 'liik';
  doc_doklausid   INTEGER = doc_data ->> 'doklausid';
  doc_summa       NUMERIC(12, 2) = doc_data ->> 'summa';
  doc_konto       TEXT = doc_data ->> 'konto';
  doc_tunnus      TEXT = doc_data ->> 'tunnus';
  doc_tp          TEXT = doc_data ->> 'tp';
  doc_proj        TEXT = doc_data ->> 'proj';
  doc_kood1       TEXT = doc_data ->> 'kood1';
  doc_kood2       TEXT = doc_data ->> 'kood2';
  doc_kood3       TEXT = doc_data ->> 'kood3';
  doc_kood4       TEXT = doc_data ->> 'kood4';
  doc_kood5       TEXT = doc_data ->> 'kood5';
  new_history     JSONB;
  docs            INTEGER [];
  a_pv_opers      TEXT [] = enum_range(NULL :: PV_OPERATSIOONID);
  is_import       BOOLEAN = data ->> 'import';
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


    INSERT INTO docs.doc (doc_type_id, history, rekvid, status)
    VALUES (doc_typeId, '[]' :: JSONB || new_history, user_rekvid, 1)
    RETURNING id
      INTO doc_id;

    INSERT INTO docs.pv_oper (parentid, kpv, pv_kaart_id, nomid, liik, summa, muud, kood1, kood2, kood3, kood4, kood5,
                              konto, tp, asutusid, tunnus, proj, doklausid)
    VALUES
      (doc_id, doc_kpv, doc_pv_kaart_id, doc_nomid, doc_liik, doc_summa, doc_muud, doc_kood1, doc_kood2, doc_kood3,
               doc_kood4, doc_kood5, doc_konto, doc_tp, doc_asutusid, doc_tunnus, doc_proj, doc_doklausid)
    RETURNING id
      INTO pv_oper_id;

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

    UPDATE docs.doc
    SET
      doc_type_id = doc_typeId,
      docs_ids    = docs,
      lastupdate  = now(),
      history     = coalesce(history, '[]') :: JSONB || new_history
    WHERE id = doc_id;


    UPDATE docs.pv_oper
    SET
      kpv       = doc_kpv,
      nomid     = doc_nomid,
      liik      = doc_liik,
      summa     = doc_summa,
      muud      = doc_muud,
      kood1     = doc_kood1,
      kood2     = doc_kood2,
      kood3     = doc_kood3,
      kood4     = doc_kood4,
      kood5     = doc_kood5,
      konto     = doc_konto,
      tp        = doc_tp,
      asutusid  = doc_asutusid,
      tunnus    = doc_tunnus,
      proj      = doc_proj,
      doklausid = doc_doklausid
    WHERE parentid = doc_id
    RETURNING id
      INTO pv_oper_id;

  END IF;


  IF doc_liik = array_position(a_pv_opers, 'paigutus') -- will calculate summa and change card status
  THEN
    PERFORM docs.sp_pv_oper_paigutus(doc_id);
  ELSEIF doc_liik = array_position(a_pv_opers, 'parandus')
    THEN
      PERFORM docs.sp_pv_oper_parandus(doc_pv_kaart_id); --will calculate parhind
  ELSEIF doc_liik = array_position(a_pv_opers, 'umberhindamine')
    THEN
      PERFORM docs.sp_pv_oper_umberhindamine(doc_pv_kaart_id); --will calculate parhind
  ELSEIF doc_liik = array_position(a_pv_opers, 'mahakandmine')
    THEN
      PERFORM docs.sp_pv_oper_mahakandmine(doc_id);
  END IF;

  -- calculation of jaak

  PERFORM docs.sp_recalc_pv_jaak(doc_pv_kaart_id);

  RETURN doc_id;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_pv_oper(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_pv_oper(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
select docs.sp_salvesta_pv_oper(
  '{"id":0,"data":{"asutus":null,"asutusid":null,"bpm":"","created":"","doc":"","doc_status":null,"doc_type_id":"POHIVARA","doklausid":null,"dokprop":null,"id":0,"journalid":null,"konto":"113","kood":null,"kood1":"null","kood2":"null","kood3":"null","kood4":null,"kood5":"null","korrkonto":"","kpv":"20180303","kuurs":1,"lastupdate":"","laus_nr":null,"liik":2,"muud":null,"nimetus":null,"nomid":68,"proj":null,"pv_kaart_id":null,"regkood":null,"status":"0","summa":1.6700,"tp":null,"tunnus":null,"userid":1,"valuuta":"EUR"}}'
  ,1,1)
*/