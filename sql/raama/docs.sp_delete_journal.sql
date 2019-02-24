DROP FUNCTION IF EXISTS docs.sp_delete_journal(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_delete_journal(IN user_id INTEGER,
                                                  IN doc_id INTEGER,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER,
                                                  OUT error_message TEXT)
  RETURNS RECORD AS
$BODY$

DECLARE
  v_doc            RECORD;
  journal_history  JSONB;
  journal1_history JSONB;
  new_history      JSONB;
  DOC_STATUS       INTEGER = 3; -- документ удален
  l_arvtasu_id     INTEGER; -- связанный счет (оплата)
BEGIN

  SELECT d.*,
         u.ametnik AS user_name,
         j.kpv
         INTO v_doc
  FROM docs.doc d
         INNER JOIN docs.journal j ON j.parentid = d.id
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

  IF NOT ou.fnc_aasta_kontrol(v_doc.rekvid, v_doc.kpv)
  THEN
    RAISE NOTICE 'Period on kinni';
    error_code = 4;
    error_message = 'Ei saa kustuta dokument. Period on kinni';
    result = 0;
  END IF;


  -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

  IF v_doc.docs_ids IS NOT NULL
    AND NOT exists(SELECT 1 FROM docs.arvtasu WHERE doc_tasu_id = v_doc.id)
    AND exists(
         SELECT d.id
         FROM docs.doc d
                INNER JOIN libs.library l ON l.id = d.doc_type_id
         WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
           AND d.status <> 3 -- not deleted
           AND l.kood IN (SELECT kood
                          FROM libs.library
                          WHERE library = 'DOK'
                            AND (properties IS NULL OR properties :: JSONB @> '{"type":"document"}')))
  THEN

    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  -- Логгирование удаленного документа
  -- docs.journal

  journal_history = row_to_json(row.*) FROM (SELECT a.*
    FROM docs.journal a WHERE a.parentid = doc_id) ROW;

  -- docs.journal1

  journal1_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                             FROM (SELECT k1.*
                                                   FROM docs.journal1 k1
                                                          INNER JOIN docs.journal k ON k.id = k1.parentid
                                                   WHERE k.parentid = doc_id) row));

  SELECT row_to_json(row)
         INTO new_history
  FROM (SELECT now() AS deleted, v_doc.user_name AS user, journal_history AS journal, journal1_history AS journal1) row;

  -- удалим (если есть связанные с проводкой предоплаты рекламного налога

  DELETE
  FROM rekl.ettemaksud e
  WHERE e.journalid IN
        (SELECT id FROM docs.journal1 WHERE parentid IN (SELECT id FROM docs.journal WHERE parentid = v_doc.id));

  DELETE FROM docs.journal1 WHERE parentid IN (SELECT id FROM docs.journal WHERE parentid = v_doc.id);

  DELETE FROM docs.journal WHERE parentid = v_doc.id; --@todo констрейн на удаление


  -- удаление оплат счетов
  l_arvtasu_id = (SELECT id
                  FROM docs.arvtasu a
                  WHERE rekvid = v_doc.rekvid
                    AND doc_tasu_id = v_doc.id
                    AND a.status <> 3
  );

  IF l_arvtasu_id IS NOT NULL
  THEN

    -- удаление оплаты
    PERFORM docs.sp_delete_arvtasu(user_id, l_arvtasu_id);
  END IF;

  -- удаление связей
  UPDATE docs.doc
  SET docs_ids = array_remove(docs_ids, doc_id)
  WHERE id IN (SELECT unnest(docs_ids) FROM docs.doc WHERE id = doc_id)
    AND status < DOC_STATUS;

  -- Установка статуса ("Удален")  и сохранение истории

  UPDATE docs.doc
  SET lastupdate = now(),
      history    = coalesce(history, '[]') :: JSONB || new_history,
      rekvid     = v_doc.rekvid,
      status     = DOC_STATUS
  WHERE id = doc_id;

  result = 1;
  RETURN;
END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;

ALTER FUNCTION docs.sp_delete_journal(INTEGER, INTEGER)
  OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.sp_delete_journal(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION docs.sp_delete_journal(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_journal(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM docs.sp_delete_journal(1, 91)/*
select error_code, result, error_message from docs.sp_delete_mk(1, 422)

select * from docs.doc where id =422 

select d.*, u.ametnik as user_name 
		from docs.doc d 
		left outer join ou.userid u on u.id = 1
		where d.id = 91

select * from libs.library where id = 2
		
*/
