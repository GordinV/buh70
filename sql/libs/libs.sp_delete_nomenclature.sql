DROP FUNCTION IF EXISTS libs.sp_delete_nomenclature( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION libs.sp_delete_nomenclature(
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
  nom_history     JSONB;
  new_history     JSONB;
  DOC_STATUS integer = 3; -- документ удален
BEGIN

  SELECT
    n.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM libs.nomenklatuur n
    LEFT OUTER JOIN ou.userid u ON u.id = userid
  WHERE n.id = doc_id;

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

  IF exists(
      SELECT 1
      FROM (
             SELECT id
             FROM docs.arv1
             WHERE nomid = v_doc.id
             UNION
             SELECT id
             FROM docs.korder2
             WHERE nomid = v_doc.id
             UNION
             SELECT id
             FROM docs.leping2
             WHERE nomid = v_doc.id

           ) qry
  )
  THEN

    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  UPDATE libs.nomenklatuur
  SET status = DOC_STATUS
  WHERE id = doc_id;

  result = 1;
  RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_delete_nomenclature(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_nomenclature(INTEGER, INTEGER) TO dbpeakasutaja;


/*

select * from libs.sp_delete_asutus(1, 6)
*/
