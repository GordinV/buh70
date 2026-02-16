DROP FUNCTION IF EXISTS palk.gen_puhkuse_oper(INTEGER, JSON);
DROP FUNCTION IF EXISTS palk.gen_puhkuse_oper(INTEGER, JSONB);

--tahtpaevad
CREATE OR REPLACE FUNCTION palk.gen_puhkuse_oper(IN user_id INTEGER, IN params JSONB, OUT result INTEGER,
                                                 OUT error_code INTEGER, OUT error_message TEXT, OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    v_lib                     RECORD;
    l_kpv                     DATE;
    l_summa                   NUMERIC(12, 2); -- расчитанная сумма отпускных
    l_puudumise_id            integer        = params -> 'puudumise_id'; -- ссылка на запись об отпуске, kohuslik
    l_dokprop_id              INTEGER        = params ->> 'dokprop_id'; -- индентификатор профиля для контировки eba kohuslik
    is_delete_prev_oper       BOOLEAN        = FALSE; -- params -> 'kas_kustuta'; -- предварительное удаление прежнего расчета
    l_algorithm               text           = params ->> 'algorithm';
    l_avg_paeva_summa         numeric(12, 2) = params ->> 'avg_paeva_summa';
    l_arv_paevad_perioodis    integer        = params ->> 'arv_paevad_perioodis';
    l_selg                    text           = params ->> 'selg';
    l_params_kpv1             date           = params ->> 'kpv1';
    l_params_kpv2             date           = params ->> 'kpv2';
    l_makse_kpv               date           = params ->> 'makse_kpv';
    l_kokkuleppe_summa        numeric(12, 2) = params ->> 'kokkuleppe_summa'; -- договорная сумма для алгоритма с договорной суммой
    l_puhkuse_summa           numeric(12, 2) = params ->> 'summa';
    l_allikas                 text           = params ->> 'allikas';
    l_artikkel                text           = params ->> 'artikkel';
    l_tegev                   text           = params ->> 'tegev';
    l_konto                   text           = params ->> 'konto';
    l_params                  JSON;
    l_save_params             JSON;
    l_function                TEXT;
    tulemus                   RECORD;
    l_dok_id                  INTEGER; -- = params ->> 'palk_oper_id'; -- ИД сформированной проводки
    v_palk_oper               RECORD; -- соберем все данные операции в строку
    l_tulemus_json            JSON;
    v_user                    RECORD;
    v_tulemus                 RECORD;
    l_viimane_summa           NUMERIC(12, 2);
    l_viimane_params          JSON;
    v_puudumine               record;
    l_periods                 integer;
    l_alg_kpv_perioodis       date ;
    l_lopp_kpv_perioodis      date ;
    l_kohustuse_alg_paev      date           = (case
                                                    when trim(coalesce(params ->> 'vm_kpv', '')) = '' then null
                                                    else params ->> 'vm_kpv' end)::date; -- дата начала обязательства по выплате
    l_kohustuse_kpv           date; -- расчтная дата наступления обязательства по начислению отпуска
    l_pidu_paevad_perioodis   integer        = (
                                                   select
                                                       count(id)
                                                   from
                                                       cur_tahtpaevad t
                                                   where
                                                       make_date(t.aasta, t.kuu, t.paev) between
                                                           l_alg_kpv_perioodis and l_lopp_kpv_perioodis
                                               );
    l_pohi_dok_id             integer;
    l_ettemaksu_dok_ids       integer[];
    l_kas_ettemaks            boolean        = false; -- определяет это предоплата иди нет

    v_kesk_palk               record; -- расчет среднего
    l_puhkuse_periodi_osa     date;
    l_libs_ids                integer[];
    l_leping_ids              integer[];
    kas_arvestus_salvestatud  boolean        = false;
    l_arvetuse_properties     jsonb;
    l_paevad_kokku            integer        = 0; -- всего дней в отсутствии
    HAIGUSE_PAEVAD            INTEGER        = 8; -- длительность больничного предел
    l_ettemaksu_period        date; -- будет храниться вычисляемое значение периода
    l_salvestatud_summa_kokku numeric        = 0; -- будем сохранять сумму итого , которая была сохранена для контроля.
BEGIN
    SELECT
        kasutaja,
        rekvid
    INTO v_user
    FROM
        ou.userid u
    WHERE
        u.id = user_Id;

    IF v_user.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud,  userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;
    END IF;

    if l_params_kpv1 is null then
        -- считаем дни для среднего
        select
            alg_kpv,
            lopp_kpv
        into l_params_kpv1, l_params_kpv2
        from
            palk.arvuta_keskpalga_period(jsonb_build_object('puudumise_id', l_puudumise_id));

    end if;


    -- get periods
    select
        p.kpv2,
        p.kpv1,
        (p.properties ->> 'avg_paeva_summa')::numeric                       as avg_paeva_summa,
        coalesce((p.properties ->> 'arvestatud_paevad')::integer, p.paevad) as arvestatud_paevad,
        coalesce((p.properties ->> 'palk_oper_id')::integer, 0)::integer    as palk_oper_id,
        p.puudumiste_liik,
        p.tyyp,
        p.id,
        pt.vs_kooded,
        p.lepingid,
        t.parentid                                                          as isik_id,
        a.tp                                                                as tp,
        l_params_kpv1                                                       as params_kpv1,
        l_params_kpv2                                                       as params_kpv2,
        (p.properties ->> 'vm_kpv')::date                                   as vm_kpv
    into v_puudumine
    from
        palk.puudumine                               p
            inner join      palk.tooleping           t on p.lepingid = t.id
            inner join      libs.asutus              a on a.id = t.parentid
            left outer join palk.com_puudumiste_tyyp pt on pt.liik = p.puudumiste_liik and pt.id = p.tyyp
    where
        p.id = l_puudumise_id;

    IF v_puudumine.lepingid IS NULL
    THEN
        error_code = 6;
        error_message = 'Parametrid on vale või puuduvad. Puudub leping';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;

    END IF;

    -- проверим на повторный расчет
    IF coalesce(v_puudumine.palk_oper_id, 0) > 0 and exists
    (
        select
            id
        from
            palk.palk_oper
        where
            parentid = v_puudumine.palk_oper_id
    )
    THEN
        error_code = 6;
        error_message = 'Palgaopratsioon juba olemas';
        result = 0;
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

        RETURN;

    END IF;


    for v_kesk_palk in (
                           with
                               report as (
                                             select *
                                             from
                                                 palk.calc_avg_income_vacation(
                                                         user_id::INTEGER, jsonb_build_object(
                                                         'alg_kpv', v_puudumine.params_kpv1,
                                                         'lopp_kpv', v_puudumine.params_kpv2,
                                                         'isik_id', v_puudumine.isik_id,
                                                         'puudumine_id', l_puudumise_id,
                                                         'kokkulepe_summa', l_kokkuleppe_summa
                                                                           ):: JSON) a
                                             where
                                                  l_algorithm is null
                                               or ltrim(rtrim(a.algorithm::text)) = ltrim(rtrim(l_algorithm))::text
                                             order by
                                                 a.puhkuse_summa desc, a.avg_paeva_summa desc, a.konto desc

                                         ),
                               algoritm as (
                                             select
                                                 algorithm
                                             from
                                                 report a
                                             limit 1
                                         )

                           select
                               r.*
                           from
                               report   r,
                               algoritm a
                           where
                               r.algorithm = a.algorithm
                       )

        loop

            if v_kesk_palk.algorithm = 'Arveldus (käsitsi)' then
                -- подменим расчетные значения на переданные параметры
                v_kesk_palk.puhkuse_summa = l_puhkuse_summa;
                v_kesk_palk.arv_paevad_perioodis = l_arv_paevad_perioodis;
                v_kesk_palk.avg_paeva_summa = l_avg_paeva_summa;
                v_kesk_palk.allikas = l_allikas;
                v_kesk_palk.artikkel = l_artikkel;
                v_kesk_palk.tegev = l_tegev;
--                v_kesk_palk.konto = l_konto;

            end if;

            -- расчет даты начала расчета отпускных
            if l_alg_kpv_perioodis is null or l_alg_kpv_perioodis > v_puudumine.kpv1
            then
                l_alg_kpv_perioodis = v_puudumine.kpv1;
                l_lopp_kpv_perioodis = v_puudumine.kpv2;
            end if;
            l_params_kpv1 = v_puudumine.kpv1;
            l_params_kpv2 = v_puudumine.kpv2;

            -- получим дату настпуления обязательства, для его последующего сохранения для контировки предоплат
            if l_kohustuse_alg_paev is not null then
                --дата наступления обязательств обозначена
                l_kohustuse_kpv = l_kohustuse_alg_paev;
            else
                l_kohustuse_kpv =
                        palk.arvuta_puhkuse_vm_paev(jsonb_build_object('puudumise_id', l_puudumise_id,
                                                                       'alg_kpv', l_alg_kpv_perioodis,
                                                                       'makse_kpv', l_makse_kpv));
            end if;

            if l_kohustuse_alg_paev is null then
                l_kohustuse_alg_paev = l_kohustuse_kpv;
            end if;

            l_avg_paeva_summa = v_kesk_palk.avg_paeva_summa;

            if l_dokprop_id is null then
                -- берем последний профиль этого учреждения для контирования
                l_dokprop_id = (
                                   select
                                       doklausid
                                   from
                                       palk.palk_oper po
                                   where
                                         po.lepingid = v_kesk_palk.leping_id
                                     and po.doklausid is not null
                                   order by po.id desc
                                   limit 1
                               );
            end if;

            -- инициализируем
            SELECT
                NULL::INTEGER AS doc_id,
                null::text    AS error_message,
                NULL::INTEGER AS error_code
            INTO v_tulemus;

            with
                pk as (
                          SELECT
                              pk.id                              as pk_id,
                              pk.libid                           AS id,
                              pk.liik,
                              empty(pk.asutusest::INTEGER)       AS is_asutusest,
                              pk.tululiik,
                              empty(percent_::INTEGER)           AS is_percent,
                              pk.tunnus,
                              pk.tunnusid::INTEGER               AS tunnusid,
                              pk.minsots,
                              pk.objekt,
                              l.properties::jsonb ->> 'konto'    as konto,
                              l.properties::jsonb ->> 'tegev'    as tegev,
                              l.properties::jsonb ->> 'artikkel' as artikkel,
                              l.properties::jsonb ->> 'allikas'  as allikas

                          FROM
                              palk.cur_palk_kaart         pk
                                  inner join libs.library l on pk.libid = l.id
                          where
                                -- только начисления
                                l.properties::jsonb ->> 'liik' = '1'
                                -- только заданный вид отсутствия
                            and l.properties::jsonb ->> 'konto' in (
                                                                       select
                                                                           unnest(puhkused_kontod)
                                                                       from
                                                                           palk.palk_kulu_kontod pkk
                                                                       where
                                                                             v_puudumine.puudumiste_liik::text = 'PUHKUS'
                                                                         and v_puudumine.tyyp not in (7, 9, 11) --за исключением учебного отпуска
                                                                       UNION ALL
                                                                       select
                                                                           unnest(huvitised_kontod)
                                                                       from
                                                                           palk.palk_kulu_kontod
                                                                       where
                                                                             v_puudumine.puudumiste_liik::text = 'PUHKUS'
                                                                         and v_puudumine.tyyp not in (7, 9)
                                                                       UNION ALL
                                                                       select
                                                                           '103560'::text
                                                                       from
                                                                           palk.palk_kulu_kontod
                                                                       where
                                                                             v_puudumine.puudumiste_liik::text = 'PUHKUS'
                                                                         and v_puudumine.tyyp in (7, 9)
                                                                       union all

                                                                       select
                                                                           unnest(koolitus_kontod)
                                                                       from
                                                                           palk.palk_kulu_kontod
                                                                       where
                                                                           v_puudumine.puudumiste_liik::text = 'KOOLITUS'
                                                                       UNION ALL
                                                                       select
                                                                           unnest(pohi_palk_kontod)
                                                                       from
                                                                           palk.palk_kulu_kontod
                                                                       where
                                                                           v_puudumine.puudumiste_liik::text = 'KOMANDEERING'
                                                                       union all
                                                                       -- haigus
                                                                       select
                                                                           unnest(huvitised_kontod)
                                                                       from
                                                                           palk.palk_kulu_kontod
                                                                       where
                                                                           v_puudumine.puudumiste_liik::text = 'HAIGUS'


                                                                   )
                            and lepingid = v_kesk_palk.leping_id
                            AND pk.status < 3
                      ),
                kontod as (
                          select
                              p.kood                                   as konto,
                              cpt.liik,
                              cpt.eesti,
                              cpt.vene,
                              p.properties::jsonb ->> 'puudumise_tyyp' as puudumise_tyyp
                          from
                              pk
                                  inner join      libs.library p on p.kood = pk.konto and p.library = 'KONTOD'
                                  left outer join (
                                                      select *
                                                      from
                                                          (
                                                              select
                                                                  pt.id,
                                                                  pt.liik::varchar(20),
                                                                  pt.eesti::varchar(120),
                                                                  pt.vene::varchar(120)
                                                              from
                                                                  palk.com_puudumiste_tyyp pt
                                                              where
                                                                    pt.kas_kehtiv
                                                                and pt.liik = v_puudumine.puudumiste_liik
                                                          ) qry
                                                  )            cpt
                                                  on (cpt.id = (p.properties::jsonb ->> 'puudumise_tyyp')::integer or
                                                      p.properties::jsonb ->> 'puudumise_tyyp' is null)
                      )
            select
                pk.*,
                kontod.puudumise_tyyp
            into v_lib
            from
                pk
                    left outer join kontod on pk.konto = kontod.konto
            where
                  pk.konto = v_kesk_palk.konto
              and (kontod.puudumise_tyyp IS NULL OR
                   coalesce(kontod.puudumise_tyyp::integer, 1)::integer in (
                                                                               select
                                                                                   v_puudumine.tyyp::integer
                                                                               union all
                                                                               -- добавим в случае учебного отпуска, все остальные учебные отпуска
                                                                               select
                                                                                   case when v_puudumine.tyyp = 50 then 5 end
                                                                               where
                                                                                   v_puudumine.tyyp = 50
                                                                               union all
                                                                               select
                                                                                   case when v_puudumine.tyyp = 51 then 5 end
                                                                               where
                                                                                   v_puudumine.tyyp = 51
                                                                           )
                      )
            order by pk.pk_id desc
            limit 1;

            if v_lib.id is null then
                l_selg = 'Viga: ' || v_kesk_palk.isik || ' puudumise konto:' || coalesce(v_kesk_palk.konto, '') ||
                         ' kood palgakaardis';
                raise exception '%',l_selg;
--                CONTINUE;
            end if;

            -- проверка на удаление прежней операции с такими параметрами
            IF is_delete_prev_oper IS NOT NULL AND is_delete_prev_oper and l_puudumise_id is not null
            THEN
                -- поиск аналогичной операции*
                for v_palk_oper in
                    SELECT
                        parentid as dok_id
                    FROM
                        palk.palk_oper po
                    WHERE
                          po.lepingid = v_kesk_palk.leping_id
                      and coalesce((po.properties ->> 'puudumise_id')::integer, 0) in (
                                                                                          select
                                                                                              id
                                                                                          from
                                                                                              palk.puudumine p
                                                                                          where
                                                                                                p.lepingid = v_kesk_palk.leping_id
                                                                                            and p.puudumiste_liik = v_puudumine.puudumiste_liik
                                                                                            and p.tyyp = v_puudumine.tyyp
                                                                                            and p.kpv1 = v_puudumine.kpv1
                                                                                            and p.kpv2 = v_puudumine.kpv2
                                                                                            and p.status <> 'deleted'
                                                                                      )
                    loop

                        -- delete
                        PERFORM palk.sp_delete_palk_oper(user_id, v_palk_oper.dok_id, FALSE);
                    end loop;
            END IF;

            -- рассчитаем запись отсутствия для данного договора
            select
                coalesce((p.properties ->> 'arvestatud_paevad')::integer, p.paevad) as arvestatud_paevad
            into l_arv_paevad_perioodis
            from
                palk.puudumine p
            where
                  p.lepingid = v_kesk_palk.leping_id
              and p.puudumiste_liik = v_puudumine.puudumiste_liik
              and p.tyyp = v_puudumine.tyyp
              and p.kpv1 = v_puudumine.kpv1
              and p.kpv2 = v_puudumine.kpv2
              and p.status <> 'deleted'
            limit 1;

            -- получим сумму отпускных
            l_summa = l_avg_paeva_summa * l_arv_paevad_perioodis;

            l_periods =
                    (
                        select
                            (year(v_puudumine.kpv2) - year(v_puudumine.kpv1)) * 12 +
                            (month(v_puudumine.kpv2) - month(v_puudumine.kpv1) + 1)
                    );

            -- если отпуск в одном периоде. то дату оставляем датой начало отпуска
            l_kpv = l_kohustuse_alg_paev;

            if get_last_day(l_kohustuse_alg_paev) < get_last_day(l_alg_kpv_perioodis) then
                -- дата наступления обязательства раньще
                l_alg_kpv_perioodis = gomonth(l_alg_kpv_perioodis, (-1));
                l_alg_kpv_perioodis = make_date(year(l_alg_kpv_perioodis), month(l_alg_kpv_perioodis), 1);

                l_kas_ettemaks = true;

                -- запомним дату реального отпуска (его части)
                l_puhkuse_periodi_osa = l_kpv;
                l_kpv = l_kohustuse_alg_paev;

                -- проверим, является ли это предоплатой
                if get_last_day(l_kpv) = get_last_day(v_puudumine.kpv2) then
                    --так как расчетный день совпадает с датой окончания отпуска (по последнему дню) то это не предоплата
                    l_kas_ettemaks = false;
                end if;
            else
                l_kas_ettemaks = false;
            end if;

            -- для больничных, не считаем периоды, а расчет производится на последний день месяца выхода из больничного
            if v_puudumine.puudumiste_liik = 'HAIGUS' then
                l_periods = 1;
                l_kpv = get_last_day(v_puudumine.kpv2);
                if l_kohustuse_alg_paev is not null then
                    l_kpv = l_kohustuse_alg_paev;
                end if;
            end if;

            FOR i IN 1..l_periods
                LOOP
                    if i > 1 then
                        -- чтобы не портить расчет предоплаты ранее
                        l_kas_ettemaks = false;
                    end if;

                    if l_periods > 1 then
                        -- arvestame summa periodis ja paevad
                        if i > 1 then
                            l_alg_kpv_perioodis = gomonth(l_alg_kpv_perioodis, (i - 1));
                            l_alg_kpv_perioodis = make_date(year(l_alg_kpv_perioodis), month(l_alg_kpv_perioodis), 1);
                            l_kas_ettemaks = true;
                        end if;
                    end if;


                    -- поправка на расчет в календарных днях
                    l_arv_paevad_perioodis =
                            v_kesk_palk.data::jsonb -> 'details' -> (i - 1) ->> 'calendar_days_in_period';
                    l_lopp_kpv_perioodis = v_kesk_palk.data::jsonb -> 'details' -> (i - 1) ->> 'period_finish';

                    if v_kesk_palk.algorithm = 'Arveldus (käsitsi)' then
                        -- у нас массив с деталями, берем данные из первой записи
                        l_arv_paevad_perioodis =
                                v_kesk_palk.data::jsonb -> 0 -> 'details' -> (i - 1) ->> 'calendar_days_in_period';
                        l_lopp_kpv_perioodis = v_kesk_palk.data::jsonb -> 0 -> 'details' -> (i - 1) ->> 'period_finish';

                    end if;

                    if l_alg_kpv_perioodis > l_lopp_kpv_perioodis then
                        l_alg_kpv_perioodis = make_date(year(l_lopp_kpv_perioodis), month(l_lopp_kpv_perioodis), 1);
                    end if;

                    -- праздничные дни
                    l_pidu_paevad_perioodis = (
                                                  select
                                                      count(id)
                                                  from
                                                      cur_tahtpaevad t
                                                  where
                                                      make_date(t.aasta, t.kuu, t.paev) between
                                                          l_alg_kpv_perioodis and l_lopp_kpv_perioodis
                                              );


                    l_summa = l_avg_paeva_summa * (l_arv_paevad_perioodis - l_pidu_paevad_perioodis);

                    -- можно выплачивать больничные позже, если надо (В.Б 09.02.2026)
                    if  v_puudumine.puudumiste_liik = 'HAIGUS' and l_lopp_kpv_perioodis < l_kohustuse_alg_paev then
                        l_lopp_kpv_perioodis = l_kohustuse_alg_paev;
                    end if;

                    -- контроль периода для модуля ЗП
                    IF NOT (ou.fnc_aasta_palk_kontrol(v_user.rekvid, l_lopp_kpv_perioodis))
                    THEN
                        RAISE EXCEPTION 'Viga, periodi kontrol %', l_lopp_kpv_perioodis;
                    END IF;

                    if v_puudumine.puudumiste_liik = 'HAIGUS' then
                        --  (со 2-го по 8-ой день
                        l_summa = v_kesk_palk.puhkuse_summa;

                        -- отработаем минус в сумме
                        if l_summa < 0 then
                            l_summa = 0;
                        end if;

                        -- запомним кол-во дней использованных в больничном
                        l_paevad_kokku = l_paevad_kokku + case
                                                              when (l_arv_paevad_perioodis - l_pidu_paevad_perioodis) = 1
                                                                  then
                                                                  0
                                                              when (l_arv_paevad_perioodis - l_pidu_paevad_perioodis) >= HAIGUSE_PAEVAD + 1
                                                                  then
                                                                  HAIGUSE_PAEVAD - l_paevad_kokku
                                                              else 0 end;
                    end if;

                    -- расчет для алгоритма продолжение ЗП
                    if v_kesk_palk.algorithm in ('Palk', 'Kokkuleppe summa', 'miinimunpalk') then
                        -- ищем подходящий период в расчете

                        l_summa = v_kesk_palk.data::jsonb -> (i - 1) ->> 'summa';
                        l_arv_paevad_perioodis = v_kesk_palk.data::jsonb -> (i - 1) ->> 'paevad';
                        l_alg_kpv_perioodis = v_kesk_palk.data::jsonb -> (i - 1) ->> 'period_start';
                        l_lopp_kpv_perioodis = get_last_day(l_alg_kpv_perioodis);

                        if l_lopp_kpv_perioodis > v_puudumine.kpv2 then
                            l_lopp_kpv_perioodis = v_puudumine.kpv2;
                        end if;

                    end if;

                    if v_kesk_palk.algorithm = 'Arveldus (käsitsi)' and l_periods = 1 then
                        -- убираем расчеты и пишем заданные параметры
                        l_summa = v_kesk_palk.puhkuse_summa;
                        l_arv_paevad_perioodis = v_kesk_palk.arv_paevad_perioodis;
                    end if;

                    -- Готовим параметры для расчета
                    SELECT
                        row_to_json(row)
                    INTO l_params
                    FROM
                        (
                            SELECT
                                case
                                    when l_periods = 1 then l_lopp_kpv_perioodis
                                    else get_last_day(l_kpv) end AS kpv,
                                v_user.rekvid                    AS rekvid,
                                v_kesk_palk.leping_id            AS lepingid,
                                V_lib.id                         AS libid,
                                l_summa                          as alus_summa
                        ) row;

                    -- определяем расчетную процедуру
                    l_function = 'palk.sp_calc_arv';

                    -- вызов процедура расчета

                    EXECUTE 'select * from ' || l_function || '($1, $2)'
                        INTO STRICT tulemus
                        USING user_id, l_params;

                    l_tulemus_json = row_to_json(tulemus);

                    IF v_lib.liik = 1 AND tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN
                        l_viimane_summa = tulemus.summa;
                        l_viimane_params = l_params;
                    END IF;

                    if l_kpv < l_kohustuse_alg_paev then
                        l_kpv = l_kohustuse_alg_paev;
                    end if;

                    IF tulemus.summa IS NOT NULL AND tulemus.summa <> 0
                    THEN
                        -- уточним расчет предоплаты
                        l_kas_ettemaks = case
                                             when l_kas_ettemaks and
                                                  get_last_day(l_lopp_kpv_perioodis) <> get_last_day(l_kpv)
                                                 then l_kas_ettemaks
                                             else false end;
                        -- сохраним период за который идет расчет
                        l_ettemaksu_period = l_lopp_kpv_perioodis;

                        SELECT
                            0 :: INTEGER                                                   AS id,
                            l_kpv                                                          AS kpv,
                            l_kpv                                                          as maksekpv,
                            v_kesk_palk.leping_id                                          AS lepingid,
                            V_lib.id                                                       AS libid,
                            tulemus.summa                                                  AS summa,
                            l_dokprop_id                                                   AS dokpropid,
                            case
                                when empty(v_kesk_palk.tegev) then v_lib.tegev
                                else v_kesk_palk.tegev end                                 AS kood1,
                            case
                                when empty(v_kesk_palk.allikas) then v_lib.allikas
                                else v_kesk_palk.allikas end                               AS kood2,
                            case
                                when empty(v_kesk_palk.artikkel) then v_lib.artikkel
                                else v_kesk_palk.artikkel end                              AS kood5,
                            null                                                           AS kood4,
                            v_lib.konto                                                    AS konto,
                            v_kesk_palk.tunnus                                             AS tunnus,
                            v_lib.tunnusid                                                 AS tunnusid,
                            null                                                           AS korrkonto,
                            l.proj                                                         AS proj,
                            V_lib.objekt                                                   AS objekt,
                            v_puudumine.tp :: TEXT                                         AS tp,
                            coalesce((l_tulemus_json ->> 'tm') :: NUMERIC, 0) :: NUMERIC   AS tulumaks,
                            coalesce((l_tulemus_json ->> 'sm') :: NUMERIC, 0) :: NUMERIC   AS sotsmaks,
                            coalesce((l_tulemus_json ->> 'tki') :: NUMERIC, 0) :: NUMERIC  AS tootumaks,
                            coalesce((l_tulemus_json ->> 'tka') :: NUMERIC, 0) :: NUMERIC  AS tka,
                            coalesce((l_tulemus_json ->> 'pm') :: NUMERIC, 0) :: NUMERIC   AS pensmaks,
                            coalesce((l_tulemus_json ->> 'mvt') :: NUMERIC, 0) :: NUMERIC  AS tulubaas,
                            v_lib.tululiik                                                 AS tululiik,
                            l_tulemus_json ->> 'selg' :: TEXT                              AS muud,
                            TRUE                                                           AS kas_lausend,
                            FALSE                                                          AS kas_kas_arvesta_saldo,
                            l_puudumise_id                                                 as puudumise_id,
                            l_kas_ettemaks                                                 as kas_ettemaks,
                            l_ettemaksu_period                                             as ettemaksu_periood,
                            case when i = 1 then l_kohustuse_kpv else null::date end::date as kohustuse_kpv
                        INTO v_palk_oper
                        FROM
                            palk.com_palk_lib AS l
                        WHERE
                            l.id = V_lib.id;

                        l_save_params = row_to_json(v_palk_oper);

                        -- save results
                        l_dok_id =
                                palk.sp_salvesta_palk_oper(
                                        ('{"lausend":true,"data":' || l_save_params || '}') :: JSON,
                                        user_id,
                                        v_user.rekvid);

                        IF (coalesce(l_dok_id, 0) > 0)
                        THEN
                            -- сохраним итоговоую сумму для контроля
                            l_salvestatud_summa_kokku = l_salvestatud_summa_kokku + tulemus.summa;

                            if i = 1 then
                                l_pohi_dok_id = l_dok_id;
                            else
                                l_ettemaksu_dok_ids = array_append(l_ettemaksu_dok_ids, l_dok_id);
                            end if;

                            if v_puudumine.id = l_puudumise_id then
                                -- результат будет только для того отсутствия, которое задано в параметрах
                                result = l_pohi_dok_id;
                            end if;

                            -- если расчет был для отпускных, то дополнительно считаем налоги
                            if v_puudumine.puudumiste_liik in ('PUHKUS') then

                                -- расчет соц. налога
                                perform palk.gen_puhkuse_sm(user_id,
                                                            jsonb_build_object('leping_id', v_kesk_palk.leping_id,
                                                                               'kpv', l_kpv,
                                                                               'dokprop_id', l_dokprop_id,
                                                                               'palk_oper_id', l_dok_id
                                                            )
                                        );


                                perform palk.gen_puhkuse_tkm(user_id,
                                                             jsonb_build_object('leping_id', v_kesk_palk.leping_id,
                                                                                'kpv',
                                                                                l_kpv, 'dokprop_id',
                                                                                l_dokprop_id,
                                                                                'palk_oper_id', l_dok_id
                                                             ));
                            end if;

                            if v_puudumine.puudumiste_liik in ('PUHKUS') or v_kesk_palk.eri_arvestus then

                                -- расчет налогов
                                select
                                    array_agg(pk.libid)
                                into l_libs_ids
                                from
                                    palk.palk_kaart             pk
                                        inner join libs.library l on l.id = pk.libid
                                where
                                      pk.lepingid = v_kesk_palk.leping_id
                                  and pk.status = 1
                                  and (l.properties::jsonb ->> 'liik')::integer in
                                          --( 2, 3, 4, 7, 8);
                                      (
                                          select
                                              unnest('{2, 3, 4, 7, 8}'::integer[])
                                          union all
                                          -- если отдельный расчет, то добавляем соц. налог
                                          select
                                              unnest('{5}'::integer[])
                                          where
                                              v_kesk_palk.eri_arvestus
                                      );


                                -- готовим параметры

                                if l_libs_ids is not null then

                                    SELECT
                                        row_to_json(row)
                                    INTO l_params
                                    FROM
                                        (
                                            SELECT
                                                array_append(l_leping_ids, v_kesk_palk.leping_id)                    AS leping_ids,
                                                l_libs_ids                                                           AS lib_ids,
                                                array []::integer[]                                                  as isik_ids,
                                                array []::integer[]                                                  as osakond_ids,
                                                l_kpv                                                                AS kpv,
                                                null::date                                                           as maksekpv,
                                                v_palk_oper.dokpropid                                                AS dokprop,
                                                FALSE                                                                AS is_delete_prev_oper,
                                                false                                                                as kas_arvesta_minsots,
                                                (v_puudumine.puudumiste_liik::text = 'PUHKUS')::boolean              as kas_puhkused,
                                                case when v_kesk_palk.eri_arvestus then l_puudumise_id else null end as puudumine_id,
                                                case when v_kesk_palk.eri_arvestus then l_dok_id else null end       as palk_oper_id
                                        ) row;

                                    PERFORM palk.gen_palkoper(user_id, l_params:: JSON);
                                end if;

                                --  вернем значение параметров расчета обратно
                                l_params_kpv1 = (params ->> 'kpv1')::date;
                                l_params_kpv2 = (params ->> 'kpv2')::date;
                            end if;

                            -- сохраним ссылку на операцию
                            if l_pohi_dok_id is not null and not kas_arvestus_salvestatud /*and exists
                            (
                                select
                                    1
                                from
                                    palk.palk_oper
                                where
                                    parentid = l_pohi_dok_id
                            )*/ then
                                l_arvetuse_properties = jsonb_build_object('ettemaksud_ids', l_ettemaksu_dok_ids,
                                                                           'algorithm', v_kesk_palk.algorithm,
                                                                           'amet', v_kesk_palk.amet,
                                                                           'avg_paeva_summa', l_avg_paeva_summa,
                                                                           'arv_paevad_perioodis',
                                                                           l_arv_paevad_perioodis,
                                                                           'arvestatud_paevad',
                                                                           v_puudumine.arvestatud_paevad,
                                                                           'kokkuleppe_summa', l_kokkuleppe_summa,
                                                                           'puhkuse_summa', v_kesk_palk.puhkuse_summa,
                                                                           'selg', l_selg,
                                                                           'allikas', v_kesk_palk.allikas,
                                                                           'tegev', v_kesk_palk.tegev,
                                                                           'artikkel', v_kesk_palk.artikkel,
                                                                           'tunnus', v_kesk_palk.tunnus,
                                                                           'konto', v_kesk_palk.konto,
                                                                           'kpv1', v_puudumine.params_kpv1::date,
                                                                           'kpv2', v_puudumine.params_kpv2::date,
                                                                           'vm_kpv', l_kohustuse_alg_paev,
                                                                           'data', v_kesk_palk.data
                                                        );

                                update palk.puudumine
                                set
                                    properties = coalesce(properties, '{}'::jsonb) || l_arvetuse_properties
                                where
                                    id = l_puudumise_id;
                                kas_arvestus_salvestatud = true;

                            end if;

                        else
                            result = 0;
                            error_code = 9;
                            error_message = 'Viga: palgaoperatsioon salvestamine ebaõnnestus ';
                            raise exception '%', error_message;
                        END IF;
                    END IF;

                END LOOP;
            --periods
            --контроля итоговой суммы
            if l_salvestatud_summa_kokku <> v_kesk_palk.puhkuse_summa then
                raise exception 'Viga: salvestatud summa <> arvestatud summa ( % vs %)', l_salvestatud_summa_kokku, v_kesk_palk.puhkuse_summa;

            end if;
            -- обнулим итоговую сумму
            l_salvestatud_summa_kokku = 0;
        end loop;
    -- kesk palk arvestus

    -- сохраним итоговую ссфлку на операцию
    update palk.puudumine
    set
        properties = properties || jsonb_build_object('palk_oper_id', l_pohi_dok_id)
    where
        id = l_puudumise_id;


    select
        p.properties ->> 'palk_oper_id'
    into l_dok_id
    from
        palk.puudumine p
    where
        p.id = l_puudumise_id;

    RETURN;
END ;
$BODY$ LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_oper(user_id INTEGER, params JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.gen_puhkuse_oper(user_id INTEGER, params JSONB) TO dbpeakasutaja;


/*
SELECT * from palk.gen_puhkuse_oper(2477, '{
   "kpv": "20251031",
   "leping_id": 28310,
   "summa": 998.70,
   "tegev": "01112",
   "allikas": "60",
   "artikkel": "5001",
   "tunnus": "",
   "puudumise_id": 152070,
   "kas_kustuta": true,
   "algorithm":"Kokkuleppe summa",
   "kokkuleppe_summa": 2297.00,
   "amet":"Direktor",
   "avg_paeva_summa":99.87,
   "arv_paevad_perioodis":8,
   "selg":"Period: 01.10.2025-10.10.2025kuu tööpäevad:23 periodi tööpäevad:8",
   "kpv1":"20250301",
   "kpv2":"20250831",
   "vm_kpv":"20250929"
    }'::jsonb)

*/