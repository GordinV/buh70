DROP FUNCTION IF EXISTS docs.sp_delete_pv_oper(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_delete_pv_oper(IN user_id INTEGER,
                                                  IN doc_id INTEGER,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER,
                                                  OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc           RECORD;
    v_seotud_docs   RECORD;
    pv_oper_history JSONB;
    new_history     JSONB;
    DOC_STATUS      INTEGER = 3; -- документ удален
    l_pv_oper_id    INTEGER;
    l_konto         TEXT;
BEGIN

    SELECT d.*,
           u.ametnik                                        AS user_name,
           po.liik,
           po.pv_kaart_id,
           (l.properties :: JSONB ->> 'gruppid') :: INTEGER AS grupp_id
    INTO v_doc
    FROM docs.doc d
             INNER JOIN docs.pv_oper po ON po.parentid = d.id
             INNER JOIN libs.library l ON po.pv_kaart_id = l.id
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

    -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

    IF exists(
            SELECT d.id
            FROM docs.doc d
                     INNER JOIN libs.library l ON l.id = d.doc_type_id
            WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
              AND l.kood IN ('ARV', 'MK', 'SORDER', 'KORDER'))
    THEN

        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;
        RETURN;
    END IF;

    -- Логгирование удаленного документа
    -- docs.arv

    pv_oper_history = row_to_json(row.*)
                      FROM (SELECT a.*
                            FROM docs.pv_oper a
                            WHERE a.parentid = doc_id) ROW;

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT now() AS deleted, v_doc.user_name AS user, pv_oper_history AS pv_oper) row;


    DELETE FROM docs.pv_oper WHERE parentid = v_doc.id; --@todo констрейн на удаление

    IF v_doc.liik = 4
    THEN
        -- если это операция списание, то меняем статус на активный
        UPDATE libs.library
        SET timestamp  = now(),
            properties = properties :: JSONB || '{
              "mahakantud": null
            }'::JSONB,
            status     = 1
        WHERE id = v_doc.pv_kaart_id;

    END IF;

    IF v_doc.liik = 6
    THEN
        -- переклафикация. выполнем прежнюю или возвращаем корр.счет
        SELECT d.id
        INTO l_pv_oper_id
        FROM docs.doc d
                 INNER JOIN docs.pv_oper po ON d.id = po.parentid
        WHERE po.pv_kaart_id = v_doc.pv_kaart_id
          AND liik = 6
          AND d.status <> 3
        ORDER BY id DESC
        LIMIT 1;

        IF l_pv_oper_id IS NOT NULL
        THEN
            -- выполняем переквалификацию
            PERFORM docs.pv_umberklassifitseerimine(l_pv_oper_id);
        ELSE
            -- нет, берем кор. счет или из группы
            SELECT properties::JSONB ->> 'korr_konto'
            INTO l_konto
            FROM libs.library
            WHERE id = v_doc.pv_kaart_id;

            IF l_konto IS NULL
            THEN
                SELECT konto
                INTO l_konto
                FROM com_pv_gruppid
                WHERE id = v_doc.grupp_id;
            END IF;

            UPDATE libs.library
            SET properties = properties::JSONB || jsonb_build_object('konto', l_konto)
            WHERE id = v_doc.pv_kaart_id;
        END IF;

    END IF;


    -- удаление связей
    UPDATE docs.doc
    SET docs_ids = array_remove(docs_ids, doc_id)
    WHERE id IN (SELECT unnest(v_doc.docs_ids))
      AND status < array_position((enum_range(NULL :: DOK_STATUS)), 'deleted');

    -- Установка статуса ("Удален")  и сохранение истории

    UPDATE docs.doc
    SET lastupdate = now(),
        history    = coalesce(history, '[]') :: JSONB || new_history,
        rekvid     = v_doc.rekvid,
        status     = DOC_STATUS
    WHERE id = doc_id;

    IF (v_doc.docs_ids IS NOT NULL)
    THEN
        FOR v_seotud_docs IN
            SELECT unnest(v_doc.docs_ids) AS id
            LOOP
                PERFORM docs.sp_delete_journal(user_id, v_seotud_docs.id);
            END LOOP;
    END IF;

    -- перерасчет сальдо
    PERFORM docs.sp_recalc_pv_jaak(v_doc.pv_kaart_id);

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;
ALTER FUNCTION docs.sp_delete_pv_oper(INTEGER, INTEGER)
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.sp_delete_pv_oper(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION docs.sp_delete_pv_oper(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_pv_oper(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM docs.sp_delete_pv_oper(1, 412)


select error_code, result, error_message from docs.sp_delete_mk(1, 422)

select * from docs.doc where id =422 

select d.*, u.ametnik as user_name 
		from docs.doc d 
		left outer join ou.userid u on u.id = 1
		where d.id = 412
*/
