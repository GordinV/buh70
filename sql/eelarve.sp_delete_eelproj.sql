DROP FUNCTION IF EXISTS eelarve.sp_delete_eelproj( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.sp_delete_eelproj(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc RECORD;
BEGIN

  SELECT
    l.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM eelarve.eelproj l
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

  UPDATE eelarve.eelproj
  SET status = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
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

GRANT EXECUTE ON FUNCTION eelarve.sp_delete_eelproj(INTEGER, INTEGER) TO eelaktsepterja;

/*
select error_code, result, error_message from eelarve.sp_delete_eelarve(1, 4, 0)
*/