DROP FUNCTION IF EXISTS libs.sp_delete_dokprop( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_delete_dokprop(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc           RECORD;
  l_doc_id INTEGER = 0;
BEGIN

  SELECT
    d.*,
    l.rekvid,
    u.ametnik AS user_name
  INTO v_doc
  FROM libs.dokprop d
    INNER JOIN libs.library l on l.id = d.parentid
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

  UPDATE libs.dokprop
  SET status = 3
  WHERE id = doc_id
    RETURNING ID INTO l_doc_id;

  result = 1;

  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_delete_dokprop(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_dokprop(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM libs.sp_delete_library(1, 186)

*/