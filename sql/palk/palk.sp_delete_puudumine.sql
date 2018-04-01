DROP FUNCTION IF EXISTS palk.sp_delete_puudumine( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_delete_puudumine(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc       RECORD;
  new_history JSONB;
BEGIN

  SELECT
    t.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM palk.puudumine t
    LEFT OUTER JOIN ou.userid u ON u.id = userid
  WHERE t.id = doc_id;

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
                WHERE id = userid
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || ', userId:' ||
                    coalesce(userid, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  -- Логгирование удаленного документа

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user) row;

  -- Установка статуса ("Удален")  и сохранение истории
  UPDATE palk.puudumine
  SET status = 'deleted',
    ajalugu  = new_history
  WHERE id = doc_id;

  result = 1;
  RETURN;
  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    error_code = 1;
    result = 0;
    RETURN;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_delete_puudumine(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION palk.sp_delete_puudumine(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_delete_puudumine(INTEGER, INTEGER) TO dbpeakasutaja;


/*

select * from palk.sp_delete_palk_kaart(1,2)
*/
