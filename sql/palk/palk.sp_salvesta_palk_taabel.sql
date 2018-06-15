DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_taabel( DATA JSON, userid INTEGER, user_rekvid INTEGER );

CREATE FUNCTION palk.sp_salvesta_palk_taabel(data JSON, userid INTEGER, user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  taabel_id     INTEGER;
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_data      JSON = data ->> 'data';
  doc_kuu       INTEGER = doc_data ->> 'kuu';
  doc_aasta     INTEGER = doc_data ->> 'aasta';
  doc_kokku     NUMERIC(12, 4) = doc_data ->> 'kokku';
  doc_too       NUMERIC(12, 4) = (doc_data ->> 'too');
  doc_paev      NUMERIC(12, 4) = doc_data ->> 'paev';
  doc_lepingid  INTEGER = doc_data ->> 'lepingid';
  doc_ohtu      NUMERIC(12, 4) = doc_data ->> 'ohtu';
  doc_oo        NUMERIC(12, 4) = doc_data ->> 'oo';
  doc_tahtpaev  NUMERIC(12, 4) = doc_data ->> 'tahtpaev';
  doc_puhapaev  NUMERIC(12, 4) = doc_data ->> 'puhapaev';
  doc_uleajatoo NUMERIC(12, 4) = doc_data ->> 'uleajatoo';
  doc_muud      TEXT = doc_data ->> 'muud';

  new_history   JSONB;
  v_palk_taabel RECORD;
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

  -- вставка или апдейт docs.doc

  IF doc_id IS NULL OR doc_id = 0
  THEN
    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;

    INSERT INTO palk.palk_taabel1 (lepingid, kuu, aasta, kokku, too, paev, ohtu, oo, tahtpaev, puhapaev, uleajatoo, status, ajalugu, muud)
    VALUES
      (doc_lepingid, doc_kuu, doc_aasta, doc_kokku, doc_too, doc_paev, doc_ohtu, doc_oo, doc_tahtpaev, doc_puhapaev,
                     doc_uleajatoo,
       'active', new_history, doc_muud)
    RETURNING id
      INTO taabel_id;

  ELSE
    -- history
    SELECT *
    INTO v_palk_taabel
    FROM palk.palk_taabel1
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()         AS updated,
            userName      AS user,
            v_palk_taabel AS palk_taabel) row;

    UPDATE palk.palk_taabel1
    SET
      kuu       = doc_kuu,
      aasta     = doc_aasta,
      kokku     = doc_kokku,
      too       = doc_too,
      paev      = doc_paev,
      ohtu      = doc_ohtu,
      oo        = doc_oo,
      tahtpaev  = doc_tahtpaev,
      puhapaev  = doc_puhapaev,
      uleajatoo = doc_uleajatoo,
      ajalugu   = new_history,
      muud      = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO taabel_id;

  END IF;

  RETURN taabel_id;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;
END;
$$;

/*
SELECT palk.sp_salvesta_puudumine(
    '{"id":0,"data":{"doc_type_id":"PUUDUMINE","id":0,"kpv1":"20180401","kpv2":"20180401","lepingid":4,"libid":384,"muud":null,"paevad":0,"parentid":0,"puudumiste_liik":"PUHKUS","status":1,"summa":100,"tyyp":1,"userid":1}}',
    1, 1)
*/
