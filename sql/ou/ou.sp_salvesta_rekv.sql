DROP FUNCTION IF EXISTS ou.sp_salvesta_rekv( JSON, INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_salvesta_rekv(
  data        JSON,
  user_id     INTEGER,
  user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  rekv_id      INTEGER;
  userName     TEXT;
  doc_id       INTEGER = data ->> 'id';
  doc_data     JSON = data ->> 'data';
  doc_parentid INTEGER = doc_data ->> 'parentid';
  doc_regkood  TEXT = doc_data ->> 'regkood';
  doc_nimetus  TEXT = doc_data ->> 'nimetus';
  doc_kbmkood  TEXT = doc_data ->> 'kbmkood';
  doc_aadress  TEXT = doc_data ->> 'aadress';
  doc_haldus   TEXT = doc_data ->> 'haldus';
  doc_tel      TEXT = doc_data ->> 'tel';
  doc_faks     TEXT = doc_data ->> 'faks';
  doc_email    TEXT = doc_data ->> 'email';
  doc_juht     TEXT = doc_data ->> 'juht';
  doc_raama    TEXT = doc_data ->> 'raama';
  doc_muud     TEXT = doc_data ->> 'muud';
  doc_ftp      TEXT = doc_data ->> 'ftp';
  doc_login    TEXT = doc_data ->> 'login';
  doc_parool   TEXT = doc_data ->> 'parool';
  doc_tahtpaev INTEGER = doc_data ->> 'tahtpaev';

  doc_details  JSON = doc_data ->> 'gridData';
  detail_id    INTEGER;
  json_object  JSONB;
  json_arved   JSONB;
  json_record  RECORD;
  ids          INTEGER [];

  new_history  JSON;
  aa_history   JSON;
  user_json    JSON;
  v_user       RECORD;
  new_user_id  INTEGER;
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

    INSERT INTO ou.rekv (parentid, regkood, nimetus, kbmkood, aadress, haldus, tel, faks, email, juht, raama, muud, ajalugu, status)
    VALUES
      (doc_parentid, doc_regkood, doc_nimetus, doc_kbmkood, doc_aadress, doc_haldus, doc_tel, doc_faks, doc_email,
                     doc_juht, doc_raama, doc_muud, new_history,
       array_position((enum_range(NULL :: DOK_STATUS)), 'active'))
    RETURNING id
      INTO rekv_id;

    -- should insert admin user

    SELECT
      0                              AS id,
      rekv_id                        AS rekvid,
      ltrim(rtrim(kasutaja)) :: TEXT AS kasutaja,
      ltrim(rtrim(ametnik)) :: TEXT  AS ametnik,
      kasutaja_,
      peakasutaja_,
      admin,
      muud
    INTO v_user
    FROM ou.userid
    WHERE id = user_id;

    SELECT row_to_json(row)
    INTO user_json
    FROM (SELECT
            0      AS id,
            v_user AS data) row;

    new_user_id = ou.sp_salvesta_userid(user_json, user_id, rekv_id);

    IF new_user_id IS NULL OR new_user_id = 0
    THEN
      RAISE EXCEPTION 'Uue kasutaja salvestamine eba õnnestus';
    END IF;

  ELSE


    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user,
            r.*
          FROM ou.rekv r
          WHERE r.id = doc_id) row;

    -- save aa old state

    SELECT array_to_json(array_agg(row_to_json(row_data)))
    INTO aa_history
    FROM (SELECT aa.*
          FROM ou.aa aa
          WHERE aa.parentid = doc_id) row_data;

    aa_history = ('{"aa":' || aa_history :: TEXT || '}') :: JSON;
    new_history = new_history :: JSONB || aa_history :: JSONB;

    -- rekl ftp andmed
    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT
                           doc_ftp    AS ftp,
                           doc_login  AS login,
                           doc_parool AS parool) row);

    json_object = (SELECT to_jsonb(row)
                   FROM (SELECT json_object :: JSONB AS reklftp) row);

    -- arved properties

    json_arved = (SELECT to_jsonb(row)
                  FROM (SELECT doc_tahtpaev AS tahtpaev) row);

    json_object = json_object || (SELECT to_jsonb(row)
                                  FROM (SELECT json_arved :: JSONB AS arved) row);


    UPDATE ou.rekv
    SET
      parentid   = doc_parentid,
      regkood    = doc_regkood,
      nimetus    = doc_nimetus,
      aadress    = doc_aadress,
      haldus     = doc_haldus,
      tel        = doc_tel,
      faks       = doc_faks,
      email      = doc_email,
      juht       = doc_juht,
      raama      = doc_raama,
      muud       = doc_muud,
      ajalugu    = new_history,
      properties = coalesce(properties :: JSONB, '{}' :: JSONB) || json_object :: JSONB
    WHERE id = doc_id
    RETURNING id
      INTO rekv_id;
  END IF;

  FOR json_object IN
  SELECT *
  FROM json_array_elements(doc_details)
  LOOP
    SELECT *
    INTO json_record
    FROM jsonb_to_record(
             json_object) AS x(id TEXT, parentid INTEGER, arve TEXT, nimetus TEXT, default_ INTEGER, kassa INTEGER, pank INTEGER,
         konto TEXT, tp TEXT, muud TEXT);

    IF json_record.id IS NULL OR json_record.id = '0' OR substring(json_record.id FROM 1 FOR 3) = 'NEW'
    THEN


      INSERT INTO ou.aa (parentid, arve, nimetus, default_, kassa, pank, konto, tp, muud)
      VALUES (json_record.parentid, json_record.arve, json_record.nimetus, json_record.default_, json_record.kassa,
              json_record.pank, json_record.konto, json_record.tp, json_record.muud)
      RETURNING id
        INTO detail_id;

    ELSE
      UPDATE ou.aa
      SET
        arve     = json_record.arve,
        nimetus  = json_record.nimetus,
        default_ = json_record.default_,
        kassa    = json_record.kassa,
        pank     = json_record.pank,
        konto    = json_record.konto,
        tp       = json_record.tp,
        muud     = json_record.muud
      WHERE id = json_record.id :: INTEGER
      RETURNING id
        INTO detail_id;
    END IF;

    -- add new id into array of ids
    ids = array_append(ids, detail_id);
  END LOOP;

  -- delete record which not in json

  DELETE FROM ou.aa
  WHERE parentid = doc_id AND id NOT IN (SELECT unnest(ids));

  RAISE NOTICE 'return %', rekv_id;

  RETURN rekv_id;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_rekv(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_rekv(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT ou.sp_salvesta_rekv('{"id":1,"data":{"tahtpaev":15,"aadress":null,"doc_type_id":"REKV","email":null,"faks":null,"haldus":null,"id":1,"juht":null,"kbmkood":null,"muud":null,"nimetus":"Test","parentid":4,"regkood":"10000","tel":null,"userid":1,"ftp":"ftp.avpsoft.ee","login":"login","parool":"pwd","gridData":[{"arve":"kassa1","default_":1,"id":1,"kassa":1,"kassapank":0,"konto":"111","muud":null,"nimetus":"Kassa1","pank":0,"parentid":1,"saldo":0,"tp":null}]}}', 1, 1);

*/
