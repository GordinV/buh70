DROP FUNCTION IF EXISTS docs.sp_salvesta_arvtasu( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arvtasu(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  lib_id          INTEGER;
  userName        TEXT;
  doc_id          INTEGER = data ->> 'id';
  doc_data        JSON = data ->> 'data';
  doc_rekvid      INTEGER = doc_data ->> 'rekvid';
  doc_doc_arv_id  INTEGER = doc_data ->> 'doc_arv_id';
  doc_doc_tasu_id INTEGER = doc_data ->> 'doc_tasu_id';
  doc_kpv         DATE = doc_data ->> 'kpv';
  doc_summa       NUMERIC(14, 2) = doc_data ->> 'summa';
  doc_dok         TEXT = doc_data ->> 'dok';
  doc_pankkassa   INTEGER = doc_data ->> 'pankkassa';
  doc_muud        TEXT = doc_data ->> 'muud';
  doc_valuuta     TEXT = coalesce((doc_data ->> 'valuuta')::text,'EUR');
  doc_kuurs       NUMERIC(14, 4) = coalesce((doc_data ->> 'kuurs')::numeric, 1);
  json_object     JSONB;
  v_tasu_dok      RECORD;
  l_arv_id        INTEGER = 0;
  a_dokvaluuta    TEXT [] = enum_range(NULL :: DOK_VALUUTA);
BEGIN

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

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

    -- check if tasu from journal
    IF doc_doc_arv_id IS NULL OR empty(doc_doc_arv_id) AND NOT empty(doc_doc_tasu_id) AND doc_pankkassa = 3
    THEN

      --1 open jounal doc
      SELECT *
      INTO v_tasu_dok
      FROM docs.journal
      WHERE parentid = doc_doc_tasu_id;

      -- 2 find arv doc
      doc_doc_arv_id = (SELECT parentid
                        FROM docs.arv
                        WHERE rekvid = v_tasu_dok.rekvid
                              AND ltrim(rtrim(number)) = ltrim(rtrim(v_tasu_dok.dok))
                              AND arv.asutusid = v_tasu_dok.asutusid
                        ORDER BY jaak DESC
                        LIMIT 1
      );

      IF doc_doc_arv_id IS NULL
      THEN
        RAISE NOTICE 'tasu dok ei leidnud';
        RETURN 0;
      END IF;


    END IF;

    -- 3 delete old payment

    DELETE FROM docs.arvtasu
    WHERE doc_tasu_id = doc_doc_tasu_id AND pankkassa = doc_pankkassa;

    INSERT INTO docs.arvtasu (rekvid, doc_arv_id, doc_tasu_id, kpv, summa, muud, status, pankkassa)
    VALUES (doc_rekvid, doc_doc_arv_id, doc_doc_tasu_id, doc_kpv, doc_summa, doc_muud, 1, doc_pankkassa)
    RETURNING id
      INTO lib_id;
  ELSE

    UPDATE docs.arvtasu
    SET
      doc_arv_id  = doc_doc_arv_id,
      doc_tasu_id = doc_doc_tasu_id,
      kpv         = doc_kpv,
      summa       = doc_summa,
      muud        = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO lib_id;
  END IF;

  IF NOT exists(SELECT id
                FROM docs.dokvaluuta1
                WHERE dokid = lib_id AND dokliik = array_position(a_dokvaluuta, 'arvtasu'))
  THEN
    -- if record does
    INSERT INTO docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs)
    VALUES (lib_id, array_position(a_dokvaluuta, 'arvtasu'), doc_valuuta, doc_kuurs);

  END IF;

  -- update arv jaak
  l_arv_id = docs.sp_update_arv_jaak(doc_doc_arv_id, doc_kpv);

  RETURN lib_id;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;


END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arvtasu(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arvtasu(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select docs.sp_salvesta_arvtasu('{"id":0,"data":{"doc_arv_id":39,"doc_tasu_id":null,"dok":null,"dok_type":null,"id":0,"kpv":"20180302","kuurs":1,"muud":null,"number":null,"pankkassa":4,"rekvid":1,"summa":100,"userid":1,"valuuta":"EUR"}}'
,1, 1)


{"id":1,"data":{"asutusid":0,"id":1,"kbmkonto":"","kbmlausend":0,"konto":"111","kood1":"","kood2":"","kood3":"","kood4":"","kood5":"","muud":"","parentid":1,"proc_":"","registr":1,"selg":"","vaatalaus":1}}
{"id":0,"data":{"asutusid":null,"dok":"ARV","id":0,"kbmkonto":null,"konto":null,"kood1":null,"kood2":null,"kood3":null,"kood5":null,"muud":null,"nimetus":null,"proc_":null,"registr":0,"rekvid":1,"selg":"__test8514","userid":1,"vaatalaus":0}}
{"id":1,"data":{"asutusid":2,"id":1,"kbmkonto":"113","kbmlausend":0,"konto":"111","kood1":"test","kood2":"","kood3":"","kood4":"","kood5":"","muud":"","parentid":1,"proc_":"","registr":1,"selg":"","vaatalaus":1}}
*/