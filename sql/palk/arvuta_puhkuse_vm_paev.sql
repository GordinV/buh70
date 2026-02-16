DROP FUNCTION IF EXISTS palk.arvuta_puhkuse_vm_paev(JSONB);

--tahtapaevad
CREATE OR REPLACE FUNCTION palk.arvuta_puhkuse_vm_paev(IN params JSONB,
                                                       OUT kpv DATE)
    LANGUAGE plpgsql
    STABLE
AS
$$
/*
 Функция рассчитывает дату выплаты отпускных или других компенсаций.
 Логика:
 1. Если дата выплаты задана вручную -> берем её.
 2. Если есть спец. коды (командировка и т.д.) -> выплата с зарплатой (конец месяца).
 3. Для отпуска (P) -> выплата за 2 рабочих дня до начала.
*/
DECLARE
    l_puudumise_id  INTEGER = (params ->> 'puudumise_id')::INTEGER;
    l_puhkuse_algus DATE    = (params ->> 'alg_kpv')::DATE;
    l_puhkuse_lopp  DATE    = (params ->> 'lopp_kpv')::DATE;
    l_makse_paev    DATE    = (params ->> 'makse_kpv')::DATE;
    l_rekvid        INTEGER = (params ->> 'rekvid')::INTEGER; -- Добавили чтение rekvid из параметров

    l_esimine_paev  DATE;
    l_toopaevad     INTEGER = 0;
    l_vs_kooded     TEXT[]; -- коды отсутствия

    -- Коды: выплата в день зарплаты (последний день месяца НАЧАЛА)
    l_palgapaev_koodid TEXT[] = '{K, PIH, TL, V, VK, AT, ÕP}';

    -- Коды: выплата в конце месяца ОКОНЧАНИЯ
    l_viimane_paeva_vm TEXT[] = '{AH, PH, H}';
BEGIN
    -- 1. Если дата выплаты задана явно, используем её.
    IF l_makse_paev IS NOT NULL THEN
        kpv = l_makse_paev;
        RETURN;
    END IF;

    -- 2. Если задан ID отсутствия, получаем данные из базы (один раз!)
    IF l_puudumise_id IS NOT NULL THEN
        SELECT p.kpv1,
               p.kpv2,
               t.rekvid,
               pt.vs_kooded
        INTO l_puhkuse_algus,
            l_puhkuse_lopp,
            l_rekvid,
            l_vs_kooded
        FROM palk.puudumine p
            inner join palk.tooleping t on t.id = p.lepingid
                 LEFT OUTER JOIN palk.com_puudumiste_tyyp pt ON pt.liik = p.puudumiste_liik AND pt.id = p.tyyp
        WHERE p.id = l_puudumise_id;
    END IF;

    -- Fallback для rekvid, если не передан и не найден в базе (для совместимости)
    l_rekvid = COALESCE(l_rekvid, 63);

    -- 3. Проверка специальных правил выплаты.

    -- Правило 1: Выплата в последний день месяца начала (Командировки и т.д.)
    IF l_vs_kooded IS NOT NULL AND l_vs_kooded <@ l_palgapaev_koodid THEN
        kpv = get_last_day(l_puhkuse_algus);
        RETURN;
    END IF;

    -- Правило 2: Выплата в последний день месяца окончания (Больничные и т.д.)
    IF l_vs_kooded IS NOT NULL AND l_vs_kooded <@ l_viimane_paeva_vm THEN
        kpv = get_last_day(l_puhkuse_lopp);
        RETURN;
    END IF;

    -- Проверка на наличие даты начала (критично для расчета отпускных).
    IF l_puhkuse_algus IS NULL THEN
        RAISE EXCEPTION 'Viga: puudub puhkuse algus kuupäev (params: %)', params;
    END IF;

    -- 4. Стандартный расчет для отпускных (P): выплата за 2 рабочих дня до начала.

    -- Начинаем отсчет с дня перед отпуском
    l_esimine_paev = (l_puhkuse_algus - interval '1 day')::DATE;

    -- Ищем 2 рабочих дня назад
    WHILE l_toopaevad < 2
        LOOP
            -- Используем функцию is_workday для проверки (учитывает выходные и праздники)
            IF is_workday(l_esimine_paev, l_rekvid) THEN
                l_toopaevad = l_toopaevad + 1;
            END IF;

            -- Если нашли 2 дня, прерываемся ДО уменьшения даты,
            -- иначе дата выплаты сдвинется лишний раз назад.
            IF l_toopaevad = 2 THEN
                EXIT;
            END IF;

            -- Шагаем назад
            l_esimine_paev = (l_esimine_paev - interval '1 day')::DATE;
        END LOOP;

    kpv = l_esimine_paev;
    RETURN;

END;
$$;

GRANT EXECUTE ON FUNCTION palk.arvuta_puhkuse_vm_paev(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_puhkuse_vm_paev(JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.arvuta_puhkuse_vm_paev(JSONB) TO dbvaatleja;

--   "puudumise_id": 152438,
/*
select *
from
    palk.arvuta_puhkuse_vm_paev('{
      "alg_kpv": "2026-02-10",
      "lopp+kpv": "2026-02-14"
    }')
*/
/*
*/