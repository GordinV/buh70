DROP FUNCTION IF EXISTS docs.tuhista_arve_saatmise_staatus(INTEGER);

CREATE OR REPLACE FUNCTION docs.tuhista_arve_saatmise_staatus(l_log_id INTEGER)
    RETURNS jsonb AS
$BODY$
DECLARE
    v_arv_rida     RECORD;
    l_jsonb_arved  JSONB;
    l_rekv_id      INTEGER;
    l_doc_rekv_id  INTEGER;
    l_user_id      INTEGER;
    l_doc_id          INTEGER;
    l_doc_type        TEXT;
    l_recipient_email TEXT;
    l_response        JSONB = '[]'::JSONB; -- результат
    l_email        TEXT;
BEGIN
    -- 1. Считываем результат работы агента, учреждение и пользователя из ou.logs
    SELECT
        l.rekvid,
        l.user_id,
        l.propertis -> 'result'
    INTO
        l_rekv_id,
        l_user_id,
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
            l_doc_rekv_id := NULL;
            l_email := NULL;
            l_doc_type := upper(coalesce(nullif(trim(v_arv_rida.doc_type), ''), 'ARV'));
            l_recipient_email := nullif(lower(trim(coalesce(v_arv_rida.recipient_email, ''))), '');

            raise notice 'v_arv_rida.doc_number %, doc_type %, l_rekv_id %, v_arv_rida.recipient_email %',
                v_arv_rida.doc_number, l_doc_type, l_rekv_id, v_arv_rida.recipient_email;

            -- 3. Ранний пропуск пустого / 'N/A' номера документа без сканирования docs.arv/docs.teatis
            IF v_arv_rida.doc_number IS NOT NULL
               AND NOT empty(trim(v_arv_rida.doc_number))
               AND upper(trim(v_arv_rida.doc_number)) <> 'N/A' THEN

                -- Ищем документ: если тип не TEATIS, сначала ищем в docs.arv;
                -- если в docs.arv не найден (например, у извещения формат номера XXX-XXXX и в теме bounce нет слова teatis),
                -- выполняем fallback-поиск в docs.teatis
                IF l_doc_type <> 'TEATIS' THEN
                    -- 3.1 Точное или подстрочное совпадение реального адреса в history (e ? 'email') или ou.logs среди активных счетов
                    IF l_recipient_email IS NOT NULL AND l_recipient_email <> 'unknown@client.ee' THEN
                        SELECT
                            d.id,
                            d.rekvid,
                            (u.properties::jsonb ->> 'email')::TEXT AS email
                        INTO l_doc_id, l_doc_rekv_id, l_email
                        FROM
                            docs.arv                 a
                                INNER JOIN docs.doc  d ON d.id = a.parentid
                                LEFT JOIN ou.userid  u ON u.id = a.userid
                        WHERE
                              d.status <> 3
                          AND trim(a.number) = trim(v_arv_rida.doc_number)
                          AND (
                                  EXISTS (
                                      SELECT
                                          1
                                      FROM
                                          jsonb_array_elements(
                                              CASE
                                                  WHEN jsonb_typeof(d.history) = 'array' THEN d.history
                                                  ELSE '[]'::JSONB
                                              END
                                          ) AS e
                                      WHERE
                                            e ? 'email'
                                        AND (
                                                lower(trim(e ->> 'aadress')) = l_recipient_email
                                                OR position(l_recipient_email IN lower(coalesce(e ->> 'aadress', ''))) > 0
                                            )
                                  )
                                  OR EXISTS (
                                      SELECT
                                          1
                                      FROM
                                          ou.logs ol
                                      WHERE
                                            ol.doc_id = d.id
                                        AND ol.propertis ->> 'event' = 'email'
                                        AND position(l_recipient_email IN lower(coalesce(ol.propertis::text, ''))) > 0
                                  )
                              )
                        ORDER BY d.id DESC
                        LIMIT 1;
                    END IF;

                    -- 3.2 Fallback для docs.arv: если по номеру найден ровно один активный счет с фактом отправки
                    IF l_doc_id IS NULL THEN
                        WITH candidates AS (
                            SELECT
                                d.id,
                                d.rekvid,
                                (u.properties::jsonb ->> 'email')::TEXT AS email
                            FROM
                                docs.arv                 a
                                    INNER JOIN docs.doc  d ON d.id = a.parentid
                                    LEFT JOIN ou.userid  u ON u.id = a.userid
                            WHERE
                                  d.status <> 3
                              AND trim(a.number) = trim(v_arv_rida.doc_number)
                              AND (
                                      EXISTS (
                                          SELECT 1
                                          FROM jsonb_array_elements(
                                              CASE
                                                  WHEN jsonb_typeof(d.history) = 'array' THEN d.history
                                                  ELSE '[]'::JSONB
                                              END
                                          ) AS e
                                          WHERE e ? 'email'
                                      )
                                      OR EXISTS (
                                          SELECT 1
                                          FROM ou.logs ol
                                          WHERE ol.doc_id = d.id
                                            AND ol.propertis ->> 'event' = 'email'
                                      )
                                  )
                            ORDER BY d.id DESC
                            LIMIT 2
                        )
                        SELECT
                            c.id,
                            c.rekvid,
                            c.email
                        INTO l_doc_id, l_doc_rekv_id, l_email
                        FROM candidates c
                        WHERE (SELECT count(*) FROM candidates) = 1
                        LIMIT 1;
                    END IF;
                END IF;

                IF l_doc_type = 'TEATIS' OR l_doc_id IS NULL THEN
                    -- 3.3 Точное или подстрочное совпадение реального адреса в history или ou.logs для docs.teatis
                    IF l_recipient_email IS NOT NULL AND l_recipient_email <> 'unknown@client.ee' THEN
                        SELECT
                            d.id,
                            d.rekvid,
                            coalesce(
                                nullif(trim((u.properties::jsonb ->> 'email')::TEXT), ''),
                                nullif(trim(r.email::TEXT), '')
                            ) AS email
                        INTO l_doc_id, l_doc_rekv_id, l_email
                        FROM
                            docs.teatis              t
                                INNER JOIN docs.doc  d ON d.id = t.parentid
                                LEFT JOIN ou.rekv    r ON r.id = d.rekvid
                                LEFT JOIN ou.userid  u ON trim(u.kasutaja) = trim(
                                                              CASE
                                                                  WHEN jsonb_typeof(d.history) = 'array' THEN d.history -> 0 ->> 'user'
                                                                  WHEN jsonb_typeof(d.history) = 'object' THEN d.history ->> 'user'
                                                                  ELSE NULL
                                                              END
                                                          )
                                                      AND u.rekvid = d.rekvid
                                                      AND u.status <> 3
                        WHERE
                              d.status <> 3
                          AND trim(t.number) = trim(v_arv_rida.doc_number)
                          AND (
                                  EXISTS (
                                      SELECT
                                          1
                                      FROM
                                          jsonb_array_elements(
                                              CASE
                                                  WHEN jsonb_typeof(d.history) = 'array' THEN d.history
                                                  ELSE '[]'::JSONB
                                              END
                                          ) AS e
                                      WHERE
                                            e ? 'email'
                                        AND (
                                                lower(trim(e ->> 'aadress')) = l_recipient_email
                                                OR position(l_recipient_email IN lower(coalesce(e ->> 'aadress', ''))) > 0
                                            )
                                  )
                                  OR EXISTS (
                                      SELECT
                                          1
                                      FROM
                                          ou.logs ol
                                      WHERE
                                            ol.doc_id = d.id
                                        AND ol.propertis ->> 'event' = 'email'
                                        AND position(l_recipient_email IN lower(coalesce(ol.propertis::text, ''))) > 0
                                  )
                              )
                        ORDER BY d.id DESC
                        LIMIT 1;
                    END IF;

                    -- 3.4 Fallback для docs.teatis: если по номеру найден ровно один активный документ с фактом отправки
                    IF l_doc_id IS NULL THEN
                        WITH candidates AS (
                            SELECT
                                d.id,
                                d.rekvid,
                                coalesce(
                                    nullif(trim((u.properties::jsonb ->> 'email')::TEXT), ''),
                                    nullif(trim(r.email::TEXT), '')
                                ) AS email
                            FROM
                                docs.teatis              t
                                    INNER JOIN docs.doc  d ON d.id = t.parentid
                                    LEFT JOIN ou.rekv    r ON r.id = d.rekvid
                                    LEFT JOIN ou.userid  u ON trim(u.kasutaja) = trim(
                                                                  CASE
                                                                      WHEN jsonb_typeof(d.history) = 'array' THEN d.history -> 0 ->> 'user'
                                                                      WHEN jsonb_typeof(d.history) = 'object' THEN d.history ->> 'user'
                                                                      ELSE NULL
                                                                  END
                                                              )
                                                          AND u.rekvid = d.rekvid
                                                          AND u.status <> 3
                            WHERE
                                  d.status <> 3
                              AND trim(t.number) = trim(v_arv_rida.doc_number)
                              AND (
                                      EXISTS (
                                          SELECT 1
                                          FROM jsonb_array_elements(
                                              CASE
                                                  WHEN jsonb_typeof(d.history) = 'array' THEN d.history
                                                  ELSE '[]'::JSONB
                                              END
                                          ) AS e
                                          WHERE e ? 'email'
                                      )
                                      OR EXISTS (
                                          SELECT 1
                                          FROM ou.logs ol
                                          WHERE ol.doc_id = d.id
                                            AND ol.propertis ->> 'event' = 'email'
                                      )
                                  )
                            ORDER BY d.id DESC
                            LIMIT 2
                        )
                        SELECT
                            c.id,
                            c.rekvid,
                            c.email
                        INTO l_doc_id, l_doc_rekv_id, l_email
                        FROM candidates c
                        WHERE (SELECT count(*) FROM candidates) = 1
                        LIMIT 1;
                    END IF;

                    IF l_doc_id IS NOT NULL THEN
                        l_doc_type := 'TEATIS';
                    END IF;
                END IF;
            END IF;

            raise notice 'l_doc_id %, l_email %', l_doc_id, l_email;

            -- 4. Если документ найден, аннулируем статус успешной отправки
            IF l_doc_id IS NOT NULL THEN
                -- Обновляем историю в docs.doc: фиксируем email_error_3 с защитой от не-массивов JSONB и идемпотентностью
                UPDATE docs.doc
                SET
                    history = CASE
                        WHEN jsonb_typeof(history) = 'array' THEN
                            CASE
                                WHEN EXISTS (
                                    SELECT 1
                                    FROM jsonb_array_elements(history) WITH ORDINALITY AS h(e, ord)
                                    WHERE e ? 'email_error_3'
                                      AND coalesce(e ->> 'status', '') = coalesce(v_arv_rida.status, '')
                                      AND coalesce(e ->> 'info', '') = coalesce(v_arv_rida.reason, '')
                                      AND ord > coalesce(
                                          (
                                              SELECT max(h2.ord)
                                              FROM jsonb_array_elements(history) WITH ORDINALITY AS h2(e2, ord)
                                              WHERE h2.e2 ? 'email'
                                          ),
                                          0
                                      )
                                ) THEN history
                                ELSE history || jsonb_build_object(
                                    'email_error_3', now(),
                                    'info', v_arv_rida.reason,
                                    'status', v_arv_rida.status
                                )
                            END
                        WHEN jsonb_typeof(history) = 'object' THEN
                            jsonb_build_array(
                                history,
                                jsonb_build_object(
                                    'email_error_3', now(),
                                    'info', v_arv_rida.reason,
                                    'status', v_arv_rida.status
                                )
                            )
                        ELSE
                            jsonb_build_array(
                                jsonb_build_object(
                                    'email_error_3', now(),
                                    'info', v_arv_rida.reason,
                                    'status', v_arv_rida.status
                                )
                            )
                    END
                WHERE
                    id = l_doc_id;

                raise notice 'update l_doc_id %', l_doc_id;

                -- 5. Обновляем детализацию ошибки в ou.logs по событию отправки (arv или teatis);
                -- если строки отправки не было (например, старый роут), создаём её, чтобы колонка Saatmise staatus отображала ошибку
                UPDATE ou.logs
                SET
                    changes = (CASE WHEN jsonb_typeof(changes) = 'object' THEN changes ELSE '{}'::JSONB END)
                              || jsonb_build_object(
                                      'status', v_arv_rida.status,
                                      'reason', v_arv_rida.reason,
                                      'email', v_arv_rida.recipient_email,
                                      'subject', v_arv_rida.subject,
                                      'cancelled_at', clock_timestamp()
                                 )
                WHERE
                      doc_id = l_doc_id
                  AND propertis ->> 'table' = CASE WHEN l_doc_type = 'TEATIS' THEN 'teatis' ELSE 'arv' END
                  AND propertis ->> 'event' = 'email';

                IF NOT FOUND THEN
                    INSERT INTO ou.logs (rekvid, user_id, doc_id, timestamp, propertis, changes)
                    VALUES (
                        coalesce(l_doc_rekv_id, l_rekv_id),
                        coalesce(l_user_id, 11558),
                        l_doc_id,
                        now(),
                        jsonb_build_object(
                            'table', CASE WHEN l_doc_type = 'TEATIS' THEN 'teatis' ELSE 'arv' END,
                            'event', 'email'
                        ),
                        jsonb_build_object(
                            'status', v_arv_rida.status,
                            'reason', v_arv_rida.reason,
                            'email', v_arv_rida.recipient_email,
                            'subject', v_arv_rida.subject,
                            'cancelled_at', clock_timestamp()
                        )
                    );
                END IF;

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
