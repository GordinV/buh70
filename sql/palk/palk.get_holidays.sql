DROP FUNCTION IF EXISTS palk.get_holidays(JSONB);

-- tahtpaevad
CREATE OR REPLACE FUNCTION palk.get_holidays(IN params JSONB, OUT result INTEGER)
    LANGUAGE plpgsql
    STABLE
AS
$$
DECLARE
    l_kpv_alg  DATE    = (params ->> 'alg_kpv')::DATE;
    l_kpv_lopp DATE    = (params ->> 'lopp_kpv')::DATE;
    l_aasta    INTEGER = (params ->> 'aasta')::INTEGER;
    l_kuu      INTEGER = (params ->> 'kuu')::INTEGER;
BEGIN
    -- 1. Определяем период, если он не передан
    IF l_kpv_alg IS NULL THEN
        -- Используем стандартный make_date вместо date()
        l_kpv_alg = make_date(l_aasta, l_kuu, 1);
    END IF;

    IF l_kpv_lopp IS NULL THEN
        -- Последний день месяца: (1-е число + 1 месяц) - 1 день
        l_kpv_lopp = (make_date(l_aasta, l_kuu, 1) + interval '1 month' - interval '1 day')::DATE;
    END IF;

    -- 3. Считаем количество праздничных дней
    -- Генерируем серию дат и проверяем каждую на наличие в календаре праздников

    SELECT
        count(*)
    INTO result
    FROM
        generate_series(l_kpv_alg, l_kpv_lopp, interval '1 day') AS d(kpv)
    WHERE
        EXISTS
        (
            SELECT
                1
            FROM
                cur_tahtpaevad t
            WHERE
                  t.paev = EXTRACT(DAY FROM d.kpv)::INTEGER
              AND t.kuu = EXTRACT(MONTH FROM d.kpv)::INTEGER
                  -- Важно: Праздник учитывается, если год не указан (ежегодный) или совпадает с годом проверяемой даты
              AND t.aasta = EXTRACT(YEAR FROM d.kpv)::INTEGER
        );

    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_holidays( JSONB ) TO dbvaatleja;
GRANT EXECUTE ON FUNCTION palk.get_holidays( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_holidays( JSONB ) TO dbpeakasutaja;


/*
-- Пример использования:
SELECT palk.get_holidays('{"kuu":1,"aasta":2026, "alg_kpv":"2026-01-01", "lopp_kpv":"2026-01-09"}' :: JSONB);
*/