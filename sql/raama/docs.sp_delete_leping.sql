DROP FUNCTION IF EXISTS docs.sp_delete_leping( INTEGER, INTEGER );

CREATE OR REPLACE FUNCTION docs.sp_delete_leping(
  IN  userid        INTEGER,
  IN  doc_id        INTEGER,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT)
AS
$BODY$

DECLARE
  v_doc           RECORD;
  v_dependid_docs RECORD;
  leping_id          INTEGER;
  ids             INTEGER [];
  leping1_history     JSONB;
  leping2_history    JSONB;
  new_history     JSONB;
  DOC_STATUS      INTEGER = 3; -- документ удален
BEGIN

  SELECT
    d.*,
    u.ametnik AS user_name
  INTO v_doc
  FROM docs.doc d
    LEFT OUTER JOIN ou.userid u ON u.id = userid
  WHERE d.id = doc_id;

  -- проверка на пользователя и его соответствие учреждению

  IF NOT exists(SELECT id
                FROM ou.userid u
                WHERE id = userid
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
  IF NOT v_doc.rigths -> 'delete' @> jsonb_build_array(userid)
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
      WHERE d.id IN (SELECT unnest(v_doc.docs_ids)))
  THEN

    RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
    error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
    error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
    result = 0;
    RETURN;
  END IF;

  -- Логгирование удаленного документа
  -- docs.leping1

  leping1_history = row_to_json(row.*) FROM ( SELECT a.*
  FROM docs.leping1 a WHERE a.parentid = doc_id) ROW;

  -- docs.leping2

  leping2_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                         FROM (SELECT l2.*
                                               FROM docs.leping2 l2
                                                 INNER JOIN docs.leping1 l1 ON l1.id = l2.parentid
                                               WHERE l1.parentid = doc_id) row));

  SELECT row_to_json(row)
  INTO new_history
  FROM (SELECT
          now()           AS deleted,
          v_doc.user_name AS user,
          leping1_history     AS leping1,
          leping2_history    AS leping2) row;


  DELETE FROM docs.leping2
  WHERE parentid IN (SELECT id
                     FROM docs.leping1
                     WHERE parentid = v_doc.id);
  DELETE FROM docs.leping1
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

GRANT EXECUTE ON FUNCTION docs.sp_delete_leping(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_leping(INTEGER, INTEGER) TO dbpeakasutaja;


/*

SELECT
  error_code,
  result,
  error_message
FROM docs.sp_delete_leping(1, 125);


select docs.sp_salvesta_arv('{"id":0,"doc_type_id":"ARV","data":{"id":0,"created":"2016-05-05T21:39:57.050726","lastupdate":"2016-05-05T21:39:57.050726","bpm":null,"doc":"Arved","doc_type_id":"ARV","status":"Черновик","number":"321","summa":24,"rekvid":null,"liik":0,"operid":null,"kpv":"2016-05-05","asutusid":1,"arvid":null,"lisa":"lisa","tahtaeg":"2016-05-19","kbmta":null,"kbm":4,"tasud":null,"tasudok":null,"muud":"muud","jaak":"0.00","objektid":null,"objekt":null,"regkood":null,"asutus":null},
"details":[{"id":"NEW0.6577064044198089","[object Object]":null,"nomid":"1","kogus":2,"hind":10,"kbm":4,"kbmta":20,"summa":24,"kood":"PAIGALDUS","nimetus":"PV paigaldamine"}]}',1, 1);

*/