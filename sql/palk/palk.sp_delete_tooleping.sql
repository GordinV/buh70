DROP FUNCTION IF EXISTS palk.sp_delete_tooleping( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_delete_tooleping(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc          RECORD;
  leping_history JSONB;
  new_history    JSONB;
BEGIN

  SELECT
    t.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM palk.tooleping t
    LEFT OUTER JOIN ou.userid u ON u.id = userid
  WHERE a.id = doc_id;

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
                      AND (u.rekvid = v_doc.rekvid OR v_doc.rekvid IS NULL OR v_doc.rekvid = 0)
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                    coalesce(userid, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

  IF exists(
      SELECT 1
      FROM (
             SELECT id
             FROM palk.palk_oper
             WHERE lepingId = doc_id
             UNION
             SELECT id
             FROM palk.palk_kaart
             WHERE lepingId = doc_id
             UNION
             SELECT id
             FROM palk.taotlus_mvt
             WHERE lepingId = doc_id
             UNION
             SELECT id
             FROM palk.palk_jaak
             WHERE lepingId = doc_id
             UNION
             SELECT id
             FROM palk.palk_taabel1
             WHERE lepingId = doc_id
             UNION
             SELECT id
             FROM palk.puudumine
             WHERE lepingId = doc_id
           ) qry
  )
  THEN

    RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  -- Логгирование удаленного документа

  leping_history = row_to_json(row.*) FROM ( SELECT t.*
  FROM palk.tooleping t WHERE t.id = doc_id) ROW;

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          leping_history  AS tooleping) row;

  -- Установка статуса ("Удален")  и сохранение истории
  UPDATE palk.tooleping
  SET status = 3
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

GRANT EXECUTE ON FUNCTION palk.sp_delete_tooleping(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION palk.sp_delete_tooleping(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_delete_tooleping(INTEGER, INTEGER) TO dbpeakasutaja;


/*

select * from libs.sp_delete_asutus(1, 6)
*/
