DROP FUNCTION IF EXISTS ou.sp_delete_userid( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_delete_userid(
  IN  user_id       INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc       RECORD;
  new_history JSON;
BEGIN

  SELECT
    u.id,
    u.kasutaja,
    u.ametnik AS user_name
  INTO v_doc
  FROM ou.userid u
  WHERE u.id = doc_id;

  IF v_doc IS NULL
  THEN
    error_code = 6;
    error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
    result = 0;
    RAISE NOTICE 'error_message %', error_message;
    RETURN;

  END IF;

  IF NOT exists(SELECT id
                FROM ou.cur_userid u
                WHERE id = user_id
                      AND u.is_admin :: BOOLEAN)
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, or puudub õigused: ' || ', userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RAISE NOTICE 'error_message %', error_message;
    RETURN;

  END IF;

  -- ajalugu
  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()                         AS deleted,
          ltrim(rtrim(v_doc.user_name)) AS user) row;

  UPDATE ou.userid
  SET
    status  = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted'),
    ajalugu = new_history
  WHERE id = doc_id;

  -- drop system account
  EXECUTE 'DROP USER IF EXISTS ' || v_doc.kasutaja;

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

GRANT EXECUTE ON FUNCTION ou.sp_delete_userid(INTEGER, INTEGER) TO dbadmin;

/*
select error_code, result, error_message from ou.sp_delete_userid(1, 5690)
*/