DROP FUNCTION IF EXISTS palk.sp_calc_taabel2(JSONB);
--tahtpaevad
CREATE OR REPLACE FUNCTION palk.sp_calc_taabel2(
    IN params JSONB,
    OUT result NUMERIC,
    OUT tahtpaeva_tunnid NUMERIC
)
    LANGUAGE plpgsql
AS
$$
/*
 Функция расчета табеля (часов) за месяц.
 Логика:
 1. Определяем период (начало/конец месяца или контракта).
 2. Считаем отсутствия (отпуск, болезнь, прочее).
 3. Если есть график (palk.Toograf) -> берем часы оттуда и вычитаем отсутствия.
 4. Если графика нет -> считаем по норме (календарные рабочие дни) минус праздники и отсутствия.
*/
DECLARE
    l_lepingid         INTEGER        = (params ->> 'lepingid')::INTEGER;
    l_kuu              INTEGER        = (params ->> 'kuu')::INTEGER;
    l_aasta            INTEGER        = (params ->> 'aasta')::INTEGER;
    l_toograf          INTEGER        = (params ->> 'toograf')::INTEGER;
    l_alg_paev         INTEGER        = coalesce((params ->> 'alg_paev')::INTEGER, 1);
    l_lopp_paev        INTEGER        = (params ->> 'lopp_paev')::INTEGER;
    l_hours            NUMERIC(18, 4) = 0;
    v_tooleping        RECORD;
    l_puhkus           NUMERIC(16, 8) = 0;
    l_haigus           NUMERIC(16, 8) = 0;
    l_muud             NUMERIC(16, 8) = 0;
    l_tunnid           NUMERIC        = 0;
    l_toopaevad        INT            = 0;
    l_maxdays          INTEGER;
    l_kpv              DATE;
    l_params           JSONB;
    l_tahtpaeva_tunnid NUMERIC(12, 4) = 0;
    l_month_start      DATE;
    l_month_end        DATE;
BEGIN

    -- 1. Определение дат периода
    l_month_start = make_date(l_aasta, l_kuu, 1);
    -- Последний день месяца стандартным способом
    l_month_end = (l_month_start + interval '1 month' - interval '1 day')::DATE;
    l_maxdays = EXTRACT(DAY FROM l_month_end)::INTEGER;

    IF l_lopp_paev IS NULL THEN
        l_lopp_paev = l_maxdays;
    END IF;

    -- Опорная дата (конец периода)
    l_kpv = make_date(l_aasta, l_kuu, l_lopp_paev);

    -- Получаем данные договора
    SELECT *
    INTO v_tooleping
    FROM
        palk.tooleping t
    WHERE
        t.id = l_lepingid;

    -- 2. Корректировка начала и конца периода по датам контракта
    -- Если контракт начался в этом месяце
    IF l_alg_paev IS NULL OR l_alg_paev = 1 THEN
        IF EXTRACT(MONTH FROM v_tooleping.algab) = l_kuu AND EXTRACT(YEAR FROM v_tooleping.algab) = l_aasta THEN
            l_alg_paev = EXTRACT(DAY FROM v_tooleping.algab)::INTEGER;
        END IF;
    END IF;

    -- Если контракт закончился в этом месяце
    IF v_tooleping.lopp IS NOT NULL AND
       EXTRACT(MONTH FROM v_tooleping.lopp) = l_kuu AND
       EXTRACT(YEAR FROM v_tooleping.lopp) = l_aasta THEN
        l_lopp_paev = EXTRACT(DAY FROM v_tooleping.lopp)::INTEGER;
    END IF;

    -- 3. Расчет отсутствий (Отпуск)
    l_params = jsonb_build_object(
            'kuu', l_kuu,
            'aasta', l_aasta,
            'kpv', l_kpv,
            'lepingid', l_lepingid,
            'alg_paev', l_alg_paev,
            'lopp_paev', l_lopp_paev,
            'taabel', TRUE,
            'pohjus', 'PUHKUS'
               );
    l_puhkus = palk.get_puudumine(l_params);

    -- Расчет отсутствий (Болезнь)
    l_params = jsonb_build_object(
            'kuu', l_kuu,
            'aasta', l_aasta,
            'kpv', l_kpv,
            'lepingid', l_lepingid,
            'pohjus', 'HAIGUS'
               );
    l_haigus = palk.get_puudumine(l_params);

    -- Расчет отсутствий (Прочее)
    l_params = jsonb_build_object(
            'kuu', l_kuu,
            'aasta', l_aasta,
            'kpv', l_kpv,
            'lepingid', l_lepingid,
            'pohjus', 'MUU'
               );
    l_muud = palk.get_puudumine(l_params);

    -- 4. Специфическая логика выделения часов из "прочих" отсутствий
    -- (дробная часть l_muud используется как часы? Сохранено как есть)
    l_tunnid = (l_muud - floor(l_muud)) * 10 ^ (position('.' IN l_muud::TEXT) - 1);
    l_muud = floor(l_muud);

    IF l_tunnid > 0 THEN
        l_muud = 0;
    END IF;

    -- 5. Проверка наличия индивидуального графика (palk.Toograf)
    SELECT
        t.tund
    INTO l_hours
    FROM
        palk.Toograf t
    WHERE
          t.lepingid = l_lepingid
      AND status <> 'deleted'
      AND t.kuu = l_kuu
      AND t.aasta = l_aasta;

    -- ВЕТКА А: Есть часы в графике
    IF coalesce(l_toograf, 0) = 0 AND coalesce(l_hours, 0) > 0 THEN

        -- Формула: Часы по графику - (Дни отсутствия * Часы в день по договору) - Спец. часы
        l_hours = (l_hours - (coalesce(l_puhkus, 0) + coalesce(l_haigus, 0) + l_muud) * v_tooleping.toopaev -
                   l_tunnid);

    ELSE
        -- ВЕТКА Б: Графика нет, считаем по норме рабочего времени

        -- Параметры для расчета рабочих дней
        l_params = jsonb_build_object(
                'kuu', l_kuu,
                'aasta', l_aasta,
                'kpv', l_kpv,
                'lepingid', NULL,
                'paev', l_alg_paev,
                'lopp', l_lopp_paev
                   );

        -- 6. Расчет сокращения рабочего времени в предпраздничные дни
        -- Ищем праздники с флагом luhipaev=1, попадающие в период
        l_tahtpaeva_tunnid = (
                                 SELECT
                                     count(id)
                                 FROM
                                     cur_tahtpaevad l
                                 WHERE
                                       l.luhipaev = 1
                                       -- Учитываем ежегодные праздники (aasta=0/null) или конкретного года
                                   AND (l.aasta IS NULL OR l.aasta = 0 OR l.aasta = l_aasta)
                                       -- Формируем дату праздника в текущем году расчета
                                   AND make_date(l_aasta, l.kuu, l.paev) > make_date(l_aasta, l_kuu, l_alg_paev)
                                   AND make_date(l_aasta, l.kuu, l.paev) <= (make_date(l_aasta, l_kuu, l_lopp_paev) + 1)
                                       -- Исключаем праздники, которые выпадают на период отсутствия работника
                                   AND make_date(l_aasta, l.kuu, l.paev) - 1 NOT IN (
                                                                                        SELECT
                                                                                            unnest(get_days_between_dates(kpv1, kpv2))
                                                                                        FROM
                                                                                            palk.puudumine p
                                                                                        WHERE
                                                                                              lepingid = v_tooleping.id
                                                                                          AND p.kpv1 >= make_date(l_aasta, l_kuu, l_alg_paev)
                                                                                          AND p.kpv2 <= make_date(l_aasta, l_kuu, l_lopp_paev)
                                                                                    )
                             ) * 3;
        -- 3 часа сокращения за каждый праздник

        -- Получаем количество рабочих дней по календарю
        l_toopaevad = (
                          SELECT palk.get_work_days(l_params::json)
                      );

        -- Базовый расчет: (Рабочие дни * Часы в день) - Сокращения праздников
        l_hours = l_toopaevad * v_tooleping.toopaev - l_tahtpaeva_tunnid;

        IF l_hours < 0 THEN
            l_hours = 0;
        END IF;

        -- Если не задан спец. режим графика (l_toograf=0), вычитаем отсутствия
        IF coalesce(l_toograf, 0) = 0 THEN
            l_hours = (l_toopaevad - (coalesce(l_puhkus, 0) + coalesce(l_haigus, 0) + l_muud)) * v_tooleping.toopaev -
                      l_tunnid;

            l_hours := l_hours - l_tahtpaeva_tunnid;
        END IF;

    END IF;

    result = coalesce(l_hours, 0);
    tahtpaeva_tunnid = coalesce(l_tahtpaeva_tunnid, 0);
    RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION palk.sp_calc_taabel2(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.sp_calc_taabel2(JSONB) TO dbpeakasutaja;