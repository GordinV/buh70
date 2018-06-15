DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_kaart( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_salvesta_palk_kaart(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
  kaart_id       INTEGER;
  userName       TEXT;
  doc_id         INTEGER = data ->> 'id';
  doc_data       JSON = data ->> 'data';
  doc_parentid   INTEGER = doc_data ->> 'parentid';
  doc_libid      INTEGER = doc_data ->> 'libid';
  doc_lepingid   INTEGER = doc_data ->> 'lepingid';
  doc_summa      NUMERIC(14, 4) = doc_data ->> 'summa';
  doc_percent_   INTEGER = doc_data ->> 'percent_';
  doc_tulumaks   INTEGER = doc_data ->> 'tulumaks';
  doc_tulumaar   INTEGER = doc_data ->> 'tulumaar';
  doc_alimentid  INTEGER = doc_data ->> 'alimentid';
  doc_tunnus     TEXT = doc_data ->> 'tunnus';
  doc_minsots    INTEGER = doc_data ->> 'minsots';
  doc_muud       TEXT = doc_data ->> 'muud';

  new_properties JSONB;
  new_history    JSONB;
  v_palk_kaart   RECORD;
  is_import      BOOLEAN = data ->> 'import';
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


    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;


    INSERT INTO palk.palk_kaart (parentid, libid, lepingid, summa, percent_, tulumaks, tulumaar,
                                 alimentid, tunnus, minsots, status, ajalugu, muud)
    VALUES
      (doc_parentid, doc_libid, doc_lepingid, doc_summa, doc_percent_, doc_tulumaks, doc_tulumaar,
                     doc_alimentid, doc_tunnus, doc_minsots, 1, new_history, doc_muud)
    RETURNING id
      INTO kaart_id;


  ELSE
    -- history
    SELECT *
    INTO v_palk_kaart
    FROM palk.palk_kaart
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()        AS updated,
            userName     AS user,
            v_palk_kaart AS palk_kaart) row;

    UPDATE palk.palk_kaart
    SET
      libid     = doc_libid,
      lepingid  = doc_lepingid,
      summa     = doc_summa,
      percent_  = doc_percent_,
      tulumaks  = doc_tulumaks,
      tulumaar  = doc_tulumaar,
      alimentid = doc_alimentid,
      tunnus    = doc_tunnus,
      minsots   = doc_minsots,
      ajalugu   = new_history,
      muud      = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO kaart_id;

  END IF;

  RETURN kaart_id;

END;
$BODY$;


GRANT EXECUTE ON FUNCTION palk.sp_salvesta_palk_kaart(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_salvesta_palk_kaart(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select palk.sp_salvesta_tooleping('{"id":0,"data":{"algab":"20180327","ametid":379,"ametnik":0,"doc_type_id":"TOOLEPING","id":0,"koormus":100,"lopp":null,"muud":null,"osakondid":377,"palgamaar":null,"palk":100,"parentid":57,"pohikoht":1,"rekvid":1,"resident":1,"riik":null,"tasuliik":1,"toend":null,"toopaev":8,"userid":1}}',1, 1);

select * from libs.asutus

*/