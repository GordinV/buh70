﻿-- Function: docs.sp_delete_smk(integer, integer)

DROP FUNCTION IF EXISTS docs.sp_delete_mk(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_delete_mk(IN l_user_id INTEGER,
                                             IN doc_id INTEGER,
                                             OUT error_code INTEGER,
                                             OUT result INTEGER,
                                             OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc           RECORD;
    mk_history      JSONB;
    mk1_history     JSONB;
    arvtasu_history JSONB;
    new_history     JSONB;
    DOC_STATUS      INTEGER = 3; -- документ удален
    v_mk            RECORD;


BEGIN

    SELECT d.*,
           (m.properties ->> 'ebatoenaolised_tagastamine_id')::INTEGER AS ebatoenaolised_tagastamine_id,
           u.ametnik                                                   AS user_name,
           m.maksepaev,
           (m.properties -> 'doc_kreedit_makse')::JSONB                AS kreedit_makse

    INTO v_doc
    FROM docs.doc d
             LEFT OUTER JOIN docs.mk m ON m.parentid = d.id
             LEFT OUTER JOIN ou.userid u ON u.id = l_user_id
    WHERE d.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RAISE EXCEPTION 'Viga %', error_message;
        RETURN;

    END IF;

    -- Проверка на связаность платежа с переносом сальдо
    IF exists(SELECT id
              FROM docs.mk
              WHERE (properties -> 'doc_kreedit_makse')::JSONB @> to_jsonb(doc_id))
    THEN

        error_code = 5;
        error_message = 'Viga: Makse seotud saldo ülekannega , kustutamine keelatud';
        result = 0;
        RAISE EXCEPTION 'Viga: Arve seotud saldo ülekannega, kustutamine keelatud';

    END IF;


    IF NOT exists(SELECT u.id
                  FROM ou.userid u
                  WHERE u.id = l_user_id
                    AND u.rekvid = v_doc.rekvid
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                        coalesce(l_user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


/*    --	ids =  v_doc.rigths->'delete';
    IF NOT v_doc.rigths -> 'delete' @> jsonb_build_array(l_user_id)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;
*/
    -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

    IF exists(
            SELECT d.id
            FROM docs.doc d
                     INNER JOIN libs.library l ON l.id = d.doc_type_id
            WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
              AND l.kood IN ('MK', 'SORDER', 'KORDER'))
    THEN

        RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;
        RETURN;
    END IF;

    -- Логгирование удаленного документа
    -- docs.arv

    mk_history = row_to_json(row.*)
                 FROM (SELECT a.*
                       FROM docs.mk a
                       WHERE a.parentid = doc_id) ROW;

    -- docs.mk1

    mk1_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                          FROM (SELECT k1.*
                                                FROM docs.mk1 k1
                                                         INNER JOIN docs.mk k ON k.id = k1.parentid
                                                WHERE k.parentid = doc_id) row));
    -- docs.arvtasu

    arvtasu_history = jsonb_build_array(array(SELECT row_to_json(row.*)
                                              FROM (SELECT at.*
                                                    FROM docs.arvtasu at
                                                             INNER JOIN docs.mk k ON k.id = at.doc_tasu_id
                                                    WHERE k.parentid = doc_id) row));


    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT now()           AS deleted,
                 v_doc.user_name AS user,
                 mk_history      AS mk,
                 mk1_history     AS mk1,
                 arvtasu_history AS arvtasu) row;

    -- Удаление данных из связанных таблиц (удаляем проводки)
    PERFORM docs.sp_delete_journal(l_user_id, mk.journalid)
    FROM (SELECT k1.*
          FROM docs.mk1 k1
                   INNER JOIN docs.mk k ON k.id = k1.parentid
          WHERE k.parentid = doc_id) mk;

    DELETE
    FROM docs.mk1
    WHERE parentid IN (SELECT a.id
                       FROM docs.arv a
                       WHERE a.parentid = v_doc.id);
    DELETE
    FROM docs.mk mk
    WHERE mk.parentid = v_doc.id;
    --@todo констрейн на удаление

    -- удаляем оплату

/*    DELETE
    FROM docs.arvtasu
    WHERE doc_tasu_id = v_doc.id;
*/
    PERFORM docs.sp_delete_arvtasu(l_user_id, at.id)
    FROM docs.arvtasu at
    WHERE doc_tasu_id = v_doc.id;

    -- удаляем ссылку на данные из выписки
    UPDATE lapsed.pank_vv SET doc_id = NULL WHERE pank_vv.doc_id = v_doc.id;

    -- удаляем возврат маловероятных , если есть
    IF (v_doc.ebatoenaolised_tagastamine_id IS NOT NULL)
    THEN
        PERFORM docs.sp_delete_journal(l_user_id, v_doc.ebatoenaolised_tagastamine_id);
    END IF;

    -- удаление связей
    UPDATE docs.doc
    SET docs_ids = array_remove(docs_ids, doc_id)
    WHERE id IN (
        SELECT unnest(docs_ids)
        FROM docs.doc d
        WHERE d.id = doc_id
    )
      AND status < DOC_STATUS;


    IF (v_doc.docs_ids IS NOT NULL)
    THEN
        PERFORM docs.sp_delete_journal(l_user_id, parentid)
        FROM docs.journal
        WHERE parentid IN (SELECT unnest(v_doc.docs_ids))
          AND parentid NOT IN (
            SELECT po.journalid
            FROM palk.palk_oper po
            WHERE po.rekvid = v_doc.rekvid
              AND journalid IS NOT NULL
        );
    END IF;

    -- Установка статуса ("Удален")  и сохранение истории

    UPDATE docs.doc
    SET lastupdate = now(),
        docs_ids   = NULL,
        history    = coalesce(history, '[]') :: JSONB || new_history,
        rekvid     = v_doc.rekvid,
        status     = DOC_STATUS
    WHERE id = doc_id;

    -- если платеж на перенос сальдо и есть кредитовые платежи, удалим их
    IF v_doc.kreedit_makse IS NOT NULL AND v_doc.kreedit_makse::TEXT <> 'null' AND
       v_doc.kreedit_makse::INTEGER > 0
    THEN
        SELECT u.id AS user_id, v_doc.kreedit_makse::INTEGER AS doc_id
        INTO v_mk
        FROM docs.doc d,
             ou.userid u
        WHERE d.id = v_doc.kreedit_makse::INTEGER
          AND d.rekvid = u.rekvid
          AND kasutaja IN (SELECT kasutaja FROM ou.userid WHERE id = l_user_id)
          AND u.status < 3
        LIMIT 1;

        IF v_mk.user_id IS NULL
        THEN
            RAISE EXCEPTION 'Viga, kasutaja siht asutuses puudub';
        END IF;
        PERFORM docs.sp_delete_mk(v_mk.user_id, v_mk.doc_id);
    END IF;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;
ALTER FUNCTION docs.sp_delete_mk( INTEGER, INTEGER )
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.sp_delete_mk(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION docs.sp_delete_mk(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_mk(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM docs.sp_delete_mk(1, 412)


select error_code, result, error_message from docs.sp_delete_mk(1, 422)

select * from docs.doc where id =422 

select d.*, u.ametnik as user_name 
		from docs.doc d 
		left outer join ou.userid u on u.id = 1
		where d.id = 412
*/
