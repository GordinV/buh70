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
  doc_deklid       INTEGER = doc_data ->> 'deklid';
  new_history      JSONB;
  docs             INTEGER [];
  is_import        BOOLEAN = data ->> 'import';
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

  RAISE NOTICE 'doc_id %', doc_id;

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

    INSERT INTO rekl.toiming (parentid, asutusid, kpv, number, alus, muud, lubaid, userid, ettekirjutus, tahtaeg, summa, staatus, deklid, tyyp)
    VALUES
      (doc_id, doc_asutusid, doc_kpv, doc_number, doc_alus, doc_muud, doc_lubaid, userid, doc_ettekirjutus, doc_tahtaeg,
               doc_summa, 'active', doc_deklid, doc_tyyp)
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
    SELECT docs_ids
    INTO docs
    FROM docs.doc
    WHERE id = doc_id;

    -- will check if arvId exists
    RAISE NOTICE 'dekl_id %', dekl_id;
    UPDATE docs.doc
    SET
      docs_ids   = docs,
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
      deklid       = doc_deklid
    WHERE parentid = doc_id
    RETURNING id
      INTO dekl_id;

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

SELECT rekl.sp_salvesta_toiming('{
  "id": 0,
  "data": {
    "number": 1,
    "kpv": "2018-06-19",
    "asutusid": 1,
    "alus": "test",
    "lubaid": 294112,
    "summa": 100,
    "ettekirjutus": "test ette",
    "tyyp": "DEKL",
    "saadetud": "2018-06-19"
  }
}', 1, 1);