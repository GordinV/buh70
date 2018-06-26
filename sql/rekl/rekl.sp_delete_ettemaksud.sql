DROP FUNCTION IF EXISTS rekl.sp_delete_ettemaksud(user_id INTEGER, doc_id INTEGER );

CREATE FUNCTION rekl.sp_delete_ettemaksud(user_id INTEGER, doc_id INTEGER, OUT error_code INTEGER, OUT result INTEGER,
                                                                           OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  v_doc RECORD;
BEGIN

  SELECT
    d.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM rekl.ettemaksud d
    LEFT OUTER JOIN ou.userid u ON u.id = user_id
  WHERE d.id = doc_id;

  -- проверка на пользователя и его соответствие учреждению

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
                      AND u.rekvid = v_doc.rekvid
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  UPDATE rekl.ettemaksud
  SET staatus = 'deleted'
  WHERE id = doc_id;

  result = 1;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    result = 0;
    error_code = 1;
    error_message = SQLERRM;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION rekl.sp_delete_ettemaksud(user_id INTEGER, doc_id INTEGER ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION rekl.sp_delete_ettemaksud(user_id INTEGER, doc_id INTEGER ) TO dbpeakasutaja;
