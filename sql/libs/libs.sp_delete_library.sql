DROP FUNCTION IF EXISTS libs.sp_delete_library( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_delete_library(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc           RECORD;
BEGIN

  SELECT
    l.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM libs.library l
    LEFT OUTER JOIN ou.userid u ON u.id = userid
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
                WHERE id = userid
                      AND (u.rekvid = v_doc.rekvid OR v_doc.rekvid IS NULL OR v_doc.rekvid = 0)
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                    coalesce(userid, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  UPDATE libs.library
  SET status = 3
  WHERE id = doc_id;

  result = 1;
  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % % %', MESSAGE_TEXT, PG_EXCEPTION_DETAIL, PG_EXCEPTION_HINT;
    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = MESSAGE_TEXT;
    result = 0;
  RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_delete_library(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_library(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM libs.sp_delete_library(1, 186)

*/