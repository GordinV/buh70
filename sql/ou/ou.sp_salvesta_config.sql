DROP FUNCTION IF EXISTS ou.sp_salvesta_config(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION ou.sp_salvesta_config(data JSON,
                                                 user_id INTEGER,
                                                 user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  config_id    INTEGER;
  userName     TEXT;
  doc_id       INTEGER = data ->> 'id';
  doc_data     JSON    = data ->> 'data';
  doc_number   TEXT    = doc_data ->> 'number';
  doc_keel     INTEGER = doc_data ->> 'keel';
  doc_port     TEXT    = doc_data ->> 'port';
  doc_smtp     TEXT    = doc_data ->> 'smtp';
  doc_user     TEXT    = doc_data ->> 'user';
  doc_pass     TEXT    = doc_data ->> 'pass';
  doc_email    TEXT    = doc_data ->> 'email';
  doc_tahtpaev INTEGER = doc_data ->> 'tahtpaev';
  doc_earved    TEXT    = doc_data ->> 'earved';
  doc_json     JSON    = ((SELECT row_to_json(row)
                           FROM (SELECT doc_keel  AS keel,
                                        doc_port  AS port,
                                        doc_smtp  AS smtp,
                                        doc_user  AS user,
                                        doc_pass  AS pass,
                                        doc_email AS email) ROW));

  doc_config_json jsonb =   ((SELECT row_to_json(row)
                              FROM (SELECT doc_earved AS earved) ROW));

BEGIN

  SELECT kasutaja
         INTO userName
  FROM ou.userid u
  WHERE u.rekvid = user_rekvid
    AND u.id = user_id;

  IF userName IS NULL
  THEN
    RAISE EXCEPTION 'User not found %', user;
    RETURN 0;
  END IF;

  IF (doc_id IS NULL)
  THEN
    doc_id = doc_data ->> 'id';
  END IF;

  -- вставка или апдейт docs.doc
  IF doc_id IS NULL OR doc_id = 0
  THEN
    INSERT INTO ou.config (rekvid, number, tahtpaev, keel, properties)
    VALUES
      (user_rekvid, doc_number, doc_tahtpaev, doc_keel, doc_config_json)
      RETURNING id
        INTO config_id;

  ELSE


    UPDATE ou.config
    SET
      number   = doc_number,
      tahtpaev = doc_tahtpaev,
      keel     = doc_keel,
      properties = properties || doc_config_json
    WHERE id = doc_id
      RETURNING id
        INTO config_id;
  END IF;

  UPDATE ou.userid SET properties = properties::JSONB || doc_json::JSONB WHERE id = user_id;

  RETURN user_rekvid;
  EXCEPTION
  WHEN OTHERS
    THEN
      RAISE EXCEPTION 'error % %', SQLERRM, SQLSTATE;
      RETURN 0;

END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION ou.sp_salvesta_config(JSON, INTEGER, INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_config(JSON, INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.sp_salvesta_config(JSON, INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT ou.sp_salvesta_rekv('{"id":1,"data":{"tahtpaev":15,"aadress":null,"doc_type_id":"REKV","email":null,"faks":null,"haldus":null,"id":1,"juht":null,"kbmkood":null,"muud":null,"nimetus":"Test","parentid":4,"regkood":"10000","tel":null,"userid":1,"ftp":"ftp.avpsoft.ee","login":"login","parool":"pwd","gridData":[{"arve":"kassa1","default_":1,"id":1,"kassa":1,"kassapank":0,"konto":"111","muud":null,"nimetus":"Kassa1","pank":0,"parentid":1,"saldo":0,"tp":null}]}}', 1, 1);

*/
