DROP FUNCTION IF EXISTS rekl.sp_delete_toiming(user_id INTEGER, doc_id INTEGER );

CREATE FUNCTION rekl.sp_delete_toiming(user_id INTEGER, doc_id INTEGER, OUT error_code INTEGER, OUT result INTEGER,
                                                                        OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  v_doc         RECORD;
  v_seotud_docs RECORD;
  toiming_history  JSONB;
  new_history   JSONB;
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

  toiming_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM rekl.toiming a WHERE a.parentid = doc_id) ROW;

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          toiming_history    AS toiming) row;


  DELETE FROM rekl.toiming
  WHERE parentid = doc_id;

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

END;
$$;
