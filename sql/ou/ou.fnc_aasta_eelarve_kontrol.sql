CREATE OR REPLACE FUNCTION ou.fnc_aasta_eelarve_kontrol(l_rekvid INTEGER, l_kpv DATE DEFAULT current_date)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_aasta INTEGER = date_part('year', coalesce(l_kpv, current_date));
    l_kuu   INTEGER = date_part('month', coalesce(l_kpv, current_date));
BEGIN
    -- Функция проверяет, открыт ли бюджет для учреждения на заданную дату.
    -- Возвращает TRUE, если бюджет открыт.
    -- Возвращает FALSE, если бюджет закрыт (eelarve_kinni = 1).

    -- Обработка случая, когда дата передана как NULL
    if l_kpv is null then
        -- Создаем дату (1-е число месяца) и получаем последний день месяца
        -- Используем стандартную функцию make_date вместо date()
        l_kpv = get_last_day(make_date(l_aasta, l_kuu, 1));
    end if;

    -- Проверяем существование периода.
    -- Если записи для данного года/месяца/учреждения нет, создаем её.
    -- Примечание: Функция имеет побочный эффект (INSERT).
    IF NOT exists
    (
        SELECT
            a.id
        FROM
            ou.aasta a
        WHERE
              a.kuu = l_kuu
          AND a.aasta = l_aasta
          AND a.rekvid = l_rekvid
    )
    THEN
        INSERT INTO ou.aasta (rekvid, "aasta", kuu, kinni, eelarve_kinni)
        VALUES (l_rekvid, l_aasta, l_kuu, 0, 0);
    END IF;

    -- Проверяем флаг закрытия бюджета (eelarve_kinni)
    IF exists
    (
        SELECT
            a.id
        FROM
            ou.aasta a
        WHERE
              a.kuu = l_kuu
          AND a.aasta = l_aasta
          AND a.rekvid = l_rekvid
          AND a.eelarve_kinni = 1
    )
    THEN
        -- Бюджет закрыт
        RETURN FALSE;
    ELSE
        -- Бюджет открыт
        RETURN TRUE;
    END IF;

END
$$;

ALTER FUNCTION ou.fnc_aasta_eelarve_kontrol(INTEGER, DATE) OWNER TO vlad;

GRANT EXECUTE ON FUNCTION ou.fnc_aasta_eelarve_kontrol(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.fnc_aasta_eelarve_kontrol(INTEGER, DATE) TO dbkasutaja;

select ou.fnc_aasta_eelarve_kontrol(63, DATE(2025,01,01));