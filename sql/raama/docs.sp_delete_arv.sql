DROP FUNCTION IF EXISTS docs.sp_delete_arv(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_delete_arv(IN user_id INTEGER,
                                              IN doc_id INTEGER,
                                              OUT error_code INTEGER,
                                              OUT result INTEGER,
                                              OUT error_message TEXT)
AS
$BODY$

DECLARE
    v_doc           RECORD;
    v_dependid_docs RECORD;
    arv_id          INTEGER;
    ids             INTEGER[];
    arv_history     JSONB;
    arv1_history    JSONB;
    arvtasu_history JSONB;
    new_history     JSONB;
    DOC_STATUS      INTEGER = 3; -- документ удален
    v_mk            RECORD;
    l_tasu_id       INTEGER; -- оплата счета пенсионера
BEGIN

    SELECT d.*,
           u.ametnik                                AS user_name,
           a.kpv,
           a.id                                     AS doc_arv_id,
           a.properties,
           a.properties ->> 'tyyp'                  AS tyyp,
           a.liik,
           a.asutusid,
           (a.properties ->> 'asendus_id')::INTEGER AS asendus_id
    INTO v_doc
    FROM docs.doc d
             LEFT OUTER JOIN ou.userid u ON u.id = user_id
             LEFT OUTER JOIN docs.arv a ON a.parentid = d.id
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

    -- нельзя удалять отправленный по эл. каналам счет
    IF exists(
            SELECT id
            FROM docs.doc
            WHERE id = doc_id
              AND (history::TEXT LIKE '%"email":%'
                OR history::TEXT LIKE '%"earve":%'))
    THEN

        error_code = 5;
        error_message = 'Viga: Arve oli esitatud, kustutamine keelatud';
        result = 0;
        RAISE EXCEPTION 'Viga: Arve oli esitatud, kustutamine keelatud';
    END IF;


    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths

    --	ids =  v_doc.rigths->'delete';

/*    IF NOT v_doc.rigths -> 'delete' @> jsonb_build_array(user_id)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        --     result = 0;
--      RETURN;

    END IF;
*/
    -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)
/*
    IF exists(
            SELECT d.id
            FROM docs.doc d
                     INNER JOIN libs.library l ON l.id = d.doc_type_id
            WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
              AND d.status <> 3
              AND l.kood IN ('MK', 'SORDER', 'KORDER','SMK','VMK'))
    THEN

        RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;
        RETURN;
    END IF;
*/
    IF v_doc.tyyp IS NOT NULL AND coalesce(v_doc.tyyp, '') = 'HOOLDEKODU_ISIKU_OSA' AND v_doc.liik = 0
    THEN
        l_tasu_id = (SELECT doc_tasu_id FROM docs.arvtasu WHERE doc_arv_id = doc_id AND status < 3 LIMIT 1);

    END IF;

    -- удалим если есть замещающие проводки
    IF v_doc.asendus_id IS NOT NULL
    THEN
        PERFORM docs.sp_delete_journal(u.id, j.parentid)
        FROM docs.journal j,
             (SELECT id, rekvid
              FROM ou.userid u
              WHERE kasutaja IN (SELECT kasutaja FROM ou.userid WHERE id = user_Id)
                AND status < 3) u
        WHERE j.rekvid = u.rekvid
          AND j.properties IS NOT NULL
          AND (j.properties ->> 'asendus_id')::INTEGER IN
              (SELECT (a1.properties ->> 'asendus_id')::INTEGER AS asendus_id
               FROM docs.arv1 a1
                        INNER JOIN docs.arv a ON a.id = a1.parentid
               WHERE a.parentid = v_doc.id
                 AND a1.properties ->> 'asendus_id' IS NOT NULL);

    END IF;


    -- Логгирование удаленного документа
    -- docs.arv

    arv_history = row_to_json(row.*)
                  FROM (SELECT a.*
                        FROM docs.arv a
                        WHERE a.parentid = doc_id) ROW;

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
    FROM (SELECT now()           AS deleted,
                 v_doc.user_name AS user,
                 arv_history     AS arv,
                 arv1_history    AS arv1,
                 arvtasu_history AS arvtasu
         ) row;

    -- удаление оплат
    FOR v_mk IN
        SELECT id, doc_tasu_id FROM docs.arvtasu WHERE doc_arv_id = doc_id
        LOOP
            -- удаление оплат
            DELETE FROM docs.arvtasu WHERE id = v_mk.id;
            -- перерасчет сальдо платежа
            PERFORM docs.sp_update_mk_jaak(v_mk.doc_tasu_id);
        END LOOP;


    --    DELETE FROM docs.arvtasu WHERE doc_arv_id = doc_id;

    -- удаление связей
    UPDATE docs.doc
    SET docs_ids = array_remove(docs_ids, v_doc.id)
    WHERE id IN (SELECT unnest(docs_ids) FROM docs.doc WHERE id = v_doc.id)
      AND status < DOC_STATUS;

    IF (SELECT (properties ->> 'arve_id') AS arve_id
        FROM docs.arv1 a1
        WHERE a1.parentid IN (SELECT id FROM docs.arv WHERE parentid = v_doc.id)
        LIMIT 1) IS NOT NULL
    THEN
        -- есть ссылка, надо снять
        UPDATE docs.doc
        SET docs_ids = array_remove(docs_ids, doc_id)
        WHERE id IN (SELECT (a1.properties ->> 'arve_id') :: INTEGER
                     FROM docs.arv1 a1
                              INNER JOIN docs.arv a ON a.id = a1.parentid
                     WHERE a.parentid = doc_id);
    END IF;

    -- уберем ссылку на счет
    UPDATE docs.mk SET arvid = NULL WHERE arvid = doc_id;
--    PERFORM docs.sp_update_mk_jaak(parentid) FROM docs.mk WHERE arvid = doc_id;

    UPDATE docs.korder1 SET arvid = NULL WHERE arvid = doc_id;

    --поменяем статус табелей в род.плате
    IF exists(SELECT 1 FROM pg_class WHERE relname = 'lapse_taabel')
    THEN
        UPDATE lapsed.lapse_taabel
        SET staatus = 1
        WHERE staatus = 2
          AND rekvid = v_doc.rekvid
          AND id IN (
            SELECT (properties ->> 'lapse_taabel_id')::INTEGER FROM docs.arv1 WHERE parentid = v_doc.doc_arv_id
        );
    END IF;

    DELETE FROM docs.arv1 WHERE parentid IN (SELECT id FROM docs.arv WHERE parentid = v_doc.id);
    DELETE FROM docs.arv WHERE parentid = v_doc.id;
    --@todo констрейн на удаление


    -- Установка статуса ("Удален")  и сохранение истории

    UPDATE docs.doc
    SET lastupdate = now(),
        history    = coalesce(history, '[]') :: JSONB || new_history,
        rekvid     = v_doc.rekvid,
        status     = DOC_STATUS
    WHERE id = doc_id;

    -- Удаление данных из связанных таблиц (удаляем проводки)

    IF (v_doc.docs_ids IS NOT NULL)
    THEN
        PERFORM docs.sp_delete_journal(user_id, parentid)
        FROM docs.journal
        WHERE parentid IN (SELECT unnest(v_doc.docs_ids)); -- @todo процедура удаления

    END IF;

    -- удаляем ссылки на договор
    IF exists(SELECT id FROM docs.leping1 WHERE parentid IN (SELECT unnest(v_doc.docs_ids)))
    THEN
        UPDATE docs.doc SET docs_ids = array_remove(docs_ids, doc_id) WHERE id IN (SELECT unnest(v_doc.docs_ids));
    END IF;

    IF v_doc.tyyp IS NOT NULL AND coalesce(v_doc.tyyp, '') = 'HOOLDEKODU_ISIKU_OSA' AND v_doc.liik = 0
    THEN
        -- удалим списание пенсии
        RAISE NOTICE 'l_tasu_id %', l_tasu_id;

        IF l_tasu_id IS NOT NULL
        THEN
            PERFORM docs.sp_delete_journal(user_id, l_tasu_id);

            -- расчет сальдо
            PERFORM hooldekodu.sp_calc_hoojaak(v_doc.asutusId);

        END IF;

    END IF;


    --удалим из кеша отчета, если он там
    IF exists(SELECT 1 FROM pg_class WHERE relname = 'saldo_ja_kaive')
    THEN
        DELETE
        FROM lapsed.saldo_ja_kaive
        WHERE (params ->> 'kpv_end' IS NULL OR ((params ->> 'kpv_end')::DATE <= v_doc.kpv
            OR (params ->> 'kpv_start')::DATE >= v_doc.kpv))
          AND rekvid = v_doc.rekvid;
    END IF;
    -- удалим сссылку в табеле
    IF exists(SELECT 1 FROM pg_class WHERE relname = 'hootaabel')
    THEN
        UPDATE hooldekodu.hootaabel
        SET arvid      = 0,
            properties = properties || jsonb_build_object('omavalitsus_osa', 0, 'isiku_osa', 0)
        WHERE arvid = v_doc.id;
        UPDATE hooldekodu.hootaabel
        SET sugulane_arv_id = NULL,
            properties      = properties || jsonb_build_object('sugulane_osa', 0)
        WHERE sugulane_arv_id = v_doc.id;

    END IF;


    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_delete_arv(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_arv(INTEGER, INTEGER) TO dbpeakasutaja;


/*
SELECT
  error_code,
  result,
  error_message
FROM docs.sp_delete_arv(70, 2377664);


select docs.sp_salvesta_arv('{"id":0,"doc_type_id":"ARV","data":{"id":0,"created":"2016-05-05T21:39:57.050726","lastupdate":"2016-05-05T21:39:57.050726","bpm":null,"doc":"Arved","doc_type_id":"ARV","status":"Черновик","number":"321","summa":24,"rekvid":null,"liik":0,"operid":null,"kpv":"2016-05-05","asutusid":1,"arvid":null,"lisa":"lisa","tahtaeg":"2016-05-19","kbmta":null,"kbm":4,"tasud":null,"tasudok":null,"muud":"muud","jaak":"0.00","objektid":null,"objekt":null,"regkood":null,"asutus":null},
"details":[{"id":"NEW0.6577064044198089","[object Object]":null,"nomid":"1","kogus":2,"hind":10,"kbm":4,"kbmta":20,"summa":24,"kood":"PAIGALDUS","nimetus":"PV paigaldamine"}]}',1, 1);

*/