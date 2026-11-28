DROP FUNCTION IF EXISTS ou.execute_task(JSONB);

CREATE OR REPLACE FUNCTION ou.execute_task(params JSONB)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_count          integer = 0;
    v_task           record;
    l_task_id        integer; -- task id for result
    l_only_task_id   integer = (params ->> 'doc_id')::integer;
    l_start          timestamp;
    l_finish         timestamp;
    l_exec_time      interval;
    l_tulemused      record;
    l_res_json       jsonb;
    l_keys           text[];
    l_has_error_code boolean;
    l_error_code     integer;
    l_has_result     boolean;
    l_result_val     integer;
    l_error_message  text;
    l_has_errors     boolean;
    l_errors         jsonb;
    l_errors_count   integer;
    l_errors_text    text;
    l_has_imported   boolean;
    l_imported       jsonb;
    l_imported_count integer;
    l_status         integer;
    l_tulemused_text text;
    l_extra_props    jsonb;
BEGIN
    for v_task in (
                      select *
                      from
                          ou.task t
                      where
                           (status = 0
                               and l_only_task_id is null)
                        or (t.id = l_only_task_id)
                  )
        loop
            l_task_id = v_task.id;

            -- Подтранзакция на каждую задачу: ошибка одной задачи не откатывает уже выполненные задачи пачки
            BEGIN
            l_start = clock_timestamp();

            EXECUTE v_task.sql into l_tulemused;
            l_finish = clock_timestamp();
            l_exec_time = l_finish - l_start;

            -- Разворачиваем результат: если у to_jsonb(l_tulemused) один ключ и его значение — объект,
            -- анализируем вложенный объект (случай 'select f(...)'), иначе анализируем как есть ('select * from f(...)').
            l_res_json = coalesce(to_jsonb(l_tulemused), '{}'::jsonb);
            SELECT array_agg(k) INTO l_keys FROM jsonb_object_keys(l_res_json) AS k;
            IF array_length(l_keys, 1) = 1
                AND jsonb_typeof(l_res_json -> l_keys[1]) = 'object'
            THEN
                l_res_json = l_res_json -> l_keys[1];
            END IF;

            l_has_error_code = (l_res_json ? 'error_code')
                AND jsonb_typeof(l_res_json -> 'error_code') = 'number';
            l_error_code = CASE
                WHEN l_has_error_code THEN (l_res_json ->> 'error_code')::numeric::integer
                ELSE NULL
            END;

            l_has_result = (l_res_json ? 'result')
                AND jsonb_typeof(l_res_json -> 'result') = 'number';
            l_result_val = CASE
                WHEN l_has_result THEN (l_res_json ->> 'result')::numeric::integer
                ELSE NULL
            END;

            l_error_message = nullif(btrim(coalesce(l_res_json ->> 'error_message', '')), '');

            l_has_errors = (l_res_json ? 'errors')
                AND jsonb_typeof(l_res_json -> 'errors') = 'array';
            l_errors = CASE
                WHEN l_has_errors THEN l_res_json -> 'errors'
                ELSE NULL
            END;
            l_errors_count = CASE
                WHEN l_has_errors THEN jsonb_array_length(l_errors)
                ELSE 0
            END;

            l_has_imported = (l_res_json ? 'imported')
                AND jsonb_typeof(l_res_json -> 'imported') = 'array';
            l_imported = CASE
                WHEN l_has_imported THEN l_res_json -> 'imported'
                ELSE NULL
            END;
            l_imported_count = CASE
                WHEN l_has_imported THEN jsonb_array_length(l_imported)
                ELSE NULL
            END;

            l_errors_text = NULL;
            IF l_errors_count > 0 THEN
                SELECT string_agg(
                    coalesce(nullif(btrim(elem ->> 'number'), ''), 'batch') || ': ' || coalesce(elem ->> 'error', 'Viga'),
                    '; '
                )
                INTO l_errors_text
                FROM jsonb_array_elements(l_errors) AS elem;
            END IF;

            -- Аддитивные правила определения статуса и tulemused
            IF coalesce(l_error_code, 0) > 0 THEN
                l_status = 2;
                IF l_errors_count > 0 AND l_errors_text IS NOT NULL THEN
                    l_tulemused_text = coalesce(l_error_message || ': ', '') || l_errors_text;
                ELSE
                    l_tulemused_text = coalesce(l_error_message, 'Viga (error_code ' || l_error_code::text || ')');
                END IF;
            ELSIF l_has_errors THEN
                IF l_errors_count > 0 AND coalesce(l_imported_count, 0) = 0 THEN
                    l_status = 2;
                    l_tulemused_text = 'Imporditud 0 arvet, vigu ' || l_errors_count::text
                        || CASE WHEN l_errors_text IS NOT NULL THEN ': ' || l_errors_text ELSE '' END;
                ELSIF l_errors_count > 0 AND coalesce(l_imported_count, 0) > 0 THEN
                    l_status = 1;
                    l_tulemused_text = 'Imporditud ' || l_imported_count::text || ' arvet, vigu ' || l_errors_count::text
                        || CASE WHEN l_errors_text IS NOT NULL THEN ': ' || l_errors_text ELSE '' END;
                ELSE
                    -- Ошибок нет (в т.ч. если все счета уже были импортированы ранее) -> Edukalt, tulemused (viga) пуст
                    l_status = 1;
                    l_tulemused_text = NULL;
                END IF;
            ELSIF l_has_result AND l_result_val = 0 AND l_error_message IS NOT NULL THEN
                l_status = 2;
                l_tulemused_text = l_error_message;
            ELSE
                l_status = 1;
                l_tulemused_text = l_error_message;
            END IF;

            IF l_tulemused_text IS NOT NULL AND length(l_tulemused_text) > 2000 THEN
                l_tulemused_text = left(l_tulemused_text, 2000);
            END IF;

            l_extra_props = jsonb_build_object('execute_time', l_exec_time);
            IF l_has_error_code THEN
                l_extra_props = l_extra_props || jsonb_build_object('error_code', l_error_code);
            END IF;
            IF l_has_imported THEN
                l_extra_props = l_extra_props || jsonb_build_object(
                    'imported_count', l_imported_count,
                    'imported', l_imported
                );
            END IF;
            IF l_has_errors THEN
                l_extra_props = l_extra_props || jsonb_build_object('errors', l_errors);
            END IF;

            update ou.task
            set
                status     = l_status,
                finished   = l_finish,
                tulemused  = l_tulemused_text,
                properties = coalesce(properties, '{}'::jsonb) || l_extra_props
            where
                id = l_task_id;

            l_count = l_count + 1;

            EXCEPTION
                WHEN OTHERS THEN
                    -- работа упавшей задачи откатана; отмечаем ошибку и переходим к следующей задаче
                    update ou.task
                    set
                        status    = 2,
                        finished  = clock_timestamp(),
                        tulemused = left(coalesce(SQLERRM, '') || ',' || coalesce(SQLSTATE, ''), 2000)
                    where
                        id = l_task_id;
            END;
        end loop;

    return l_count;
EXCEPTION
    -- ошибки вне выполнения задач (например, при выборке задач); ошибки самих задач ловятся в цикле
    WHEN OTHERS
        THEN
--            RAISE 'error % %', SQLERRM, SQLSTATE;
            update ou.task
            set
                status    = 2,
                finished  = clock_timestamp(),
                tulemused = left(coalesce(SQLERRM, '') || ',' || coalesce(SQLSTATE, ''), 2000)
            where
                id = l_task_id;

            RETURN 0;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.execute_task(JSONB) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.execute_task(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.execute_task(JSONB) TO dbpeakasutaja;

--select ou.execute_task(null::JSONB);

/*
-- SQL-сценарии для проверки на тестовой БД:
-- 1. Нет прав (error_code=4): status=2, tulemused содержит 'Puudub õigused', properties.error_code=4
-- 2. Все счета с ошибкой (errors!=[], imported=[]): status=2, tulemused='Imporditud 0 arvet, vigu N: ...', properties.imported_count=0, properties.errors=[...]
-- 3. Частичный успех (errors!=[], imported!=[]): status=1, tulemused='Imporditud M arvet, vigu N: ...', properties.imported_count=M, properties.errors=[...]
-- 4. Всё успешно (errors=[], imported!=[]): status=1, tulemused IS NULL, properties.imported_count=M, properties.errors=[]
-- 5. Исключение (например SELECT 1/0): status=2, finished IS NOT NULL, tulemused содержит SQLERRM
-- 6. Посторонняя задача без error_code/result/errors (например SELECT docs.refresh_kaibed_public()): status=1, tulemused IS NULL
-- 7. Пачка (doc_id = null) из трех задач status=0, вторая SELECT 1/0: первая и третья status=1, вторая status=2 с SQLERRM;
--    результат функции = 2 (число успешно обработанных задач)
*/
