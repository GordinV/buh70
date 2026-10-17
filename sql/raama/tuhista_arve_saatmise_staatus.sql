DROP FUNCTION IF EXISTS docs.tuhista_arve_saatmise_staatus(INTEGER);

CREATE OR REPLACE FUNCTION docs.tuhista_arve_saatmise_staatus(l_log_id INTEGER)
    RETURNS jsonb AS
$BODY$
DECLARE
    v_arv_rida    RECORD;
    l_jsonb_arved JSONB;
    l_rekv_id     INTEGER;
    l_doc_id      INTEGER;
    l_response    JSONB = '[]'::JSONB; -- результат
BEGIN
    -- 1. Считываем результат работы агента и учреждение из ou.logs
    SELECT 
        l.rekvid,
        l.propertis -> 'result'
    INTO 
        l_rekv_id,
        l_jsonb_arved
    FROM ou.logs l
    WHERE l.id = l_log_id;

    -- Проверка на наличие данных в логе
    IF l_jsonb_arved IS NULL OR jsonb_typeof(l_jsonb_arved) <> 'array' THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Logi kirje ei leitud või result ei ole massiiv',
            'log_id', l_log_id
        );
    END IF;

    -- 2. Итерируемся по массиву ошибок с распаковкой через jsonb_to_recordset
    FOR v_arv_rida IN
        SELECT *
        FROM jsonb_to_recordset(l_jsonb_arved) AS x(
            doc_number TEXT,
            status TEXT,
            reason TEXT,
            recipient_email TEXT
        )
    LOOP
        l_doc_id := NULL;

        -- 3. Ищем документ счета с фильтрацией по номеру, учреждению и адресу получателя
        SELECT d.id
        INTO l_doc_id
        FROM docs.arv a
        INNER JOIN docs.doc d ON d.id = a.parentid
        WHERE trim(a.number) = trim(v_arv_rida.doc_number)
          AND (l_rekv_id IS NULL OR d.rekvid = l_rekv_id)
          AND EXISTS (
              SELECT 1
              FROM jsonb_array_elements(coalesce(d.history, '[]'::JSONB)) AS e
              WHERE e ? 'email'
                AND (
                    v_arv_rida.recipient_email IS NULL 
                    OR empty(v_arv_rida.recipient_email)
                    OR lower(trim(e ->> 'aadress')) = lower(trim(v_arv_rida.recipient_email))
                )
          )
        ORDER BY d.id DESC
        LIMIT 1;

        -- 4. Если счет найден, аннулируем статус успешной отправки
        IF l_doc_id IS NOT NULL THEN
            -- Обновляем историю в docs.doc: заменяем email на email_error с сохранением статуса и причины
            UPDATE docs.doc
            SET history = history || jsonb_build_object('email_error_3', now(), 'info', v_arv_rida.reason, 'status', v_arv_rida.status)
            WHERE id = l_doc_id;

            -- 5. Обновляем детализацию ошибки в ou.logs по событию отправки счета
            UPDATE ou.logs
            SET changes = jsonb_build_object(
                'status', v_arv_rida.status,
                'reason', v_arv_rida.reason,
                'email', v_arv_rida.recipient_email,
                'cancelled_at', clock_timestamp()
            ) || coalesce(changes, '{}'::JSONB)
            WHERE doc_id = l_doc_id
              AND propertis ->> 'table' = 'arv'
              AND propertis ->> 'event' = 'email';

            -- Добавляем успешный результат в ответ
            l_response := l_response || jsonb_build_object(
                'doc_number', v_arv_rida.doc_number,
                'doc_id', l_doc_id,
                'recipient_email', v_arv_rida.recipient_email,
                'status', 'success'
            );
        ELSE
            -- Счет не найден
            l_response := l_response || jsonb_build_object(
                'doc_number', v_arv_rida.doc_number,
                'recipient_email', v_arv_rida.recipient_email,
                'status', 'error_not_found'
            );
        END IF;

    END LOOP;

    RETURN l_response;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.tuhista_arve_saatmise_staatus(INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION docs.tuhista_arve_saatmise_staatus(INTEGER) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION docs.tuhista_arve_saatmise_staatus(INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.tuhista_arve_saatmise_staatus(INTEGER) TO dbpeakasutaja;