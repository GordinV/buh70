DROP FUNCTION IF EXISTS libs.sp_delete_konto( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_delete_konto(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc           RECORD;
  v_dependid_docs RECORD;
  ids             INTEGER [];
  library_history JSONB;
  new_history     JSONB;
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

  --	ids =  v_doc.rigths->'delete';
  /*
    if not v_doc.rigths->'delete' @> jsonb_build_array(userid) then
      error_code = 4;
      error_message = 'Ei saa kustuta dokument. Puudub õigused';
      result  = 0;
      return;

    end if;
  */

  IF exists(
      SELECT 1
      FROM (
             SELECT id
             FROM docs.journal1
             WHERE deebet = v_doc.kood OR kreedit = v_doc.kood
             LIMIT 1
           ) qry
  )
  THEN

    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  library_history = row_to_json(row.*) FROM ( SELECT l.*
  FROM libs.library l WHERE l.id = doc_id) ROW;

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          library_history AS library) row;

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
ALTER FUNCTION libs.sp_delete_konto( INTEGER, INTEGER )
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION libs.sp_delete_konto(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION libs.sp_delete_konto(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_konto(INTEGER, INTEGER) TO dbpeakasutaja;


/*

select * from libs.sp_delete_asutus(1, 6)
*/
