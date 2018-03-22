DROP FUNCTION IF EXISTS ou.sp_delete_rekv( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_delete_rekv(
  IN  user_id       INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc       RECORD;
  v_user      RECORD;
  l_success   INTEGER;
  new_history JSON;
BEGIN

  SELECT
    l.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM ou.rekv l
    LEFT OUTER JOIN ou.userid u ON u.id = user_id
  WHERE l.id = doc_id;

  IF v_doc IS NULL
  THEN
    error_code = 6;
    error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  IF NOT exists(SELECT id
                FROM ou.userid u
                WHERE id = user_id
                      AND not empty(u.admin)
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(doc_id, 0) :: TEXT || ', userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  -- ajalugu
  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()    AS deleted,
          ltrim(rtrim(v_doc.user_name)) AS user) row;


  UPDATE ou.rekv
  SET
    ajalugu  = new_history,
    status   = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted'),
    parentid = 999 -- sane as deleted, depreciated
  WHERE id = doc_id;

  -- should delete all users

  FOR v_user IN
  SELECT id
  FROM ou.userid
  WHERE rekvid = doc_id
  LOOP
    SELECT sp.result
    INTO l_success
    FROM ou.sp_delete_userid(user_id, v_user.id) as sp;
    IF l_success IS NULL OR l_success = 0
    THEN
      RAISE EXCEPTION 'Ei saa kustuta kasutajad %', l_success;
    END IF;
  END LOOP;

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

GRANT EXECUTE ON FUNCTION ou.sp_delete_rekv(INTEGER, INTEGER) TO dbadmin;

/*
select error_code, result, error_message from ou.sp_delete_rekv(1, 17)
*/