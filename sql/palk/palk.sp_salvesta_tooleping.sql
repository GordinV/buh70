DROP FUNCTION IF EXISTS palk.sp_salvesta_tooleping( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_salvesta_tooleping(
  data        JSON,
  userid      INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
  leping_id      INTEGER;
  userName       TEXT;
  doc_id         INTEGER = data ->> 'id';
  doc_data       JSON = data ->> 'data';
  doc_parentid   INTEGER = doc_data ->> 'parentid';
  doc_osakondid  INTEGER = doc_data ->> 'osakondid';
  doc_ametid     INTEGER = doc_data ->> 'ametid';
  doc_algab      DATE = coalesce((doc_data ->> 'algab') :: DATE, now() :: DATE);
  doc_lopp       DATE = CASE WHEN ltrim(rtrim((doc_data ->> 'lopp') :: TEXT)) = ''
    THEN NULL :: DATE
                        ELSE (doc_data ->> 'lopp') :: DATE END;
  doc_palk       NUMERIC(14, 2) = doc_data ->> 'palk';
  doc_palgamaar  INTEGER = coalesce((doc_data ->> 'palgamaar') :: INTEGER,
                                    array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK'));
  doc_muud       TEXT = doc_data ->> 'muud';
  doc_resident   INTEGER = doc_data ->> 'resident';
  doc_riik       TEXT = doc_data ->> 'riik';
  doc_toend      DATE = doc_data ->> 'toend';
  doc_koormus    NUMERIC(14, 4) = coalesce((doc_data ->> 'koormus') :: NUMERIC, 100);
  doc_toopaev    NUMERIC(14, 4) = coalesce((doc_data ->> 'toopaev') :: NUMERIC, 8);
  doc_pohikoht   INTEGER = coalesce((doc_data ->> 'pohikoht') :: INTEGER, 1);
  doc_ametnik    INTEGER = coalesce((doc_data ->> 'ametnik') :: INTEGER, 0);
  doc_tasuliik   INTEGER = coalesce((doc_data ->> 'tasuliik') :: INTEGER,
                                    array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK'));
  new_properties JSONB;
  new_history    JSONB;
  v_tooleping    RECORD;
  l_status       INTEGER = CASE WHEN doc_lopp IS NOT NULL AND doc_lopp < current_date
    THEN array_position((enum_range(NULL :: DOK_STATUS)), 'closed')
                           ELSE array_position((enum_range(NULL :: DOK_STATUS)), 'active') END;
  is_import      BOOLEAN = data ->> 'import';
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

  raise notice 'save leping %, user_rekvid %',doc_id, user_rekvid;

  IF doc_id IS NULL OR doc_id = 0
  THEN


    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS created,
            userName AS user) row;


    INSERT INTO palk.tooleping (rekvid, parentid, osakondid, ametid, algab, lopp, palk, palgamaar, pohikoht,
                                ametnik, tasuliik, resident, riik, toend, koormus, toopaev, ajalugu, muud)
    VALUES
      (user_rekvid, doc_parentid, doc_osakondid, doc_ametid, doc_algab, doc_lopp, doc_palk, doc_palgamaar, doc_pohikoht,
                    doc_ametnik, doc_tasuliik, doc_resident, doc_riik, doc_toend, doc_koormus, doc_toopaev, new_history,
       doc_muud)
    RETURNING id
      INTO leping_id;


  ELSE
    -- history
    SELECT *
    INTO v_tooleping
    FROM palk.tooleping
    WHERE id = doc_id;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()       AS updated,
            userName    AS user,
            v_tooleping AS tooleping) row;

    UPDATE palk.tooleping
    SET
      osakondid = doc_osakondid,
      ametid    = doc_ametid,
      algab     = doc_algab,
      lopp      = doc_lopp,
      palk      = doc_palk,
      palgamaar = doc_palgamaar,
      pohikoht  = doc_pohikoht,
      ametnik   = doc_ametnik,
      tasuliik  = doc_tasuliik,
      resident  = doc_resident,
      riik      = doc_riik,
      toend     = doc_toend,
      koormus   = doc_koormus,
      toopaev   = doc_toopaev,
      ajalugu   = new_history,
      status    = l_status,
      muud      = doc_muud,
      rekvid    = CASE WHEN is_import IS NOT NULL
        THEN user_rekvid
                  ELSE rekvid END
    WHERE id = doc_id
    RETURNING id
      INTO leping_id;

  END IF;

  RETURN leping_id;

END;
$BODY$;


GRANT EXECUTE ON FUNCTION palk.sp_salvesta_tooleping(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_salvesta_tooleping(JSON, INTEGER, INTEGER) TO dbpeakasutaja;


/*
select palk.sp_salvesta_tooleping('{"id":0,"data":{"algab":"20180327","ametid":379,"ametnik":0,"doc_type_id":"TOOLEPING","id":0,"koormus":100,"lopp":null,"muud":null,"osakondid":377,"palgamaar":null,"palk":100,"parentid":57,"pohikoht":1,"rekvid":1,"resident":1,"riik":null,"tasuliik":1,"toend":null,"toopaev":8,"userid":1}}',1, 1);

select * from libs.asutus

*/