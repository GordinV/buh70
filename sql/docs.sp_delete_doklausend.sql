DROP FUNCTION IF EXISTS docs.sp_delete_doklausend( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_delete_doklausend(
  IN  user_id        INTEGER,
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
    d.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM docs.doklausheader d
    LEFT OUTER JOIN ou.userid u ON u.id = userid
  WHERE d.id = doc_id;

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
                      AND (u.rekvid = v_doc.rekvid OR v_doc.rekvid IS NULL OR v_doc.rekvid = 0)
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                    coalesce(user_id, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  UPDATE docs.doklausheader
  SET status = 3
  WHERE id = doc_id;

  result = 1;
  RETURN;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_delete_doklausend(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_doklausend(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM libs.sp_delete_library(1, 186)

*/