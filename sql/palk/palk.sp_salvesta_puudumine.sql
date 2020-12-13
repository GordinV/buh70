DROP FUNCTION IF EXISTS palk.sp_salvesta_puudumine( DATA JSON, userid INTEGER, user_rekvid INTEGER );

CREATE FUNCTION palk.sp_salvesta_puudumine(data JSON, userid INTEGER, user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  puudumine_id        INTEGER;
  userName            TEXT;
  doc_id              INTEGER = data ->> 'id';
  doc_data            JSON = data ->> 'data';
  doc_kpv1            DATE = doc_data ->> 'kpv1';
  doc_kpv2            DATE = doc_data ->> 'kpv2';
  doc_paevad          INTEGER = doc_data ->> 'paevad';
  doc_puudumiste_liik PUUDUMISTE_LIIGID = (doc_data ->> 'puudumiste_liik') :: TEXT;
  doc_tyyp            INTEGER = doc_data ->> 'tyyp';
  doc_lepingid        INTEGER = doc_data ->> 'lepingid';
  doc_libid           INTEGER = doc_data ->> 'libid';
  doc_summa           NUMERIC(14, 4) = doc_data ->> 'summa';
  doc_muud            TEXT = doc_data ->> 'muud';

  new_history         JSONB;
  v_puudumine         RECORD;
  is_import           BOOLEAN = data ->> 'import';
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

    INSERT INTO palk.puudumine (lepingid, libid, summa, kpv1, kpv2, paevad, puudumiste_liik, tyyp, status, ajalugu, muud)
    VALUES
      (doc_lepingid, doc_libid, doc_summa, doc_kpv1, doc_kpv2, doc_paevad, doc_puudumiste_liik :: PUUDUMISTE_LIIGID,
                     doc_tyyp, 'active',
                     new_history, doc_muud)
    RETURNING id
      INTO puudumine_id;


  ELSE
    -- history
    SELECT *
    INTO v_puudumine
    FROM palk.puudumine
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()       AS updated,
            userName    AS user,
            v_puudumine AS puudumine) row;

    UPDATE palk.puudumine
    SET
      libid           = doc_libid,
      summa           = doc_summa,
      ajalugu         = '[]'::jsonb || coalesce(ajalugu, '[]'::jsonb) || new_history,
      kpv1            = doc_kpv1,
      kpv2            = doc_kpv2,
      paevad          = doc_paevad,
      puudumiste_liik = doc_puudumiste_liik :: PUUDUMISTE_LIIGID,
      tyyp            = doc_tyyp,
      muud            = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO puudumine_id;

  END IF;

  RETURN puudumine_id;
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