DROP FUNCTION IF EXISTS palk.sp_salvesta_toograafik( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_salvesta_toograafik(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
  graafik_id   INTEGER;
  userName     TEXT;
  doc_id       INTEGER = data ->> 'id';
  doc_data     JSON = data ->> 'data';
  doc_lepingid INTEGER = doc_data ->> 'lepingid';
  doc_kuu      INTEGER = doc_data ->> 'kuu';
  doc_aasta    INTEGER = doc_data ->> 'aasta';
  doc_tund     NUMERIC(12, 4) = doc_data ->> 'tund';
  doc_muud     TEXT = doc_data ->> 'muud';
  new_history  JSONB;
  v_graafik    RECORD;
BEGIN

  SELECT kasutaja
  INTO userName
  FROM ou.userid u
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


    INSERT INTO palk.toograf (lepingid, kuu, aasta, tund, ajalugu, muud)
    VALUES
      (doc_lepingid, doc_kuu, doc_aasta, doc_tund, new_history, doc_muud)
    RETURNING id
      INTO graafik_id;

  ELSE
    -- history
    SELECT *
    INTO v_graafik
    FROM palk.toograf
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()     AS updated,
            userName  AS user,
            v_graafik AS toograafik) row;

    UPDATE palk.toograf
    SET
      kuu     = doc_kuu,
      aasta   = doc_aasta,
      tund    = doc_tund,
      ajalugu = new_history,
      muud    = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO graafik_id;

  END IF;

  RETURN graafik_id;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;
$BODY$;


GRANT EXECUTE ON FUNCTION palk.sp_salvesta_toograafik(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_salvesta_toograafik(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select palk.sp_salvesta_tooleping('{"id":0,"data":{"algab":"20180327","ametid":379,"ametnik":0,"doc_type_id":"TOOLEPING","id":0,"koormus":100,"lopp":null,"muud":null,"osakondid":377,"palgamaar":null,"palk":100,"parentid":57,"pohikoht":1,"rekvid":1,"resident":1,"riik":null,"tasuliik":1,"toend":null,"toopaev":8,"userid":1}}',1, 1);

select * from libs.asutus

*/