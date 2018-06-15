DROP FUNCTION IF EXISTS sp_salvesta_palk_tmpl( DATA JSON, userid INTEGER, user_rekvid INTEGER );
DROP FUNCTION IF EXISTS palk.sp_salvesta_palk_tmpl( DATA JSON, userid INTEGER, user_rekvid INTEGER );

CREATE FUNCTION palk.sp_salvesta_palk_tmpl(data JSON, userid INTEGER, user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  tmpl_id      INTEGER;
  userName     TEXT;
  doc_id       INTEGER = data ->> 'id';
  doc_data     JSON = data ->> 'data';
  doc_parentid INTEGER = doc_data ->> 'parentid';
  doc_libid    INTEGER = doc_data ->> 'libid';
  doc_summa    NUMERIC(14, 4) = doc_data ->> 'summa';
  doc_percent_ INTEGER = doc_data ->> 'percent_';
  doc_tulumaks INTEGER = doc_data ->> 'tulumaks';
  doc_tulumaar INTEGER = doc_data ->> 'tulumaar';
  doc_tunnus   TEXT = doc_data ->> 'tunnus';
  doc_muud     TEXT = doc_data ->> 'muud';

  new_history  JSONB;
  v_palk_tmpl  RECORD;
  is_import    BOOLEAN = data ->> 'import';
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


    INSERT INTO palk.palk_tmpl (parentid, libid, summa, percent_, tulumaks, tulumaar,
                                tunnus, status, ajalugu, muud)
    VALUES
      (doc_parentid, doc_libid, doc_summa, doc_percent_, doc_tulumaks, doc_tulumaar,
       doc_tunnus, 'active',
       new_history, doc_muud)
    RETURNING id
      INTO tmpl_id;


  ELSE
    -- history
    SELECT *
    INTO v_palk_tmpl
    FROM palk.palk_tmpl
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()       AS updated,
            userName    AS user,
            v_palk_tmpl AS palk_tmpl) row;

    UPDATE palk.palk_tmpl
    SET
      libid    = doc_libid,
      summa    = doc_summa,
      percent_ = doc_percent_,
      tulumaks = doc_tulumaks,
      tulumaar = doc_tulumaar,
      tunnus   = doc_tunnus,
      ajalugu  = new_history,
      muud     = doc_muud
    WHERE id = doc_id
    RETURNING id
      INTO tmpl_id;

  END IF;

  RETURN tmpl_id;

END;
$$;


SELECT palk.sp_salvesta_palk_tmpl(
    '{
      "id": 0,
      "data": {
        "alimentid": 0,
        "doc_type_id": "PALK_TMPL",
        "id": 0,
        "libid": 384,
        "minsots": 0,
        "muud": null,
        "parentid": 379,
        "percent_": 0,
        "status": "active",
        "summa": 100,
        "tulumaar": 0,
        "tulumaks": 0,
        "tunnus": null,
        "userid": 1
      }
    }',
    1, 1)