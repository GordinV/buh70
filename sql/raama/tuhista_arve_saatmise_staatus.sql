DROP FUNCTION IF EXISTS docs.tuhista_arve_saatmise_staatus(INTEGER);

CREATE OR REPLACE FUNCTION docs.tuhista_arve_saatmise_staatus(l_log_id INTEGER)
    RETURNS jsonb AS
$BODY$
DECLARE
    v_arv_rida    RECORD;
    l_jsonb_arved JSONB;
    l_rekv_id     INTEGER;
    l_doc_id      INTEGER;
    l_doc_type    TEXT;
    l_response    JSONB = '[]'::JSONB; -- результат
    l_email       TEXT;
BEGIN
    -- 1. Считываем результат работы агента и учреждение из ou.logs
    SELECT
        l.rekvid,
        l.propertis -> 'result'
    INTO
        l_rekv_id,
        l_jsonb_arved
    FROM
        ou.logs l
    WHERE
        l.id = l_log_id;

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
        FROM
            jsonb_to_recordset(l_jsonb_arved) AS x(
                                                   doc_number TEXT,
                                                   doc_type TEXT,
                                                   status TEXT,
                                                   reason TEXT,
                                                   recipient_email TEXT,
                                                   subject TEXT
                )
        LOOP

            l_doc_id := NULL;
            l_email := NULL;
            l_doc_type := upper(coalesce(nullif(trim(v_arv_rida.doc_type), ''), 'ARV'));

            raise notice 'v_arv_rida.doc_number %, doc_type %, l_rekv_id %, v_arv_rida.recipient_email %',
                v_arv_rida.doc_number, l_doc_type, l_rekv_id, v_arv_rida.recipient_email;

            -- 3. Ищем документ: если тип не TEATIS, сначала ищем в docs.arv;
            -- если в docs.arv не найден (например, у извещения формат номера XXX-XXXX и в теме bounce нет слова teatis),
            -- выполняем fallback-поиск в docs.teatis
            IF l_doc_type <> 'TEATIS' THEN
                -- Используем LEFT JOIN ou.userid, чтобы счет аннулировался даже если автор не найден или удален
                SELECT
                    d.id,
                    d.rekvid,
                    (u.properties::jsonb ->> 'email')::TEXT AS email
                INTO l_doc_id, l_rekv_id, l_email
                FROM
                    docs.arv                 a
                        INNER JOIN docs.doc  d ON d.id = a.parentid
                        LEFT JOIN ou.userid  u ON u.id = a.userid
                WHERE
                      trim(a.number) = trim(v_arv_rida.doc_number)
                  AND EXISTS
                      (
                          SELECT
                              1
                          FROM
                              jsonb_array_elements(coalesce(d.history, '[]'::JSONB)) AS e
                          WHERE
                                e ? 'email'
                            AND (
                                    v_arv_rida.recipient_email IS NULL
                                        OR empty(v_arv_rida.recipient_email)
                                        OR lower(trim(e ->> 'aadress')) = lower(trim(v_arv_rida.recipient_email))
                                    )
                      )
                ORDER BY d.id DESC
                LIMIT 1;
            END IF;

            IF l_doc_type = 'TEATIS' OR l_doc_id IS NULL THEN
                SELECT
                    d.id,
                    d.rekvid,
                    coalesce(
                        nullif(trim((u.properties::jsonb ->> 'email')::TEXT), ''),
                        nullif(trim(r.email::TEXT), '')
                    ) AS email
                INTO l_doc_id, l_rekv_id, l_email
                FROM
                    docs.teatis              t
                        INNER JOIN docs.doc  d ON d.id = t.parentid
                        LEFT JOIN ou.rekv    r ON r.id = d.rekvid
                        LEFT JOIN ou.userid  u ON u.kasutaja = (d.history -> 0 ->> 'user')
                                              AND u.rekvid = d.rekvid
                                              AND u.status <> 3
                WHERE
                      d.status <> 3
                  AND trim(t.number) = trim(v_arv_rida.doc_number)
                  AND EXISTS
                      (
                          SELECT
                              1
                          FROM
                              jsonb_array_elements(coalesce(d.history, '[]'::JSONB)) AS e
                          WHERE
                                e ? 'email'
                            AND (
                                    v_arv_rida.recipient_email IS NULL
                                        OR empty(v_arv_rida.recipient_email)
                                        OR lower(trim(e ->> 'aadress')) = lower(trim(v_arv_rida.recipient_email))
                                    )
                      )
                ORDER BY d.id DESC
                LIMIT 1;

                IF l_doc_id IS NOT NULL THEN
                    l_doc_type := 'TEATIS';
                END IF;
            END IF;

            raise notice 'l_doc_id %, l_email %', l_doc_id, l_email;

            -- 4. Если документ найден, аннулируем статус успешной отправки
            IF l_doc_id IS NOT NULL THEN
                -- Обновляем историю в docs.doc: фиксируем email_error_3 с сохранением статуса и причины
                UPDATE docs.doc
                SET
                    history = coalesce(history, '[]'::JSONB) || jsonb_build_object(
                            'email_error_3', now(),
                            'info', v_arv_rida.reason,
                            'status', v_arv_rida.status
                        )
                WHERE
                    id = l_doc_id;

                raise notice 'update l_doc_id %', l_doc_id;

                -- 5. Обновляем детализацию ошибки в ou.logs по событию отправки (arv или teatis)
                UPDATE ou.logs
                SET
                    changes = jsonb_build_object(
                                      'status', v_arv_rida.status,
                                      'reason', v_arv_rida.reason,
                                      'email', v_arv_rida.recipient_email,
                                      'subject', v_arv_rida.subject,
                                      'cancelled_at', clock_timestamp()
                              ) || coalesce(changes, '{}'::JSONB)
                WHERE
                      doc_id = l_doc_id
                  AND propertis ->> 'table' = CASE WHEN l_doc_type = 'TEATIS' THEN 'teatis' ELSE 'arv' END
                  AND propertis ->> 'event' = 'email';

                raise notice 'update ou.logs l_log_id %', l_log_id;

                -- Добавляем успешный результат в ответ
                l_response := l_response || jsonb_build_object(
                        'doc_type', l_doc_type,
                        'doc_number', v_arv_rida.doc_number,
                        'doc_id', l_doc_id,
                        'recipient_email', v_arv_rida.recipient_email,
                        'status', 'success',
                        'email', l_email,
                        'subject', v_arv_rida.subject);
            ELSE
                -- Документ не найден
                l_response := l_response || jsonb_build_object(
                        'doc_type', l_doc_type,
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
