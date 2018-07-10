DROP FUNCTION IF EXISTS rekl.sp_salvesta_ettemaksud( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION rekl.sp_salvesta_ettemaksud(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_data      JSON = data ->> 'data';
  doc_number    INTEGER = coalesce((doc_data ->> 'number') :: INTEGER, 1);
  doc_asutusid  INTEGER = doc_data ->> 'asutusid';
  doc_kpv       DATE = doc_data ->> 'kpv';
  doc_summa     NUMERIC(14, 2) = doc_data ->> 'summa';
  doc_dokid     INTEGER = doc_data ->> 'dokid';
  doc_doktyyp   REKL_ETTEMAKS_LIIK = coalesce((doc_data ->> 'doktyyp') :: REKL_ETTEMAKS_LIIK, 'DEEBET');
  doc_selg      TEXT = doc_data ->> 'selg';
  doc_journalid INTEGER = doc_data ->> 'journalid';
  doc_muud      TEXT = doc_data ->> 'muud';
  is_import     BOOLEAN = data ->> 'import';
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

    INSERT INTO rekl.ettemaksud (rekvid, asutusid, kpv, number, selg, muud, summa, staatus, dokid, doktyyp, journalid)
    VALUES
      (user_rekvid, doc_asutusid, doc_kpv, doc_number, doc_selg, doc_muud, doc_summa, 'active', doc_dokid, doc_doktyyp,
       doc_journalid)
    RETURNING id
      INTO doc_id;

  ELSE

    UPDATE rekl.ettemaksud
    SET
      kpv    = doc_kpv,
      selg   = doc_selg,
      number = doc_number,
      muud   = doc_muud,
      summa  = doc_summa,
      dokid  = doc_dokid

    WHERE id = doc_id
    RETURNING id
      INTO doc_id;

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


GRANT EXECUTE ON FUNCTION rekl.sp_salvesta_ettemaksud(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_salvesta_ettemaksud(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

SELECT rekl.sp_salvesta_ettemaksud('{
  "id": 0,
  "data": {
    "number": 1,
    "kpv": "2018-06-19",
    "asutusid": 1,
    "selg": "test",
    "summa": 100
  }
}', 1, 1);