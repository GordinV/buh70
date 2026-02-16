DROP FUNCTION IF EXISTS palk.get_work_days(JSON);

--tahtpaevad
CREATE OR REPLACE FUNCTION palk.get_work_days(IN params JSON)
    RETURNS INTEGER
    LANGUAGE plpgsql
    STABLE -- Функция зависит только от данных в таблицах, можно кэшировать в рамках транзакции
AS
$$
/*
 Функция возвращает количество рабочих дней в периоде.
 Логика:
 1. Если задан диапазон дат (alg_kpv, lopp_kpv) -> разбивает на месяцы и суммирует результат рекурсивно.
 2. Если задан месяц (period или kuu/aasta) -> проверяет наличие табеля (toograf).
 3. Если есть табель -> возвращает (часы / часы_в_день).
 4. Если табеля нет -> считает календарные рабочие дни (исключая выходные и праздники).
*/
DECLARE
    l_lepingid     INTEGER = params ->> 'lepingid';
    l_kuu          INTEGER = coalesce((params ->> 'kuu') :: INTEGER, EXTRACT(MONTH FROM current_date)::INTEGER);
    l_aasta        INTEGER = coalesce((params ->> 'aasta') :: INTEGER, EXTRACT(YEAR FROM current_date)::INTEGER);
    l_esimine_paev INTEGER = coalesce((params ->> 'paev') :: INTEGER, 1);
    l_lopp_paev    INTEGER = coalesce((params ->> 'lopp') :: INTEGER, 31);
    l_period       text    = params ->> 'period';
    l_rekvid       INTEGER = params ->> 'rekvid';
    l_alg_kpv      DATE    = params ->> 'alg_kpv';
    l_lopp_kpv     DATE    = params ->> 'lopp_kpv';

    -- Вычисляем последний день месяца стандартными средствами
    l_month_start  DATE    = make_date(l_aasta, l_kuu, 1);
    l_maxdays      INTEGER = EXTRACT(DAY FROM (l_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE)::INTEGER;

    l_holidays     INTEGER = 0;
    l_date         DATE;
    qrytoograf     RECORD;
    lnDow          INT;
    l_result       INTEGER = 0;
    v_periods      record; -- для цикла по месяцам
    l_paevad       integer = 0; -- накопитель дней

BEGIN

    -- 1. Обработка диапазона дат (рекурсивный вызов для каждого месяца)
    IF l_alg_kpv IS NOT NULL AND l_lopp_kpv IS NOT NULL THEN
        FOR v_periods IN
            WITH kpv AS (
                            SELECT generate_series(
                                           make_date(EXTRACT(YEAR FROM l_alg_kpv)::INTEGER, EXTRACT(MONTH FROM l_alg_kpv)::INTEGER, 1),
                                           l_lopp_kpv,
                                           INTERVAL '1 month'
                                   )::date AS kpv
                 )
            SELECT
                CASE WHEN l_alg_kpv > k.kpv THEN l_alg_kpv ELSE k.kpv END AS alg_kpv,
                CASE
                    WHEN (k.kpv + interval '1 month' - interval '1 day')::date > l_lopp_kpv
                        THEN l_lopp_kpv
                    ELSE (k.kpv + interval '1 month' - interval '1 day')::date
                    END AS lopp_kpv
            FROM kpv k
            LOOP
                l_paevad = l_paevad + palk.get_work_days(
                        jsonb_build_object(
                                'lepingid', l_lepingid,
                                'aasta', EXTRACT(YEAR FROM v_periods.alg_kpv)::INTEGER,
                                'kuu', EXTRACT(MONTH FROM v_periods.alg_kpv)::INTEGER,
                                'paev', EXTRACT(DAY FROM v_periods.alg_kpv)::INTEGER,
                                'lopp', EXTRACT(DAY FROM v_periods.lopp_kpv)::INTEGER,
                                'rekvid', l_rekvid
                        ):: JSON);
            END LOOP;
        RETURN l_paevad;
    END IF;


    -- 2. Парсинг периода, если передан строкой 'YYYY-MM'
    IF (l_period IS NOT NULL AND params ->> 'kuu' IS NULL) THEN
        l_aasta = left(l_period, 4)::integer;
        l_kuu = right(l_period, 2)::integer;
        -- Пересчитываем макс. дней для нового месяца
        l_month_start = make_date(l_aasta, l_kuu, 1);
        l_maxdays = EXTRACT(DAY FROM (l_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE)::INTEGER;
        l_lopp_paev = l_maxdays;
    END IF;

    -- Корректировка последнего дня расчета
    IF l_maxdays < l_lopp_paev THEN
        l_lopp_paev = l_maxdays;
    END IF;

    -- Инициализация даты начала перебора
    l_date = make_date(l_aasta, l_kuu, CASE WHEN l_esimine_paev > l_maxdays THEN l_maxdays ELSE l_esimine_paev END);


    -- 3. Проверка наличия табеля (Toograf)
    IF l_lepingid IS NOT NULL THEN
        IF EXISTS (
                      SELECT 1
                      FROM palk.toograf
                      WHERE lepingid = l_lepingid
                        AND kuu = l_kuu
                        AND aasta = l_aasta
                        AND status <> 'deleted'
                  ) THEN
            -- Если табель есть, считаем дни на основе часов
            SELECT p.*, t.toopaev
            INTO qrytoograf
            FROM palk.toograf p
                     INNER JOIN palk.tooleping t ON t.id = p.lepingid
            WHERE p.lepingid = l_lepingid
              AND p.kuu = l_kuu
              AND p.status <> 'deleted'
              AND p.aasta = l_aasta;

            IF (coalesce(qrytoograf.toopaev, 0) = 0) THEN
                l_result = 0;
            ELSE
                l_result = (coalesce(qrytoograf.tund, 0) / qrytoograf.toopaev);
            END IF;

            RETURN l_result;
        END IF;

    END IF;


    -- 4. Расчет по календарю (цикл по дням)
    FOR i IN l_esimine_paev..l_lopp_paev
        LOOP
            -- DOW: 0 - Воскресенье, 6 - Суббота
            lnDow := EXTRACT(DOW FROM l_date);

            IF lnDow = 6 OR lnDow = 0 THEN
                -- Выходной
                l_holidays := l_holidays + 1;
            ELSE
                -- Проверка на государственный праздник
                IF EXISTS (
                              SELECT 1
                              FROM cur_tahtpaevad l
                              WHERE l.paev = EXTRACT(DAY FROM l_date)::INTEGER
                                AND l.kuu = EXTRACT(MONTH FROM l_date)::INTEGER
                                AND l.aasta  = EXTRACT(YEAR FROM l_date)::INTEGER
                          ) THEN
                    l_holidays := l_holidays + 1;
                END IF;
            END IF;

            l_date := l_date + 1;
        END LOOP;

    -- Результат: Всего дней в диапазоне - Выходные/Праздники
    l_result = COALESCE((l_lopp_paev - l_esimine_paev + 1) - l_holidays, 0)::INTEGER;

    RETURN l_result;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.get_work_days(JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_work_days(JSON) TO dbpeakasutaja;

/*
SELECT * from palk.get_work_days('{"period":"2026-02"}' :: JSON);

SELECT palk.get_work_days(NULL :: JSON);

SELECT palk.get_work_days('{"kuu":1,"aasta":2021,"lepingid":30951}' :: JSON);


*/