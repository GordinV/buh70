DROP FUNCTION IF EXISTS palk.get_palk_taabel_id(params JSONB);

-- вернет ид табеля, на основании которого эта операция создана
CREATE FUNCTION palk.get_palk_taabel_id(params JSONB)
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_palk_oper_id INTEGER = params ->> 'palk_oper_id';
    l_taabel_id    INTEGER;
    v_palk_oper    RECORD;
BEGIN
    with
        po as (
                  select
                      p.parentid                                                    as id,
                      p.kpv,
                      p.konto,
                      p.libid,
                      p.lepingid,
                      (p.properties ->> 'paranduse_kpv')                            as p_kpv,
                      (p.properties ->> 'taabel_id')::integer                       as taabel_id,
                      COALESCE(lib.properties::jsonb ->> 'tabeli_tyyp', 'TAVALINE') as taabeli_tyyp
                  from
                      PALK.palk_oper              p
                          INNER JOIN libs.library lib
                                     ON p.libid = lib.id
                  where
                        p.parentid = l_palk_oper_id
                    AND (lib.properties::jsonb ->> 'liik')::integer = 1
                    AND lib.library = 'PALK'
        )
    SELECT
        p.id,
        pk.percent_,
        pt.tyyp,
        p.konto,
        coalesce(p.taabel_id, pt.id) as taabel_id
    into v_palk_oper
    FROM
        po                                    p
            INNER JOIN      palk.palk_kaart   pk
                            ON pk.libid = p.libid
                                AND pk.lepingid = p.lepingid
            LEFT OUTER JOIN palk.palk_taabel1 pt
                            ON pt.lepingid = p.lepingid
                                -- только для процентных операций
                                and not empty(pk.percent_::integer)

                                -- только если нет прямой ссылки
                                and p.taabel_id is null
                                AND pt.status <> 'deleted'
/*                                AND (pt.aasta = date_part('year', case
                                                                      when (p.p_kpv) is not null
                                                                          then (p.p_kpv)::date
                                                                      else p.kpv end)::integer
                                    AND pt.kuu = date_part('month', case
                                                                        when (p.p_kpv) is not null
                                                                            then (p.p_kpv)::date
                                                                        else p.kpv end)::integer
                                   )
*/
                                AND (
                                   p.p_kpv is null
                                       and make_date(pt.aasta, pt.kuu, 1)::date =
                                           make_date(year((p.kpv - interval '1 month')::date),
                                                     month((p.kpv - interval '1 month')::date), 1)
                                       or (
                                       (pt.aasta = date_part('year', case
                                                                         when (p.p_kpv) is not null
                                                                             then (p.p_kpv)::date
                                                                         else p.kpv end)::integer
                                           AND pt.kuu = date_part('month', case
                                                                               when (p.p_kpv) is not null
                                                                                   then (p.p_kpv)::date
                                                                               else p.kpv end)::integer
                                           )
                                       ))
                                AND pt.tyyp::text = p.taabeli_tyyp::text
            ,
        palk.palk_kulu_kontod                 pkk
    WHERE
        array [p.konto]::text[] <@ pkk.pohi_palk_kontod
    and p.taabeli_tyyp::TEXT <> 'TAVALINE'
    limit 1;


    IF v_palk_oper.ID IS NULL THEN
        -- операция не найдена
        RETURN NULL;
    end if;

    if empty(v_palk_oper.percent_::integer) then
        -- расчет на абсолютных цифрах. табель не нужен
        return null;
    end if;

    -- 1. если ссылка сохранена

    if v_palk_oper.taabel_id is not null and exists
    (
        select id from palk.palk_taabel1 t where t.id = v_palk_oper.taabel_id and t.status::text <> 'deleted'
    ) then
        -- есть прямая ссылка, вернем ее
        l_taabel_id = v_palk_oper.taabel_id::integer;
        return l_taabel_id;
    end if;

    -- 2. ссылки нет. анализируем рассчет
    if empty(v_palk_oper.percent_::integer) then
        -- этот код не считается через табель
        return null::integer;
    end if;

    --3 теперь ищем табель, с которого был расчет
    l_taabel_id = v_palk_oper.taabel_id;
    RETURN l_taabel_id;

END;
$$;



GRANT EXECUTE ON FUNCTION palk.get_palk_taabel_id(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_palk_taabel_id(JSONB) TO dbpeakasutaja;


/*
select palk.get_palk_taabel_id('{"palk_oper_id":2319355}'::jsonb)  -- -> 0

 */


