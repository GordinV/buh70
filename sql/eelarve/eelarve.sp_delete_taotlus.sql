-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS eelarve.sp_delete_taotlus( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION eelarve.sp_delete_taotlus(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc           RECORD;
  taotlus_history JSONB;
  taotlus1_history JSONB;
  new_history     JSONB;
  DOC_STATUS      INTEGER = array_position((enum_range(NULL :: dok_status)), 'deleted'); -- документ удален
BEGIN

  SELECT
    d.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM docs.doc d
    LEFT OUTER JOIN ou.userid u ON u.id = userid
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
                WHERE id = userid
                      AND u.rekvid = v_doc.rekvid
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                    coalesce(userid, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


  --	ids =  v_doc.rigths->'delete';
  IF NOT v_doc.rigths -> 'delete' @> jsonb_build_array(userid)
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
      WHERE d.id IN (SELECT unnest(v_doc.docs_ids)))
  THEN

    RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  -- Логгирование удаленного документа
  -- docs.arv

  taotlus_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM eelarve.taotlus a WHERE a.parentid = doc_id) ROW;

  taotlus1_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                           FROM (SELECT t1.*
                                                 FROM eelarve.taotlus t
                                                   INNER JOIN eelarve.taotlus t1 ON t.id = t1.parentid
                                                 WHERE t.parentid = doc_id) row));

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          taotlus_history AS taotlus,
          taotlus1_history AS taotlus1) row;

  -- Удаление данных из связанных таблиц (удаляем проводки)

  DELETE FROM eelarve.taotlus1
  WHERE parentid IN (SELECT id
                     FROM eelarve.taotlus
                     WHERE parentid = v_doc.id);

  DELETE FROM eelarve.taotlus
  WHERE parentid = v_doc.id; --@todo констрейн на удаление

  -- Установка статуса ("Удален")  и сохранение истории

  UPDATE docs.doc
  SET lastupdate = now(),
    history      = coalesce(history, '[]') :: JSONB || new_history,
    rekvid       = v_doc.rekvid,
    status       = DOC_STATUS
  WHERE id = doc_id;

  result = 1;
  RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION eelarve.sp_delete_taotlus(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION eelarve.sp_delete_taotlus(INTEGER, INTEGER) TO dbpeakasutaja;
