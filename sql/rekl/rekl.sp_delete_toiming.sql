DROP FUNCTION IF EXISTS rekl.sp_delete_toiming(user_id INTEGER, doc_id INTEGER);

CREATE FUNCTION rekl.sp_delete_toiming(user_id INTEGER, doc_id INTEGER, OUT error_code INTEGER, OUT result INTEGER,
                                       OUT error_message TEXT)
    RETURNS RECORD
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_doc            RECORD;
    v_seotud_docs    RECORD;
    toiming_history  JSONB;
    new_history      JSONB;
    l_seotud_dekl_id INTEGER;
    v_dekl           RECORD;
BEGIN

    SELECT d.*,
           t.tyyp,
           t.asutusid,
           t.kpv,
           u.ametnik AS user_name,
           u.roles,
           t.staatus

           INTO v_doc
    FROM docs.doc d
             INNER JOIN rekl.toiming t ON t.parentid = d.id
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
    --  IF NOT v_doc.rigths -> 'delete' @> jsonb_build_array(user_id)

    IF v_doc.staatus IS NOT NULL AND NOT (v_doc.roles ->> 'is_rekl_administraator') :: BOOLEAN
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление %', v_doc.staatus;
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;


    UPDATE rekl.toiming SET staatus = 'deleted' WHERE parentid = doc_id;

    IF (v_doc.docs_ids IS NOT NULL)
    THEN
        FOR v_seotud_docs IN
            SELECT unnest(v_doc.docs_ids) AS id
            LOOP
                -- убрать ссылку на документ
                UPDATE docs.doc SET docs_ids = array_remove(docs_ids, v_doc.id) WHERE id = v_seotud_docs.id;
                UPDATE docs.doc SET docs_ids = array_remove(docs_ids, v_seotud_docs.id) WHERE id = v_doc.id;

                PERFORM docs.sp_delete_journal(user_id, v_seotud_docs.id);

            END LOOP;
    END IF;

    IF v_doc.tyyp = 'TASU'
    THEN
        RAISE NOTICE 'tasu';

        -- оплата, удаляем списание предоплаты
        DELETE
        FROM rekl.ettemaksud
        WHERE dokid = v_doc.id
          AND doktyyp = 'KREEDIT';

        -- меняем статус декларации если ее сальдо = 0

        SELECT t.*,
               rekl.fnc_dekl_jaak(t.parentid) AS jaak
               INTO v_dekl
        FROM rekl.toiming t
        WHERE t.parentid IN (SELECT unnest(v_doc.docs_ids :: INTEGER[]))
          AND t.tyyp IN ('DEKL', 'INTRESS')
          AND t.staatus = 'closed'
        LIMIT 1;

        RAISE NOTICE 'tasu found dekl % summa %', v_dekl.jaak, v_dekl.summa;

        IF (coalesce(v_dekl.jaak, v_dekl.summa) = v_dekl.summa)
        THEN
            RAISE NOTICE 'tasu change status %', v_dekl.id;

            -- меняем статус декларации
            UPDATE rekl.toiming SET staatus = 'active' WHERE id = v_dekl.id;
        END IF;


-- нимаем статус с предоплаты за этот период
        UPDATE rekl.ettemaksud
        SET staatus = 'active'
        WHERE asutusid = v_doc.asutusid
          and doktyyp = 'DEEBET'
          AND month(kpv) = month(v_doc.kpv)
          AND year(kpv) = year(v_doc.kpv);

    END IF;

    -- Установка статуса ("Удален")  и сохранение истории
    SELECT row_to_json(row) INTO new_history
    FROM (SELECT now() AS deleted, v_doc.user_name AS user) row;


    UPDATE docs.doc
    SET lastupdate = now(),
        history    = coalesce(history, '[]') :: JSONB || new_history,
        rekvid     = v_doc.rekvid,
        status     = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted')
    WHERE id = doc_id;


    result = 1;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            result = 0;
            error_code = 1;
            error_message = SQLERRM;
            RETURN;

END;
$$;
