DROP FUNCTION IF EXISTS is_workday(DATE, INTEGER);

--tahtpaevad
CREATE OR REPLACE FUNCTION is_workday(
    l_kpv DATE,
    l_rekv_id INTEGER DEFAULT 63 -- По умолчанию ID фин. департамента
)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
    STABLE -- Функция STABLE, так как читает данные из таблицы, но не меняет их (лучше для оптимизатора)
AS
$$
DECLARE
    l_target_rekv_id INTEGER = 63;
BEGIN

    -- 1. Проверка на выходные дни
    -- EXTRACT(ISODOW ...) возвращает 1 (Понедельник) - 7 (Воскресенье).
    -- Соответственно, 6 и 7 - это Суббота и Воскресенье.
    IF EXTRACT(ISODOW FROM l_kpv) IN (6, 7) THEN
        RETURN FALSE;
    END IF;

    -- 2. Проверка на государственные праздники
    -- Проверяем наличие записи в таблице праздников для целевого учреждения
    IF EXISTS
    (
        SELECT
            1
        FROM
            cur_tahtpaevad
        WHERE
              paev = EXTRACT(DAY FROM l_kpv)::INTEGER
          AND kuu = EXTRACT(MONTH FROM l_kpv)::INTEGER
              -- Важно: добавляем проверку года.
          AND aasta = EXTRACT(YEAR FROM l_kpv)::INTEGER
    )
    THEN
        RETURN FALSE;
    END IF;

    -- Если не выходной и не праздник, значит рабочий день
    RETURN TRUE;

END;
$$;

-- Примеры использования:
/*
select * from cur_tahtpaevad order by id desc limit 10

SELECT is_workday(current_date ) as is_working;
SELECT is_workday('2024-01-01', 63) as is_new_year_working; -- Должно вернуть false
*/