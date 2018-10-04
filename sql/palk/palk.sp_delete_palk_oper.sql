-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS palk.sp_delete_palk_oper( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION palk.sp_delete_palk_oper(
  IN  user_id       INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc             RECORD;
  v_seotud_docs     RECORD;
  palk_oper_history JSONB;
  new_history       JSONB;
BEGIN

  SELECT
    d.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM docs.doc d
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

  -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths

  --	ids =  v_doc.rigths->'delete';
  IF NOT v_doc.rigths -> 'delete' @> jsonb_build_array(user_id)
  THEN
    RAISE NOTICE 'У пользователя нет прав на удаление';
    error_code = 4;
    error_message = 'Ei saa kustuta dokument. Puudub õigused';
    result = 0;
    RETURN;

  END IF;

  -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя кроме проводки)

  IF exists(
      SELECT d.id
      FROM docs.doc d
        INNER JOIN libs.library l ON l.id = d.doc_type_id
      WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
            AND l.kood IN (
        SELECT kood
        FROM libs.library
        WHERE library = 'DOK'
              AND kood NOT IN ('JOURNAL')
              AND (properties IS NULL OR properties :: JSONB @> '{"type":"document"}')
      ))
  THEN

    RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  -- Логгирование удаленного документа
  -- docs.arv

  palk_oper_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM palk.palk_oper a WHERE a.parentid = doc_id) ROW;

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()             AS deleted,
          v_doc.user_name   AS user,
          palk_oper_history AS palk_oper) row;

  -- Удаление данных из связанных таблиц (удаляем проводки)

  IF (v_doc.docs_ids IS NOT NULL)
  THEN
    FOR v_seotud_docs IN
    SELECT unnest(v_doc.docs_ids) AS id
    LOOP
      PERFORM docs.sp_delete_journal(user_id, v_seotud_docs.id);
    END LOOP;
  END IF;

  DELETE FROM palk.palk_oper
  WHERE parentid = doc_id; --@todo констрейн на удаление


  -- удаление связей
  UPDATE docs.doc
  SET docs_ids = array_remove(docs_ids, doc_id)
  WHERE id IN (
    SELECT unnest(docs_ids)
    FROM docs.doc
    WHERE id = doc_id
  )
        AND status < array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

  -- Установка статуса ("Удален")  и сохранение истории

  UPDATE docs.doc
  SET lastupdate = now(),
    history      = coalesce(history, '[]') :: JSONB || new_history,
    rekvid       = v_doc.rekvid,
    status       = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
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

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION palk.sp_delete_palk_oper(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_delete_palk_oper(INTEGER, INTEGER) TO dbpeakasutaja;
