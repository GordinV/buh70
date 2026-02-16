DROP FUNCTION IF EXISTS palk.arvuta_keskpalga_period(JSONB);

CREATE OR REPLACE FUNCTION palk.arvuta_keskpalga_period(
    IN params JSONB,
    OUT alg_kpv DATE,
    OUT lopp_kpv DATE,
    OUT vm_kpv DATE,
    OUT kokkuleppe_summa NUMERIC
)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_kpv_input     DATE    := (params ->> 'alg_kpv')::DATE; -- Явное приведение
    l_puudumine_id  INTEGER := (params ->> 'puudumise_id')::INTEGER;
    l_kpv_alg       DATE;
    v_leping        RECORD;
    l_period        INTEGER := 6; -- Стандартный период расчета (6 мес)
    l_months_worked INTEGER;
    l_palk_kontod   TEXT[]; -- Кэшируем счета зарплаты
BEGIN
    -- 1. Определяем дату выплаты (vm_kpv)
    -- Используем jsonb_build_object для передачи параметров во вложенную функцию
    vm_kpv := palk.arvuta_puhkuse_vm_paev(jsonb_build_object('alg_kpv', l_kpv_input, 'puudumise_id', l_puudumine_id));

    -- 2. Корректировка периода в зависимости от даты выплаты
    -- Если выплата приходится на месяц раньше (например, отпуск с 1 числа, выплата в пред. месяце), сдвигаем базу
    IF get_last_day(vm_kpv) = get_last_day((l_kpv_input - INTERVAL '1 month')::DATE) THEN
        l_kpv_input := (l_kpv_input - INTERVAL '1 month')::DATE;
    END IF;

    -- Конец периода - последний день предыдущего месяца
    lopp_kpv := get_last_day((l_kpv_input - INTERVAL '1 month')::DATE);

    -- По умолчанию начало периода - 5 месяцев назад от конца (итого 6 месяцев: текущий - 1 + 5 назад)
    l_kpv_alg := lopp_kpv - INTERVAL '5 month';
    -- Приводим к 1 числу месяца
    alg_kpv := make_date(EXTRACT(YEAR FROM l_kpv_alg)::INT, EXTRACT(MONTH FROM l_kpv_alg)::INT, 1);

    -- 3. Получаем данные договора
    SELECT
        tl.algab,
        tl.lopp,
        tl.palk, -- Сразу берем оклад для fallback логики
        pt.vs_kooded
    INTO v_leping
    FROM
        palk.tooleping                          tl
            INNER JOIN palk.puudumine           p ON p.lepingid = tl.id
            LEFT JOIN  palk.com_puudumiste_tyyp pt ON pt.liik = p.puudumiste_liik AND pt.id = p.tyyp
    WHERE
        p.id = l_puudumine_id;

    -- 4. Проверка на короткий стаж (< 6 месяцев)
    -- Вычисляем стаж в полных месяцах на момент расчета
    l_months_worked := (EXTRACT(YEAR FROM age(l_kpv_input, v_leping.algab)) * 12 +
                        EXTRACT(MONTH FROM age(l_kpv_input, v_leping.algab)))::INTEGER;

    IF l_months_worked < l_period THEN
        -- Если работаем меньше 6 месяцев, началом периода считается дата начала договора
        alg_kpv := v_leping.algab;
        l_period := l_months_worked; -- Обновляем период для информации (если понадобится)
    END IF;

    -- 5. Расчет суммы (kokkuleppe_summa)
    -- Сначала получаем список счетов, чтобы не джойнить таблицу настроек к операциям
    SELECT
        pohi_palk_kontod
    INTO l_palk_kontod
    FROM
        palk.palk_kulu_kontod
    LIMIT 1;

    -- Считаем сумму операций за релевантный период
    -- Логика: ищем выплаты в месяце, предшествующем началу отсутствия (puudumine)
    SELECT
        SUM(po.summa)
    INTO kokkuleppe_summa
    FROM
        palk.palk_oper                po
            INNER JOIN palk.puudumine p ON po.lepingid = p.lepingid
    WHERE
          p.id = l_puudumine_id
          -- Период поиска: месяц до начала отсутствия.
          -- make_date(..., 1) создает 1 число месяца отсутствия.
      AND po.kpv >= (make_date(EXTRACT(YEAR FROM p.kpv1)::INT, EXTRACT(MONTH FROM p.kpv1)::INT, 1) - INTERVAL '1 month')
      AND po.kpv <= make_date(EXTRACT(YEAR FROM p.kpv1)::INT, EXTRACT(MONTH FROM p.kpv1)::INT, 1)
      AND po.konto = ANY (l_palk_kontod);

    -- 6. Fallback: Если суммы нет, берем оклад из договора
    IF kokkuleppe_summa IS NULL OR kokkuleppe_summa = 0 THEN
        kokkuleppe_summa := COALESCE(v_leping.palk, 0);
    END IF;

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period(JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_keskpalga_period(JSONB) TO dbvaatleja;