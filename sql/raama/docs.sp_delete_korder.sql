-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS docs.sp_delete_korder( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_delete_korder(
  IN  user_id        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc           RECORD;
  korder1_history JSONB;
  korder2_history JSONB;
  arvtasu_history JSONB;
  new_history     JSONB;
  DOC_STATUS      INTEGER = 3; -- документ удален
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

  korder1_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM docs.korder1 a WHERE a.parentid = doc_id) ROW;

  -- docs.mk1

  korder2_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                            FROM (SELECT k1.*
                                                  FROM docs.mk1 k1
                                                    INNER JOIN docs.mk k ON k.id = k1.parentid
                                                  WHERE k.parentid = doc_id) row));
  -- docs.arvtasu

  arvtasu_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                            FROM (SELECT at.*
                                                  FROM docs.arvtasu at
                                                    INNER JOIN docs.korder1 k ON k.id = at.doc_tasu_id
                                                  WHERE k.parentid = doc_id) row));

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          korder1_history AS korder1,
          korder2_history AS korder2,
          arvtasu_history AS arvtasu) row;


  DELETE FROM docs.korder2
  WHERE parentid IN (SELECT id
                     FROM docs.arv
                     WHERE parentid = v_doc.id);
  DELETE FROM docs.korder1
  WHERE parentid = v_doc.id; --@todo констрейн на удаление

  -- удаляем оплату
  PERFORM docs.sp_delete_arvtasu(user_id, id)
  FROM docs.arvtasu a
  WHERE a.doc_tasu_id = doc_id;

  -- удаление связей
  UPDATE docs.doc
  SET docs_ids = array_remove(docs_ids, doc_id)
  WHERE id IN (
    SELECT unnest(v_doc.docs_ids)
  )
        AND status < DOC_STATUS;

  -- Установка статуса ("Удален")  и сохранение истории
  UPDATE docs.doc
  SET lastupdate = now(),
    history      = coalesce(history, '[]') :: JSONB || new_history,
    rekvid       = v_doc.rekvid,
    status       = DOC_STATUS
  WHERE id = doc_id;

  -- Удаление данных из связанных таблиц (удаляем проводки)

  IF (v_doc.docs_ids IS NOT NULL)
  THEN
    PERFORM docs.sp_delete_journal(user_id, parentid)
    FROM docs.journal
    WHERE parentid IN (SELECT unnest(v_doc.docs_ids)); -- @todo процедура удаления
  END IF;

  result = 1;
  RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
ALTER FUNCTION docs.sp_delete_korder( INTEGER, INTEGER )
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.sp_delete_korder(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_korder(INTEGER, INTEGER) TO dbpeakasutaja;
