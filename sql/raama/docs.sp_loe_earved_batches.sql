DROP FUNCTION IF EXISTS docs.sp_loe_earved_batches(JSONB);

-- Выполняет импорт батчей e-счетов FinBit за один SQL-вызов (для ou.task / ou.execute_task).
-- Вход: l_batches — jsonb-массив вида [{"user_id": 2477, "data": [...]}, ...]
-- Выход: одна строка с агрегированными колонками верхнего уровня:
--   result        — общее число реально импортированных счетов
--   error_code    — > 0 только если ВСЕ батчи отказали целиком (нет прав, пустой массив, исключение)
--   error_message — человекочитаемое резюме 'Imporditud M arvet, vigu N'
--   imported      — объединенный массив [{doc_id, number, rekv_id}, ...]
--   errors        — объединенный массив ошибок по счетам и отказавшим батчам
CREATE OR REPLACE FUNCTION docs.sp_loe_earved_batches(
    IN l_batches JSONB,
    OUT result INTEGER,
    OUT error_code INTEGER,
    OUT error_message TEXT,
    OUT imported JSONB,
    OUT errors JSONB
)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_batch           JSONB;
    v_res             RECORD;
    l_batch_user_id   INTEGER;
    l_batch_data      JSONB;
    l_total_batches   INTEGER = 0;
    l_failed_batches  INTEGER = 0;
    l_last_error_code INTEGER = 0;
    l_errors_count    INTEGER = 0;
BEGIN
    result = 0;
    error_code = 0;
    error_message = 'Imporditud 0 arvet, vigu 0';
    imported = '[]'::jsonb;
    errors = '[]'::jsonb;

    IF l_batches IS NULL
        OR jsonb_typeof(l_batches) <> 'array'
        OR jsonb_array_length(l_batches) = 0
    THEN
        RETURN;
    END IF;

    FOR v_batch IN
        SELECT elem
        FROM jsonb_array_elements(l_batches) AS elem
    LOOP
        l_total_batches = l_total_batches + 1;
        l_batch_user_id = NULL;
        l_batch_data = NULL;

        BEGIN
            l_batch_user_id = (v_batch ->> 'user_id')::INTEGER;
            l_batch_data = v_batch -> 'data';

            IF l_batch_user_id IS NULL THEN
                l_failed_batches = l_failed_batches + 1;
                l_last_error_code = coalesce(nullif(l_last_error_code, 0), 4);
                errors = errors || jsonb_build_array(
                    jsonb_build_object(
                        'number', NULL,
                        'user_id', NULL,
                        'error', 'Puudub user_id'
                    )
                );
                CONTINUE;
            END IF;

            SELECT *
            INTO v_res
            FROM docs.sp_loe_earved(l_batch_user_id, l_batch_data);

            IF coalesce(v_res.error_code, 0) > 0 THEN
                -- Отказ батча целиком (например, нет прав: error_code = 4)
                l_failed_batches = l_failed_batches + 1;
                l_last_error_code = v_res.error_code;
                errors = errors || jsonb_build_array(
                    jsonb_build_object(
                        'number', NULL,
                        'user_id', l_batch_user_id,
                        'error', coalesce(v_res.error_message, 'Viga (error_code ' || v_res.error_code::TEXT || ')')
                    )
                );
            ELSIF l_batch_data IS NULL
                OR jsonb_typeof(l_batch_data) <> 'array'
                OR jsonb_array_length(l_batch_data) = 0
                OR (coalesce(v_res.result, 0) = 0
                    AND coalesce(v_res.error_message, '') = 'Arved ei ole')
            THEN
                -- Пустой массив счетов в батче трактуем как отказ батча
                l_failed_batches = l_failed_batches + 1;
                l_last_error_code = coalesce(nullif(l_last_error_code, 0), 1);
                errors = errors || jsonb_build_array(
                    jsonb_build_object(
                        'number', NULL,
                        'user_id', l_batch_user_id,
                        'error', coalesce(nullif(v_res.error_message, ''), 'Arved ei ole')
                    )
                );
            ELSE
                IF v_res.imported IS NOT NULL AND jsonb_typeof(v_res.imported) = 'array' THEN
                    imported = imported || v_res.imported;
                END IF;
                IF v_res.errors IS NOT NULL AND jsonb_typeof(v_res.errors) = 'array' THEN
                    errors = errors || v_res.errors;
                END IF;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_failed_batches = l_failed_batches + 1;
                l_last_error_code = coalesce(nullif(l_last_error_code, 0), 1);
                errors = errors || jsonb_build_array(
                    jsonb_build_object(
                        'number', NULL,
                        'user_id', l_batch_user_id,
                        'error', coalesce(SQLERRM, SQLSTATE)
                    )
                );
        END;
    END LOOP;

    result = jsonb_array_length(imported);
    l_errors_count = jsonb_array_length(errors);
    error_message = 'Imporditud ' || result::TEXT || ' arvet, vigu ' || l_errors_count::TEXT;

    IF l_total_batches > 0 AND l_failed_batches = l_total_batches THEN
        error_code = coalesce(nullif(l_last_error_code, 0), 1);
    ELSE
        error_code = 0;
    END IF;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_loe_earved_batches(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_earved_batches(JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_loe_earved_batches(JSONB) TO dbadmin;

COMMENT ON FUNCTION docs.sp_loe_earved_batches(JSONB) IS 'Выполняет docs.sp_loe_earved по массиву батчей [{user_id, data}] и возвращает агрегированный результат';

/*
-- SQL-сценарии для проверки на тестовой БД (после выкатки docs.sp_loe_earved с OUT imported/errors):

-- 1. Пустой массив батчей: result=0, error_code=0, imported=[], errors=[], error_message='Imporditud 0 arvet, vigu 0'
SELECT * FROM docs.sp_loe_earved_batches('[]'::jsonb);

-- 2. Все батчи с ошибкой (нет прав у несуществующего пользователя -1): error_code=4, result=0, errors=[{number:null,user_id:-1,error:'Puudub õigused'}]
SELECT * FROM docs.sp_loe_earved_batches('[{"user_id": -1, "data": [{"id": 0, "data": {"number": "TEST-1"}}]}]'::jsonb);

-- 3. Один батч без прав + один валидный батч: error_code=0, errors содержит отказ первого батча, imported содержит счета второго
-- SELECT * FROM docs.sp_loe_earved_batches('[{"user_id": -1, "data": [{"id": 0, "data": {"number": "BAD"}}]}, {"user_id": <valid_user_id>, "data": [<valid_invoice>]}]'::jsonb);

-- 4. Два валидных батча: error_code=0, result=M, imported объединяет оба батча, errors=[]
-- SELECT * FROM docs.sp_loe_earved_batches('[{"user_id": <u1>, "data": [<inv1>]}, {"user_id": <u2>, "data": [<inv2>]}]'::jsonb);
*/
