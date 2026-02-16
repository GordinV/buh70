DROP FUNCTION IF EXISTS get_week_ends(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_week_ends(INTEGER, INTEGER, INTEGER);

-- tahtapaevad
CREATE OR REPLACE FUNCTION get_week_ends(
    l_kuu INTEGER,
    l_aasta INTEGER,
    l_rekvid INTEGER DEFAULT NULL
)
    RETURNS INTEGER[]
    LANGUAGE plpgsql
    STABLE -- Функция детерминирована для одних и тех же данных в таблицах
AS
$$
DECLARE
    REKV_ID INTEGER = 63; -- только фин. департамент
BEGIN
    -- Возвращаем массив дней, используя один эффективный запрос вместо цикла
    RETURN (
               WITH
                   month_dates AS (
                                      -- 1. Генерируем список всех дат месяца
                                      SELECT
                                          generate_series(
                                                  make_date(l_aasta, l_kuu, 1),
                                              -- Вычисляем последний день месяца стандартным способом (1-е число + месяц - 1 день)
                                                  (make_date(l_aasta, l_kuu, 1) + interval '1 month' - interval '1 day')::date,
                                                  '1 day'::interval
                                          )::date AS kpv
                   )
               SELECT
                   -- Собираем номера дней в массив
                   array_agg(EXTRACT(DAY FROM kpv)::INTEGER ORDER BY kpv)
               FROM
                   month_dates
               WHERE
                 -- 2. Проверка на выходные (ISO: 6 = Суббота, 7 = Воскресенье)
                 EXTRACT(ISODOW FROM kpv) IN (6, 7)
                 OR
                 -- 3. Проверка на праздники
                 EXISTS
                 (
                     SELECT
                         1
                     FROM
                         cur_tahtpaevad t
                     WHERE
                           t.paev = EXTRACT(DAY FROM kpv)::INTEGER
                       AND t.kuu = EXTRACT(MONTH FROM kpv)::INTEGER
                           -- Важно: проверяем год. Праздник действует, если год не указан (0/NULL) или совпадает.
                       AND t.aasta = l_aasta
                 )
           );
END;
$$;

/*
-- Пример использования:
SELECT get_week_ends(1, 2026, 63); -- Вернет выходные и праздники января 2024
*/