DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_config( DATA JSON, userid INTEGER, user_rekvid INTEGER );

CREATE FUNCTION palk.sp_salvesta_palk_config(data JSON, user_id INTEGER, user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  config_id      INTEGER;
  userName       TEXT;
  doc_id         INTEGER = data ->> 'id';
  doc_data       JSON = data ->> 'data';
  doc_minpalk    NUMERIC = doc_data ->> 'minpalk';
  doc_tulubaas   NUMERIC = doc_data ->> 'tulubaas';
  doc_round      NUMERIC = doc_data ->> 'round';
  doc_jaak       NUMERIC = doc_data ->> 'jaak';
  doc_genlausend INTEGER = doc_data ->> 'genlausend';
  doc_suurasu    INTEGER = doc_data ->> 'suurasu';
  doc_tm         NUMERIC = doc_data ->> 'tm';
  doc_pm         NUMERIC = doc_data ->> 'pm';
  doc_tka        NUMERIC = doc_data ->> 'tka';
  doc_tki        NUMERIC = doc_data ->> 'tki';
  doc_sm         NUMERIC = doc_data ->> 'sm';
  doc_muud1      NUMERIC = doc_data ->> 'muud1';
  doc_muud2      NUMERIC = doc_data ->> 'muud2';

  new_history    JSONB;
  v_palk_config  RECORD;
BEGIN

  SELECT kasutaja
  INTO userName
  FROM ou.userid u
  WHERE u.rekvid = user_rekvid AND u.id = user_id;
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

    INSERT INTO palk.palk_config (rekvid, minpalk, tulubaas, round, jaak, genlausend, suurasu, tm,
                                  pm, tka, tki, sm, muud1, muud2, ajalugu)
    VALUES
      (user_rekvid, doc_minpalk, doc_tulubaas, doc_round, doc_jaak, doc_genlausend, doc_suurasu, doc_tm,
                    doc_pm, doc_tka, doc_tki, doc_sm, doc_muud1, doc_muud2, new_history)
    RETURNING id
      INTO config_id;

  ELSE
    -- history
    SELECT *
    INTO v_palk_config
    FROM palk.palk_config
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()         AS updated,
            userName      AS user,
            v_palk_config AS palk_config) row;

    UPDATE palk.palk_config
    SET
      minpalk    = doc_minpalk,
      tulubaas   = doc_tulubaas,
      round      = doc_round,
      jaak       = doc_jaak,
      genlausend = doc_genlausend,
      suurasu    = doc_suurasu,
      tm         = doc_tm,
      pm         = doc_pm,
      tka        = doc_tka,
      tki        = doc_tki,
      sm         = doc_sm,
      muud1      = doc_muud1,
      muud2      = doc_muud2,
      ajalugu    = new_history
    WHERE id = doc_id
    RETURNING id
      INTO config_id;

  END IF;

  RETURN config_id;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;
END;
$$;

/*
SELECT palk.sp_salvesta_palk_config(
    '{"id":1,"data":{"genlausend":1,"id":1,"jaak":0,"kuurs":0,"minpalk":,"pm":2,"rekvid":1,"round":,"sm":33,"suurasu":0,"tka":0.80,"tki":1.60,"tm":20,"tulubaas":,"valuuta":""}}',
    1, 1)
*/