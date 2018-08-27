DROP FUNCTION IF EXISTS ou.sp_delete_menupohi( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION ou.sp_delete_menupohi(
  IN  user_id       INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc       RECORD;
BEGIN

  SELECT
    u.ametnik AS user_name
  INTO v_doc
  FROM ou.menupohi l
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
                      AND (roles->'is_admin' @> to_jsonb(true)
                      or roles->'is_admin' @> to_jsonb(1))
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT || ', userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  UPDATE ou.menupohi
  SET
    status   =  'deleted'
  WHERE id = doc_id;

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

GRANT EXECUTE ON FUNCTION ou.sp_delete_menupohi(INTEGER, INTEGER) TO dbadmin;

/*
select error_code, result, error_message from ou.sp_delete_rekv(1, 17)
*/