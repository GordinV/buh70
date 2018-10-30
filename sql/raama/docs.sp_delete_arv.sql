DROP FUNCTION IF EXISTS docs.sp_delete_arv( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_delete_arv(
  IN  user_id       INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
AS
$BODY$

DECLARE
  v_doc           RECORD;
  v_dependid_docs RECORD;
  arv_id          INTEGER;
  ids             INTEGER [];
  arv_history     JSONB;
  arv1_history    JSONB;
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

  IF NOT exists(SELECT id
                FROM ou.userid u
                WHERE id = user_id
                      AND u.rekvid = v_doc.rekvid
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud';
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

  -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

  IF exists(
      SELECT d.id
      FROM docs.doc d
        INNER JOIN libs.library l ON l.id = d.doc_type_id
      WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
            AND l.kood IN ('ARV', 'MK', 'SORDER', 'KORDER'))
  THEN

    RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  -- Логгирование удаленного документа
  -- docs.arv

  arv_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM docs.arv a WHERE a.parentid = doc_id) ROW;

  -- docs.arv1

  arv1_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                         FROM (SELECT a1.*
                                               FROM docs.arv1 a1
                                                 INNER JOIN docs.arv a ON a.id = a1.parentid
                                               WHERE a.parentid = doc_id) row));
  -- docs.arvtasu

  arvtasu_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                            FROM (SELECT at.*
                                                  FROM docs.arvtasu at
                                                    INNER JOIN docs.arv a ON a.id = at.doc_arv_id
                                                  WHERE a.parentid = doc_id) row));

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          arv_history     AS arv,
          arv1_history    AS arv1,
          arvtasu_history AS arvtasu) row;

  -- удаление связей
  UPDATE docs.doc
  SET docs_ids = array_remove(docs_ids, v_doc.id)
  WHERE id IN (
    SELECT unnest(docs_ids)
    FROM docs.doc
    WHERE id = v_doc.id
  )
        AND status < DOC_STATUS;


  DELETE FROM docs.arv1
  WHERE parentid IN (SELECT id
                     FROM docs.arv
                     WHERE parentid = v_doc.id);
  DELETE FROM docs.arv
  WHERE parentid = v_doc.id; --@todo констрейн на удаление

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

  -- удаляем ссылки на договор
  IF exists(SELECT id
            FROM docs.leping1
            WHERE parentid IN (SELECT unnest(v_doc.docs_ids)))
  THEN
    UPDATE docs.doc
    SET docs_ids = array_remove(docs_ids, doc_id)
    WHERE id IN (SELECT unnest(v_doc.docs_ids));
  END IF;


  result = 1;
  RETURN;
END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_delete_arv(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_arv(INTEGER, INTEGER) TO dbpeakasutaja;


/*
SELECT
  error_code,
  result,
  error_message
FROM docs.sp_delete_arv(1, 125);


select docs.sp_salvesta_arv('{"id":0,"doc_type_id":"ARV","data":{"id":0,"created":"2016-05-05T21:39:57.050726","lastupdate":"2016-05-05T21:39:57.050726","bpm":null,"doc":"Arved","doc_type_id":"ARV","status":"Черновик","number":"321","summa":24,"rekvid":null,"liik":0,"operid":null,"kpv":"2016-05-05","asutusid":1,"arvid":null,"lisa":"lisa","tahtaeg":"2016-05-19","kbmta":null,"kbm":4,"tasud":null,"tasudok":null,"muud":"muud","jaak":"0.00","objektid":null,"objekt":null,"regkood":null,"asutus":null},
"details":[{"id":"NEW0.6577064044198089","[object Object]":null,"nomid":"1","kogus":2,"hind":10,"kbm":4,"kbmta":20,"summa":24,"kood":"PAIGALDUS","nimetus":"PV paigaldamine"}]}',1, 1);

*/