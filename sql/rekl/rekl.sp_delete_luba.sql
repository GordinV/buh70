DROP FUNCTION IF EXISTS rekl.sp_delete_luba(user_id INTEGER, doc_id INTEGER );

CREATE FUNCTION rekl.sp_delete_luba(user_id INTEGER, doc_id INTEGER, OUT error_code INTEGER, OUT result INTEGER,
                                                                     OUT error_message TEXT)
  RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
  v_doc         RECORD;
  v_seotud_docs RECORD;
  luba_history  JSONB;
  luba1_history JSONB;
  dekl_history JSONB;
  new_history   JSONB;
BEGIN

  SELECT
    d.*,
    u.ametnik AS user_name,
    l.staatus as rekl_staatus
  INTO v_doc
  FROM docs.doc d
    inner join rekl.luba l on l.parentid = d.id
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

  IF v_doc.rekl_staatus is not null and  not empty(v_doc.rekl_staatus)  and exists(
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

  luba_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM rekl.luba a WHERE a.parentid = doc_id) ROW;

  luba1_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                          FROM (SELECT l1.*
                                                FROM rekl.luba1 l1
                                                  INNER JOIN rekl.luba l ON l.id = l1.parentid
                                                WHERE l.parentid = doc_id) row));

  dekl_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                          FROM (SELECT t.*
                                                FROM rekl.toiming t
                                                WHERE t.lubaid = doc_id) row));

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          luba_history    AS luba,
          luba1_history   AS luba1,
          dekl_history as toiming
       ) row;


  DELETE FROM rekl.toiming
  WHERE lubaid = doc_id;


  DELETE FROM rekl.luba
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


/*
select error_code, result, error_message from rekl.sp_delete_luba(1, 294175)
select * from docs.doc where id =  294175

 */