DROP FUNCTION IF EXISTS ou.sp_muuda_aasta_status( INTEGER, JSON );

CREATE OR REPLACE FUNCTION ou.sp_muuda_aasta_status(
  IN  user_id       INTEGER,
  IN  params        JSON,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  l_aasta_id  INTEGER = params ->> 'id';
  l_status    INTEGER = coalesce((params ->> 'status') :: INTEGER, 0);
  l_kuu       INTEGER = params ->> 'kuu';
  l_aasta     INTEGER = params ->> 'aasta';
  v_user      RECORD;
  v_doc       RECORD;
  l_success   INTEGER;
  l_rekv_id   INTEGER = (SELECT rekvid
                         FROM ou.userid u
                         WHERE id = user_id);
  new_history JSON;
BEGIN
  SELECT *
  INTO v_user
  FROM ou.userid
  WHERE id = user_id;

  IF v_user IS NULL
  THEN
    error_code = 5;
    error_message = 'Kasutaja ei leitud, aasta.id: ' || coalesce(l_aasta_id, 0) :: TEXT || ', userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  SELECT a.*
  INTO v_doc
  FROM ou.aasta a
  WHERE a.id = l_aasta_id;

  -- ajalugu
  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()                        AS updated,
          ltrim(rtrim(v_user.ametnik)) AS user) row;

  IF (l_aasta_id IS NULL OR l_aasta_id = 0)
  THEN
    -- new perioa
    IF l_kuu IS NULL OR l_aasta IS NULL
    THEN
      error_code = 6;
      error_message = 'Puuduvad vajaliku andmed: ' :: TEXT;
      result = 0;
      RETURN;

    END IF;

    l_aasta_id = (SELECT id
                  FROM ou.aasta a
                  WHERE rekvid = l_rekv_id
                        AND kuu = l_kuu
                        AND l_aasta = aasta);

    IF l_aasta_id IS NULL OR l_aasta_id = 0
    THEN
      INSERT INTO ou.aasta (rekvid, ajalugu, kuu, aasta)
      VALUES (l_rekv_id, new_history, l_kuu, l_aasta)
      RETURNING id
        INTO l_aasta_id;

    END IF;
  ELSE

    IF v_doc IS NULL
    THEN
      error_code = 6;
      error_message = 'Dokument ei leitud, docId: ' || coalesce(l_aasta_id, 0) :: TEXT;
      result = 0;
      RETURN;

    END IF;
  END IF;

  UPDATE ou.aasta
  SET
    ajalugu = new_history,
    kinni  = l_status
  WHERE id = l_aasta_id;

  result = 1;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    result = 0;
    RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION ou.sp_muuda_aasta_status(INTEGER, JSON) TO dbpeakasutaja;

/*
select ou.sp_muuda_aasta_status(1,'{"id":0,"status":1, "kuu":7, "aasta":2018}')
*/