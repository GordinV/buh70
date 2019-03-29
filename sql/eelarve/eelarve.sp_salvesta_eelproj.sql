DROP FUNCTION IF EXISTS eelarve.sp_salvesta_eelproj(JSON, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION eelarve.sp_salvesta_eelproj(data JSON,
                                                       user_id INTEGER,
                                                       user_rekvid INTEGER)
  RETURNS INTEGER AS
$BODY$

DECLARE
  eelarve_id    INTEGER;
  userName      TEXT;
  doc_id        INTEGER = data ->> 'id';
  doc_data      JSON    = data ->> 'data';
  doc_aasta     INTEGER = doc_data ->> 'aasta';
  doc_kuu       INTEGER = doc_data ->> 'kuu';
  doc_kinnitaja INTEGER = doc_data ->> 'kinnitaja';
  doc_muud      TEXT    = doc_data ->> 'muud';
  doc_rekvid    INTEGER = doc_data ->> 'rekvid';
  new_history   JSON;
  is_import     BOOLEAN = data ->> 'import';
BEGIN

  SELECT kasutaja
         INTO userName
  FROM ou.userid u
  WHERE u.rekvid = user_rekvid
    AND u.id = user_id;

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

    INSERT INTO eelarve.eelproj (rekvid, aasta, kuu, kinnitaja, muud, ajalugu, status)
    VALUES
    (doc_rekvid, doc_aasta, doc_kuu, doc_kinnitaja, doc_muud, new_history, 1)
    RETURNING id
      INTO eelarve_id;

  ELSE


    SELECT row_to_json(row)
           INTO new_history
    FROM (SELECT
            now()    AS updated,
            userName AS user,
            e.*
          FROM eelarve.eelproj e
          WHERE e.id = doc_id) row;


    UPDATE eelarve.eelproj
    SET
      rekvid    = doc_rekvid,
      aasta     = doc_aasta,
      kuu       = doc_kuu,
      kinnitaja = doc_kinnitaja,
      muud      = doc_muud,
      ajalugu   = new_history
    WHERE id = doc_id
      RETURNING id
        INTO eelarve_id;
  END IF;
  RETURN eelarve_id;

END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;


GRANT EXECUTE ON FUNCTION eelarve.sp_salvesta_eelproj(JSON, INTEGER, INTEGER) TO eelaktsepterja;

/*
SELECT eelarve.sp_salvesta_eelproj('{"id":1,"data":{"aasta":2018,"ajalugu":"{\"user\": \"vlad\", \"created\": \"2018-03-12T17:55:20.662526+02:00\"}","dok_status":"active","id":1,"kinnitaja":1,"kuu":0,"muud":"test model","properties":null,"rekvid":1,"status":1,"timestamp":,"userid":"1"}}', 1, 1);

*/
