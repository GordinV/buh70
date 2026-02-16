DROP FUNCTION IF EXISTS palk.calc_avg_income_vacation(INTEGER, params JSON);

--tahtpaevad
CREATE OR
    REPLACE FUNCTION palk.calc_avg_income_vacation(IN user_id INTEGER, IN params JSON)
    RETURNS TABLE
            (
                algorithm            varchar(100),
                selg                 TEXT,
                avg_paeva_summa      NUMERIC(12, 2),
                puhkuse_summa        NUMERIC(12, 2),
                arv_paevad_perioodis INTEGER,
                leping_id            INTEGER,
                konto                varchar(20),
                allikas              varchar(20),
                tegev                varchar(20),
                artikkel             varchar(20),
                tunnus               varchar(20),
                projekt              varchar(20),
                isik_id              INTEGER,
                isik                 varchar(254),
                amet                 varchar(254),
                eri_arvestus         boolean,
                error_code           INTEGER,
                result               INTEGER,
                error_message        TEXT,
                data                 JSONB
            )
AS
$BODY$
DECLARE
    l_isik_id                 INTEGER = params ->> 'isik_id';
    l_lopp_kpv                DATE    = coalesce((params ->> 'lopp_kpv') :: DATE, current_date);
    l_alg_kpv                 DATE    = coalesce((params ->> 'alg_kpv') :: DATE, (l_lopp_kpv - interval '6 month'));
    l_rekvid                  INTEGER = (
                                            select
                                                u.rekvid
                                            from
                                                ou.userid u
                                            where
                                                u.id = user_id
                                            limit 1
                                        );
    l_puudumine_id            integer = params ->> 'puudumine_id'; -- for calculation algorithm continue salary
    l_kokkulepe_summa         numeric = params ->> 'kokkulepe_summa'; -- сумма по договоренности
    l_pohi_leping_id          integer;
    l_jsonb_params            jsonb;
    l_jsonb_periods           jsonb;
    l_puudumise_kpv1          date;
    l_puudumise_kpv2          date;
    l_puudumise_paevad        integer = 0;
    l_vs_kooded               text[]; -- коды отсутсвий согласно вирософту для определения алгоритма расчета
    l_keskpalk_puhata_koodid  text[]  = '{ÕP}'; -- коды, для которых актуален расчет среднего
    l_keskpalk_koodid         text[]  = '{AP,  P, IP, LPA,  PL}'; -- коды, для которых актуален расчет среднего
    l_keskpalk_haiguse_koodid text[]  = '{H, PIH}'; -- коды, для которых актуален расчет среднего
    l_keskpalk_toopaev_koodid text[]  = '{K, VK, AT}'; -- коды, для которых актуален расчет среднего
    l_palk_koodid             text[]  = '{P,TL, V}'; -- коды, для которых актуален расчет алгоритма продолжение ЗП
    l_kokkulepe_koodid        text[]  = '{P,K, PL, V,AT, TL}'; -- коды, для которых актуален расчет по договоренности
    l_minpalk_koodid          text[]  = '{ÕP}'; -- коды, для которых актуален расчет по договоренности
    kas_eametnik              boolean = false; -- вычисляем, является ли этот работник чиновником
    l_min_palk                numeric = (
                                            select
                                                coalesce(palk_miinium, 886)
--                                                minpalk
                                            from
                                                palk.palk_config
                                            where
                                                  rekvid = 63
                                              and status = 'active'
                                            limit 1
                                        ); -- получаем константу мин ЗП для алгоритмов ÕP
    l_muud                    text ;
    l_puudumise_tyyp          integer; -- тип отсутствия
    l_puudumise_persent       numeric = 100;

BEGIN

    -- ищем отсутствие, для которого идет расчет
    if l_puudumine_id is null then
        -- if no parameter, we will look for id to realise this algorith (temporaryly)

        with
            po as (
                      select
                          (po.properties ->> 'puudumise_id')::integer as puudumise_id
                      from
                          palk.palk_oper po
                      where
                            lepingid in (
                                            select
                                                id
                                            from
                                                palk.tooleping t
                                            where
                                                t.parentid = l_isik_id
                                        )
                        and po.rekvid = l_rekvid
                        and kpv >= l_lopp_kpv::date
                        and po.properties ->> 'puudumise_id' is not null
            )
        select
            p.id,
            p.lepingid,
            p.kpv1,
            p.kpv2,
            pt.vs_kooded,
            p.muud,
            p.tyyp,
            coalesce(pt.protsenti, 100)
        into l_puudumine_id, l_pohi_leping_id, l_puudumise_kpv1, l_puudumise_kpv2, l_vs_kooded, l_muud, l_puudumise_tyyp, l_puudumise_persent
        from
            palk.puudumine                               p
                left outer join palk.com_puudumiste_tyyp pt on pt.liik = p.puudumiste_liik and pt.id = p.tyyp

        where
              p.kpv1 > l_lopp_kpv
          and p.lepingid in (
                                select
                                    id
                                from
                                    palk.tooleping t
                                where
                                      t.rekvid = l_rekvid
                                  and (t.lopp is null or t.lopp >= l_lopp_kpv)
                                  and t.parentid = l_isik_id
                            )
          and p.status <> 'deleted'
          and p.id not in (
                              select
                                  puudumise_id
                              from
                                  po
                          )
        order by p.kpv1, p.id
        limit 1;

        -- все уже насчитано, неет свободных отпусков, берем последний
        if l_puudumine_id is null then
            select
                p.id,
                p.lepingid,
                p.kpv1,
                p.kpv2,
                pt.vs_kooded,
                p.muud,
                p.tyyp,
                coalesce(pt.protsenti, 100)
            into l_puudumine_id, l_pohi_leping_id, l_puudumise_kpv1, l_puudumise_kpv2, l_vs_kooded, l_muud, l_puudumise_tyyp, l_puudumise_persent
            from
                palk.puudumine                               p
                    left outer join palk.com_puudumiste_tyyp pt on pt.liik = p.puudumiste_liik and pt.id = p.tyyp
            where
                  kpv1 > l_lopp_kpv
              and kpv1 < gomonth(l_lopp_kpv, 2)
              and p.lepingid in (
                                    select
                                        id
                                    from
                                        palk.tooleping t
                                    where
                                          t.rekvid = l_rekvid
                                      and (t.lopp is null or t.lopp >= l_lopp_kpv)
                                      and t.parentid = l_isik_id
                                )
              and p.status <> 'deleted'
            order by p.kpv1 desc, p.id
            limit 1;
        end if;
    else
        select
            p.lepingid,
            p.kpv1,
            p.kpv2,
            p.paevad,
            pt.vs_kooded,
            p.muud,
            p.tyyp,
            coalesce(pt.protsenti, 100)
        into l_pohi_leping_id, l_puudumise_kpv1, l_puudumise_kpv2,l_puudumise_paevad, l_vs_kooded, l_muud, l_puudumise_tyyp, l_puudumise_persent
        from
            palk.puudumine                               p
                left outer join palk.com_puudumiste_tyyp pt on pt.liik = p.puudumiste_liik and pt.id = p.tyyp
        where
            p.id = l_puudumine_id;
    end if;

    -- готовим параментры
    l_jsonb_params = jsonb_build_object(
            'alg_kpv', l_puudumise_kpv1,
            'lopp_kpv', l_puudumise_kpv2);

    -- массив периодов
    l_jsonb_periods = jsonb_agg(to_jsonb(p))
                      from
                          palk.fnc_get_periodis_from_date_range(l_jsonb_params) p;

    -- уменьшаем дни за счет отпусков и т.д.
    RETURN QUERY
        with
            puudumine as (
                             select
                                 id,
                                 month(p.kpv1)                                                       as kuu,
                                 year(p.kpv2)                                                        as aasta,
                                 p.kpv1                                                              as puudumise_alg_kpv,
                                 p.kpv2                                                              as puudumise_lopp_kpv,
                                 p.lepingid,
                                 month(case
                                           when year(l_alg_kpv) <> year(l_Lopp_kpv)
                                               then make_date(year(l_alg_kpv), 12, 31)
                                           else l_lopp_kpv end) - month(l_alg_kpv) +
                                 1                                                                   as aasta_preemia_kuued,
                                 l_alg_kpv::date                                                     as alg_kpv,
                                 l_lopp_kpv                                                          as lopp_kpv,
                                 p.paevad                                                            as puudumise_paevad,
                                 coalesce((p.properties ->> 'arvestatud_paevad')::integer, p.paevad) as arvestatud_paevad,
                                 (p.properties ->> 'arvestatud_paevad_j')::integer                   as arvestatud_paevad_j,
                                 (p.properties ->> 'allikas_e')                                      as allikas_e,
                                 (p.properties ->> 'allikas_j')                                      as allikas_j,
                                 p.puudumiste_liik,
                                 p.tyyp
                             from
                                 palk.puudumine p
                             where
                                 p.id = l_puudumine_id
                         ),
            params as
                (
                             select
                                 p.puudumise_alg_kpv,
                                 p.puudumise_lopp_kpv,
                                 p.alg_kpv::date  as kpv1,
                                 p.lopp_kpv::date as kpv2,
                                 l_isik_id        as isik_id,
                                 l_pohi_leping_id as leping_id,
                                 p.id             as puudumine_id,
                                 l_rekvid         as rekv_id,
                                 month(p.alg_kpv) as kuu,
                                 year(p.alg_kpv)  as aasta,
                                 p.aasta_preemia_kuued,
                                 p.puudumise_paevad
                             from
                                 puudumine p
                         ),
            periods as (
                             with
                                 period as (
                                               select
                                                   to_char(generate_series(
                                                                   p.kpv1, -- начальная дата
                                                                   p.kpv2, -- конечная дата
                                                                   INTERVAL '1 month' -- шаг: 1 месяц
                                                           )::date, 'YYYY-MM') as period
                                               from
                                                   params p
                                 )
                             select
                                 p.period,
                                 (palk.get_work_days(json_build_object('kuu',
                                                                       right(p.period, 2)::INTEGER,
                                                                       'aasta',
                                                                       left(p.period, 4)::INTEGER,
                                                                       'lepingid', null) ::JSON)) as toopaevad,
                                 (palk.get_days_of_month_in_period(right(p.period, 2)::INTEGER,
                                                                   left(p.period, 4)::INTEGER,
                                                                   null::date,
                                                                   null::date))                   as kalendripaevad,
                                 (palk.get_days_of_month_in_period(right(p.period, 2)::INTEGER,
                                                                   left(p.period, 4)::INTEGER,
                                                                   null::date,
                                                                   null::date, true, true,
                                                                   true))                         as puhad

                             from
                                 period p

                         ),
            pohi_leping as (
                             select
                                 t.id,
                                 t.algab   as pohi_leping_algus,
                                 t.ametnik as kas_ametnik
                             from
                                 palk.tooleping t,
                                 params         p
                             where
                                  t.parentid = p.isik_id
                                      and t.rekvid = p.rekv_id
                                      and t.lopp is null
                               or t.lopp > p.puudumise_alg_kpv
                                      and t.status < 3
                             order by t.algab, t.palk
                             limit 1
                         ),

            lepingud as (
                             select
                                 tl.id,
                                 pl.pohi_leping_algus        as algab,
                                 tl.lopp,
                                 case
                                     when pl.pohi_leping_algus > p.kpv1 then pl.pohi_leping_algus
                                     else p.kpv1 end         as perioodi_alg, -- Если работник проработал у работодателя менее шести календарных месяцев, средняя заработная плата исчисляется исходя из календарных месяцев, за которые работнику наступил срок выплаты заработной платы.
                                 p.kpv2                      as perioodi_lopp,
                                 (
                                     select
                                         count(id)
                                     from
                                         cur_tahtpaevad t
                                     where
                                         make_date(t.aasta, t.kuu, t.paev) between
                                             case
                                                 when pohi_leping_algus > p.kpv1 then pohi_leping_algus
                                                 else p.kpv1 end::date
                                             and p.kpv2
                                 )                           as pidu_paevad_kokku,
                                 tl.palk * tl.koormus * 0.01 as palk,
                                 p.aasta_preemia_kuued

                             from
                                 palk.tooleping tl,
                                 pohi_leping    pl,
                                 params         p
                             where
                                   tl.id = p.leping_id
                               and tl.rekvid = p.rekv_id
                               and (tl.lopp is null or tl.lopp >= p.kpv1::date)
                               and coalesce(tl.lopp, p.kpv2) >= p.kpv1
                               and tl.status < 3
                         ),
            puudumised_periodi_jargi as (
                             select
                                 max(period)                     as period,
                                 max(lepingid)                   as lepingid,
                                 max(liik)                       as liik,
                                 max(periods)                    as periods,
                                 sum(periodi_puudumiste_paevad)  as periodi_puudumiste_paevad,
                                 sum(pidu_paevad_puudumisel)     as pidu_paevad_puudumisel,
                                 sum(periodi_puhkuse_paevad)     as periodi_puhkuse_paevad,
                                 sum(periodi_haiguse_paevad)     as periodi_haiguse_paevad,
                                 sum(p.periodi_koolituse_paevad) as periodi_koolituse_paevad,
                                 sum(periodi_muud_paevad)        as periodi_muud_paevad,
                                 sum(kalendripaevad)             as kalendripaevad,
                                 sum(toopaevad)                  as toopaevad,
                                 sum(puhad)                      as puhad
                             from
                                 (
                                     with
                                         puudumiste_paevad as (
                                                                  select
                                                                      p.lepingid,
                                                                      t.vs_kooded,
                                                                      case when params.kpv1 > p.kpv1 then params.kpv1 else p.kpv1 end::date as alg_puudumise_kpv, -- дата начала отсутствия с поправкой на период расчета
                                                                      case when params.kpv2 < p.kpv2 then params.kpv2 else p.kpv2 end       AS lopp_puudumise_kpv,
                                                                      (
                                                                          select
                                                                              count(id)
                                                                          from
                                                                              cur_tahtpaevad t
                                                                          where
                                                                              make_date(t.aasta, t.kuu, t.paev) between case when params.kpv1 > p.kpv1 then params.kpv1 else p.kpv1 end::date and case when params.kpv2 < p.kpv2 then params.kpv2 else p.kpv2 end
                                                                      )                                                                     as pidu_paevad_puhkusel,
                                                                      p.katkestuse_paevad,
                                                                      p.katkestuse_toopaevad,
                                                                      to_char(
                                                                              case when params.kpv1 > p.kpv1 then params.kpv1 else p.kpv1 end::date,
                                                                              'YYYY-MM')                                                    as period,
                                                                      p.pohjus                                                              as liik
                                                                  from
                                                                      palk.cur_puudumine                      p
                                                                          inner join lepingud                 l on l.id = p.lepingid
                                                                          inner join palk.com_puudumiste_tyyp t
                                                                                     on t.id = p.tyyp and t.liik::text = p.pohjus::text,
                                                                                                              params
                                                                  where
                                                                        p.kpv1 < params.kpv2::date
--                                                         and p.lepingid = params.leping_id
                                                                    and create_date_range(p.kpv1, case
                                                                                                      when p.kpv2 = p.kpv1
                                                                                                          then p.kpv2 + 1
                                                                                                      else p.kpv2 end) &&
                                                                        create_date_range(params.kpv1, params.kpv2)
                                                                    and t.vs_kooded <@
                                                                        array ['P','A', 'AP', 'AT', 'EMP', 'IP', 'LHP', 'LP', 'LPA', 'MTV', 'PIH', 'PL', 'PLP', 'TE', 'TLP', 'TP', 'V', 'VK', 'VP', 'ÕP',
                                                                            'AH','H', 'HD', 'HL', 'HP', 'PH',
                                                                            'STR',
                                                                            'EKK',
                                                                            'K', 'M']
                                         )
                                     select
                                         pp.period,
                                         pp.lepingid,
                                         array_agg(pp.liik)                                                             as liik,
                                         array_agg(to_char(pp.alg_puudumise_kpv, 'DD.MM.YYYY') || ' - ' ||
                                                   to_char(pp.lopp_puudumise_kpv, 'DD.MM.YYYY')::text ||
                                                   ', paevad:' ||
                                                   ((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                                    pidu_paevad_puhkusel -
                                                    pp.katkestuse_toopaevad)::text)                                     as periods,
                                         sum((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                             pidu_paevad_puhkusel -
                                             pp.katkestuse_toopaevad)                                                   as periodi_puudumiste_paevad,
                                         sum(pidu_paevad_puhkusel)                                                      as pidu_paevad_puudumisel,
                                         sum(case
                                                 when pp.liik = 'PUHKUS' then (
                                                     (pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                                     pidu_paevad_puhkusel - pp.katkestuse_toopaevad)
                                                 else 0 end)                                                            as periodi_puhkuse_paevad,
                                         sum(case
                                                 when pp.liik = 'HAIGUS' then (
                                                     (pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                                     pidu_paevad_puhkusel - pp.katkestuse_toopaevad)
                                                 else 0 end)                                                            as periodi_haiguse_paevad,
                                         sum(case
                                                 when pp.liik = 'KOOLITUS' then (
                                                     (pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                                     pidu_paevad_puhkusel - pp.katkestuse_toopaevad)
                                                 else 0 end)                                                            as periodi_koolituse_paevad,

                                         sum(case
                                                 when pp.liik not in ('HAIGUS', 'PUHKUS', 'KOOLITUS') then (
                                                     (pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                                     pidu_paevad_puhkusel - pp.katkestuse_toopaevad)
                                                 else 0 end)                                                            as periodi_muud_paevad,
                                         0                                                                              as kalendripaevad,
                                         sum(-1 * palk.get_work_days(jsonb_build_object('alg_kpv', pp.alg_puudumise_kpv,
                                                                                        'lopp_kpv',
                                                                                        pp.lopp_puudumise_kpv):: JSON)) as toopaevad,
                                         0                                                                              as puhad
                                     from
                                         puudumiste_paevad pp
                                     group by pp.lepingid, pp.period
                                     union all
                                     select
                                         p.period,
                                         0    as lepingid,
                                         null as liik,
                                         null as periods,
                                         0    as periodi_puudumiste_paevad,
                                         0    as pidu_paevad_puudumisel,
                                         0    as periodi_puhkuse_paevad,
                                         0    as periodi_haiguse_paevad,
                                         0    as periodi_koolituse_paevad,
                                         0    as periodi_muud_paevad,
                                         p.kalendripaevad,
                                         p.toopaevad,
                                         p.puhad
                                     from
                                         periods p
                                 ) p
                             group by p.period
                             order by p.period
                         ),
            -- убрал группировку по догорам чтобы схлопнуть расчет рабюдней
            puudumised as (
                             select
                                 max(coalesce(pp.lepingid, 0))            as lepingid,
                                 array_agg(array_to_string(periods, '.')) as periods,
                                 sum(periodi_puudumiste_paevad)           as puudumiste_paevad,
                                 sum(pp.toopaevad)                        as toopaevad
                             from
                                 puudumised_periodi_jargi pp
                         ),

            paevad as (
                             select
                                 l.id                                          as lepingid,
                                 l.perioodi_alg,
                                 l.perioodi_lopp,
                                 coalesce(p.puudumiste_paevad, 0)              as puudumised,
                                 coalesce(array_to_string(p.periods, ','), '') as puudumiste_periods,
                                 l.pidu_paevad_kokku                           as pidu_paevad,
                                 (l.perioodi_lopp - l.perioodi_alg) + 1        as kalendri_paevad,
                                 (l.perioodi_lopp - l.perioodi_alg) + 1 - coalesce(p.puudumiste_paevad, 0) -
                                 l.pidu_paevad_kokku                           as arvestatud_paevad,
                                 p.toopaevad,
                                 (l.perioodi_lopp - l.perioodi_alg) + 1 -
                                 coalesce(p.puudumiste_paevad, 0)              as kal_paevad_puhata
                             from
                                 lepingud                       l
                                     left outer join puudumised p on l.id = p.lepingid
                         ),
            kontod as (
                             with
                                 puudumise_kontod as (
                                                         select
                                                             kood                                                as konto,
                                                             (l.properties::jsonb ->> 'puudumise_tyyp')::integer as puudumise_tyyp,
                                                             (
                                                                 select
                                                                     case
                                                                         when (konto_tyyp ->> 'puhkuse_konto')::boolean
                                                                             then 'PUHKUS'
                                                                         when (konto_tyyp ->> 'haiguse_konto')::boolean
                                                                             then 'HAIGUS'
                                                                         when (konto_tyyp ->> 'lisatasu_konto')::boolean
                                                                             then 'LISATASU'
                                                                         when (konto_tyyp ->> 'koolituse_konto')::boolean
                                                                             then 'KOOLITUS'
                                                                         else 'MUUD'
                                                                         END::varchar(20)
                                                                 from
                                                                     libs.get_konto_laiendus(l.kood::text) as konto_tyyp
                                                             )                                                   as konto_tyyp
                                                         from
                                                             libs.library l
                                                         where
                                                               l.library = 'KONTOD'
                                                           and status < 3
                                                               -- только счета ЗП
--                                                           and l.kood like '500%'
                                                           and l.kood in (
                                                                             select
                                                                                 kontod.konto
                                                                             from
                                                                                 (
                                                                                     select distinct
                                                                                         l.properties::jsonb ->> 'konto' as konto
                                                                                     from
                                                                                         libs.library l,
                                                                                         params       p
                                                                                     where
                                                                                           l.library = 'PALK'
                                                                                       and status < 3
                                                                                       and l.rekvid = p.rekv_id
                                                                                       and l.properties::jsonb ->> 'liik' = '1'
                                                                                 ) kontod
                                                                             where
                                                                                   kontod.konto is not null
                                                                               and not empty(kontod.konto)
                                                                               and kontod.konto not like ('202%')

                                                                         )
                                 )

                             select distinct
                                 max(l.properties::jsonb ->> 'konto') as konto,
                                 pk.lepingid
                             FROM
                                 palk.cur_palk_kaart         pk
                                     inner join libs.library l on pk.libid = l.id,
                                 puudumine                   p
                             where
                                   -- только начисления
                                   l.properties::jsonb ->> 'liik' = '1'
                                   -- только конто заданного отсутствия
                               and l.properties::jsonb ->> 'konto' in (
                                                                          select
                                                                              k.konto
                                                                          from
                                                                              puudumise_kontod k
                                                                          where
                                                                              --приведем все типы учебного отпуска к типу номер 5
                                                                              (k.puudumise_tyyp is null or
                                                                               k.puudumise_tyyp in (
                                                                                                       select
                                                                                                           p.tyyp
                                                                                                       union all
                                                                                                       select
                                                                                                           case when p.tyyp = 50 then 5 end::integer
                                                                                                       where
                                                                                                           p.tyyp = 50

                                                                                                       union all
                                                                                                       select
                                                                                                           case when p.tyyp = 51 then 5 end::integer
                                                                                                       where
                                                                                                           p.tyyp = 51
                                                                                                   )
                                                                                  )
                                                                      )

                               and l.properties::jsonb ->> 'konto' in (
                                                                          select
                                                                              unnest(puhkused_kontod)
                                                                          from
                                                                              palk.     palk_kulu_kontod,
                                                                              puudumine p
                                                                          where
                                                                                p.puudumiste_liik::text = 'PUHKUS'
                                                                            and p.tyyp not in (5, 50, 51, 7, 9, 11, 14, 15) --за исключением учебного отпуска
                                                                          UNION ALL
                                                                          -- vabapaev
                                                                          select
                                                                              (pkk.konto)
                                                                          from
                                                                              (
                                                                                  select
                                                                                      unnest(puhkused_kontod) as konto
                                                                                  from
                                                                                      palk.palk_kulu_kontod
                                                                              )         pkk,
                                                                              puudumine p
                                                                          where
                                                                                p.puudumiste_liik::text = 'PUHKUS'
                                                                            and p.tyyp in (14, 15) -- свободный день
                                                                            and pkk.konto like '%002'

                                                                          UNION ALL
                                                                          select
                                                                              unnest(koolitus_kontod)
                                                                          from
                                                                              palk.     palk_kulu_kontod,
                                                                              puudumine p
                                                                          where
                                                                              p.puudumiste_liik::text = 'KOOLITUS'
                                                                          UNION ALL
                                                                          --komandeering
                                                                          select
                                                                              unnest(pohi_palk_kontod)
                                                                          from
                                                                              palk.     palk_kulu_kontod,
                                                                              puudumine p
                                                                          where
                                                                              p.puudumiste_liik::text = 'KOMANDEERING'
                                                                          union all
                                                                          select
                                                                              '103560'::text
                                                                          from
                                                                              puudumine p
                                                                          where
                                                                                p.puudumiste_liik::text = 'PUHKUS'
                                                                            and p.tyyp in (7, 9)
                                                                          union all
                                                                          --õppepuhkus
                                                                          select
                                                                              pkk.konto::text
                                                                          from
                                                                              (
                                                                                  select
                                                                                      unnest(puhkused_kontod) as konto
                                                                                  from
                                                                                      palk.palk_kulu_kontod
                                                                              )         pkk,
                                                                              puudumine p
                                                                          where
                                                                                pkk.konto like '%23'
                                                                            and p.puudumiste_liik::text = 'PUHKUS'
                                                                            and p.tyyp in (5, 50, 51)
                                                                          union all
                                                                          -- Puudega täisealise isiku hooldaja puhkus
                                                                          select
                                                                              pkk.konto::text
                                                                          from
                                                                              (
                                                                                  select
                                                                                      unnest(huvitised_kontod) as konto
                                                                                  from
                                                                                      palk.palk_kulu_kontod
                                                                              )         pkk,
                                                                              puudumine p
                                                                          where
                                                                                pkk.konto like '%701'
                                                                            and p.puudumiste_liik::text = 'PUHKUS'
                                                                            and p.tyyp = 11
                                                                          union all
                                                                          -- haigus
                                                                          select
                                                                              pkk.konto::text
                                                                          from
                                                                              (
                                                                                  select
                                                                                      unnest(pk.huvitised_kontod) as konto
                                                                                  from
                                                                                      palk.palk_kulu_kontod pk
                                                                              )         pkk,
                                                                              puudumine p
                                                                          where
                                                                                pkk.konto like '%701'
                                                                            and p.puudumiste_liik::text = 'HAIGUS'
                                                                            and p.tyyp = 1

                                                                      )
                               and pk.lepingid in (
                                                      select
                                                          id
                                                      from
                                                          lepingud
                                                  )
                               AND pk.status < 3
                             group by pk.lepingid
                         ),
            arveldus_periodi_jargi as (
                             select
                                 'Arveldus'                    as algoritm,
                                 a.lepingid,
                                 array_agg(a.used_palk_koodid) as used_palk_koodid,
                                 a.konto,
                                 a.tegev,
                                 a.allikas,
                                 a.artikkel,
                                 a.tunnus,
                                 max(a.projekt)                as projekt,
                                 coalesce(a.period, p.period)  as period,
                                 sum(coalesce(a.summa, 0))     as summa
                             from
                                 periods p
                                     left outer join
                                     (
                                         -- начисления , которые идут в расчет
                                         select
                                             po.lepingid,
                                             (po.summa)                                        as summa,
                                             ltrim(rtrim(lib.kood))                            as used_palk_koodid,
                                             po.kood1                                          as tegev,
                                             po.kood2                                          as allikas,
                                             po.kood5                                          as artikkel,
                                             coalesce(case
                                                          when empty(po.tunnus) then lib.properties::jsonb ->> 'tunnus'
                                                          else po.tunnus end, '')::varchar(20) as tunnus,
                                             po.proj                                           as projekt,
                                             TO_CHAR(po.kpv, 'YYYY-MM')                        as period,
                                             po.konto
                                         from
                                             palk.palk_oper              po
                                                 inner join lepingud     l
                                                            on l.id = po.lepingid
                                                                and po.kpv >= l.perioodi_alg and
                                                               po.kpv <= l.perioodi_lopp
                                                 inner join libs.library lib on lib.id = po.libid
                                                 and (lib.properties::jsonb ->> 'liik')::integer = 1,
                                             params                      p

                                         where
                                               po.summa <> 0
                                           and po.properties ->> 'paranduse_kpv' is null
--                                     and po.lepingid = l_pohi_leping_id
                                           and po.konto in (
                                                               SELECT
                                                                   unnest(
                                                                           p.pohi_palk_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                               union
                                                               SELECT
                                                                   unnest(
                                                                           p.lisa_tasud_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                               union
                                                               SELECT
                                                                   unnest(
                                                                           p.preemiad_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                           )
                                         -- korrigeerimised
                                         union all
                                         select
                                             po.lepingid,
                                             (
                                                 po.summa)                                                 as summa_kokku,
                                             ltrim(
                                                     rtrim(
                                                             lib.kood))                                    as used_palk_koodid,
                                             po.kood1                                                      as tegev,
                                             po.kood2                                                      as allikas,
                                             po.kood5                                                      as artikkel,
--                                po.tunnus                  as tunnus,
                                             coalesce(case
                                                          when empty(po.tunnus) then lib.properties::jsonb ->> 'tunnus'
                                                          else po.tunnus end, '')::varchar(20)             as tunnus,

                                             po.proj                                                       as projekt,
                                             TO_CHAR((po.properties ->> 'paranduse_kpv')::date, 'YYYY-MM') as period,
                                             po.konto

                                         from
                                             palk.palk_oper              po
                                                 inner join lepingud     l
                                                            on l.id = po.lepingid
                                                 inner join libs.library lib on lib.id = po.libid
                                                 and (lib.properties::jsonb ->> 'liik')::integer = 1
                                         where
                                               po.summa <> 0
--                                     and po.lepingid = l_pohi_leping_id
                                           and po.properties ->> 'paranduse_kpv' is not null
                                           and (
                                                   po.properties ->> 'paranduse_kpv')::date >= l.perioodi_alg
                                           and (
                                                   po.properties ->> 'paranduse_kpv')::date <= l.perioodi_lopp
                                           and po.konto in (
                                                               SELECT
                                                                   unnest(
                                                                           p.pohi_palk_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                               union
                                                               SELECT
                                                                   unnest(
                                                                           p.lisa_tasud_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                               union
                                                               SELECT
                                                                   unnest(
                                                                           p.preemiad_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                           )
                                         union all
                                         -- aasta preemiad
                                         -- начисления , которые идут в расчет
                                         select
                                             po.lepingid,
                                             round((po.summa / 12) * p.aasta_preemia_kuued, 2) as summa_kokku,
                                             ltrim(
                                                     rtrim(
                                                             lib.kood))                        as used_palk_koodid,
                                             po.kood1                                          as tegev,
                                             po.kood2                                          as allikas,
                                             po.kood5                                          as artikkel,
                                             coalesce(case
                                                          when empty(po.tunnus) then lib.properties::jsonb ->> 'tunnus'
                                                          else po.tunnus end, '')::varchar(20) as tunnus,
                                             po.proj                                           as projekt,
                                             TO_CHAR(po.kpv, 'YYYY-MM')                        as period,
                                             po.konto

                                         from
                                             palk.palk_oper              po
                                                 inner join lepingud     l
                                                            on l.id = po.lepingid
                                                                and po.kpv >= l.perioodi_alg and
                                                               po.kpv <= l.perioodi_lopp
                                                 inner join libs.library lib on lib.id = po.libid
                                                 and (lib.properties::jsonb ->> 'liik')::integer = 1,
                                             params                      p
                                         where
                                               po.summa <> 0
                                           and p.aasta_preemia_kuued
                                                   > 0
                                           and po.properties ->> 'paranduse_kpv' is null
--                                     and po.lepingid = l_pohi_leping_id
                                           and po.konto in (
                                                               SELECT
                                                                   unnest(
                                                                           p.aasta_preemiad_kontod)
                                                               from
                                                                   palk.palk_kulu_kontod p
                                                           )

                                     )   a on p.period = a.period
                             --,details
                             group by
                                 a.lepingid, a.konto, coalesce(a.period, p.period), a.tegev, a.allikas, a.artikkel,
                                 a.tunnus --, a.algoritm , a.projekt
                         ),
            arveldus as (
                             select
                                 a.algoritm,
                                 a.lepingid,
                                 max(a.konto)                                        as konto,
                                 a.tegev,
                                 a.allikas,
                                 a.artikkel,
                                 a.tunnus,
                                 a.projekt,
                                 array_agg(array_to_string(a.used_palk_koodid, ',')) as used_palk_koodid,
                                 sum(a.summa)                                        as summa_kokku,
                                 jsonb_agg(jsonb_build_object('period', a.period,
                                                              'summa', summa,
                                                              'konto', a.konto,
                                                              'toopaevad', p.toopaevad::integer,
                                                              'kalendripaevad', p.kalendripaevad::integer,
                                                              'puhad', p.puhad,
                                                              'puhkus', p.periodi_puhkuse_paevad,
                                                              'haigus', p.periodi_haiguse_paevad,
                                                              'koolitus', p.periodi_koolituse_paevad,
                                                              'muud_puudumised', p.periodi_muud_paevad
                                           ))                                        as lisa,
                                 l_jsonb_periods                                     as details

                             from
                                 arveldus_periodi_jargi                       a
                                     left outer join puudumised_periodi_jargi p on p.period = a.period
                             where
                                 coalesce(summa, 0) <> 0
                             -- только для заданных видов отсутствия
                             --,details
                             group by
                                 a.lepingid, a.tegev, a.allikas, a.artikkel, a.tunnus, a.algoritm,
                                 a.projekt -- ,a.konto,
                         ),

            -- gродолжение ЗП
            palk_leping_ as (
                             with
                                 palk as (
                                             select
                                                 l.id as leping_id,
                                                 params.puudumise_alg_kpv,
                                                 params.puudumise_lopp_kpv,
                                                 l.palk,
                                                 (
                                                     select
                                                         kuu_summa
                                                     from
                                                         libs.proj_laiendus          pl
                                                             inner join libs.library p on p.id = pl.proj_id
                                                     where
                                                           pl.leping_id = l.id
                                                       and (p.properties::JSONB ->> 'proj_kuni')::DATE >= current_date
                                                       and p.kood in (
                                                                         select
                                                                             l.properties::JSONB ->> 'proj'
                                                                         from
                                                                             palk.palk_kaart             pk
                                                                                 inner join libs.library l on l.id = pk.libid
                                                                         where
                                                                               pk.lepingid = l.id
                                                                           and l.properties::JSONB ->> 'proj' is not null
                                                                     )
                                                     order by (p.properties::jsonb ->> 'proj_alates')::date desc
                                                     limit 1
                                                 )    as proj_palk

                                             from
                                                 lepingud l,
                                                          params
                                 )


                             select
                                 palk.leping_id                                                as leping_id,
                                 p.period_start,
                                 p.period_finish,
                                 p.work_days_in_period,
                                 p.work_days_in_month,
                                 sum(p.work_days_in_period) over (partition by palk.leping_id) as arv_days,
                                 palk.puudumise_alg_kpv,
                                 palk.puudumise_lopp_kpv,
                                 coalesce(palk.proj_palk, palk.palk)                           as palk,
                                 round((coalesce(palk.proj_palk, palk.palk) / p.work_days_in_month), 2) *
                                 p.work_days_in_period                                         as arv_palk,
                                 'Period: ' || to_char(p.period_start, 'DD.MM.YYYY') || '-' ||
                                 to_char(p.period_finish, 'DD.MM.YYYY') || 'kuu tööpäevad:' ||
                                 p.work_days_in_month::text ||
                                 ' periodi tööpäevad:' || p.work_days_in_period::text          as selg
                             from
                                 palk,
--                                 params,
                                 palk.fnc_get_periodis_from_date_range(l_jsonb_params) p
                             where
                                   l_puudumine_id is not null
                                   -- только для заданных видов отсутствия
                               and l_palk_koodid @> l_vs_kooded
                         ),
            -- по договоренности
            kokkuleppe_summa as (
                             select
                                 l.id                                                 as leping_id,
                                 p.period_start,
                                 p.period_finish,
                                 p.work_days_in_period,
                                 p.work_days_in_month,
                                 sum(p.work_days_in_period) over (partition by l.id)  as arv_days,
                                 params.puudumise_alg_kpv,
                                 params.puudumise_lopp_kpv,
                                 l_kokkulepe_summa,
                                 round((l_kokkulepe_summa / p.work_days_in_month), 2) *
                                 p.work_days_in_period                                as arv_palk,
                                 'Period: ' || to_char(p.period_start, 'DD.MM.YYYY') || '-' ||
                                 to_char(p.period_finish, 'DD.MM.YYYY') || 'kuu tööpäevad:' ||
                                 p.work_days_in_month::text ||
                                 ' periodi tööpäevad:' || p.work_days_in_period::text as selg
                             from
                                 lepingud                                              l,
                                                                                       params,
                                 palk.fnc_get_periodis_from_date_range(l_jsonb_params) p
                             where
                                   l_puudumine_id is not null
                                   -- только для заданных видов отсутствия
                               and l_kokkulepe_koodid @> l_vs_kooded
                               and l_kokkulepe_summa is not null

                         ),
            -- по договоренности
            miinimumpalk as (
                             select
                                 l.id                                                 as leping_id,
                                 p.period_start,
                                 p.period_finish,
                                 p.work_days_in_period,
                                 p.work_days_in_month,
                                 sum(p.work_days_in_period) over (partition by l.id)  as arv_days,
                                 params.puudumise_alg_kpv,
                                 params.puudumise_lopp_kpv,
                                 l_min_palk                                           as summa,
                                 round((l_min_palk / p.work_days_in_month), 2) *
                                 p.work_days_in_period                                as arv_palk,
                                 'Period: ' || to_char(p.period_start, 'DD.MM.YYYY') || '-' ||
                                 to_char(p.period_finish, 'DD.MM.YYYY') || 'kuu tööpäevad:' ||
                                 p.work_days_in_month::text ||
                                 ' periodi tööpäevad:' || p.work_days_in_period::text as selg
                             from
                                 lepingud                                              l,
                                                                                       params,
                                 palk.fnc_get_periodis_from_date_range(l_jsonb_params) p
                             where
                                   l_puudumine_id is not null
                                   -- только для заданных видов отсутствия
                               and l_minpalk_koodid @> l_vs_kooded
                                   -- только для учебных отпусков
                               and case
                                       when '{ÕP}' @> l_vs_kooded and l_puudumise_tyyp = 50
                                           then true
                                       when '{ÕP}' @> l_vs_kooded and l_puudumise_tyyp = 51
                                           then false
                                       when not '{ÕP}' @> l_vs_kooded
                                           then true
                                       else false
                                       end

                         )


        select
            qry.algoritm,
            qry.selg,
            qry.avg_paeva_summa,
            qry.puhkuse_summa,
            qry.arv_paevad_perioodis,
            qry.leping_id,
            coalesce(k.konto, '')::varchar(20)         as konto,
            coalesce(qry.allikas, 'LE-P')::varchar(20) as allikas,
            qry.tegev,
            qry.artikkel,
            qry.tunnus,
            qry.projekt,
            a.id                                       as isik_id,
            a.nimetus::varchar(254)                    as isik,
            amet.nimetus::varchar(254)                 as amet,
            qry.eri_arvestus                           as eri_arvestus,
            0:: INTEGER                                as error_code,
            1:: INTEGER                                as result,
            null::text                                 as error_message,
            qry.details::jsonb                         as data

        from
            (
                -- Tööandja 2-3 день, Tööandja 4-8 день  Sotsiaalkindlustusamet с 9 дня
                -- määr 70%
                select
                    'Arveldus (70%, teisel päeval)' ::varchar(100)                               as algoritm,
                    'Kalendripäevad ilma pühata periodis:' || p.kal_paevad_puhata::text ||
                    ' puudumised:' || p.puudumiste_periods ||
                    ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                    array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text as selg,
                    0.01 * l_puudumise_persent *
                    round(a.summa_kokku / p.kal_paevad_puhata, 2):: NUMERIC(12, 2)               as avg_paeva_summa,
                    (0.01 * l_puudumise_persent * round((a.summa_kokku / p.kal_paevad_puhata), 2) *
                     pd.arvestatud_paevad):: NUMERIC(12, 2)                                      as puhkuse_summa,
                    p.kal_paevad_puhata::integer                                                 as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                         as leping_id,
                    coalesce(pd.allikas_e, a.allikas):: varchar(20)                              as allikas,
                    a.tegev:: varchar(20)                                                        as tegev,
                    a.artikkel:: varchar(20)                                                     as artikkel,
                    a.tunnus:: varchar(20)                                                       as tunnus,
                    a.projekt:: varchar(20)                                                      as projekt,
                    jsonb_build_object('details', a.details, 'lisa', a.lisa)::jsonb              as details,
                    false                                                                        as eri_arvestus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params,
                    puudumine             pd
                where
                      p.kal_paevad_puhata > 0
                  and l_keskpalk_haiguse_koodid @> l_vs_kooded
                union all
                -- доп. источник, если задан
                select
                    'Arveldus (70%, teisel päeval)' ::varchar(100)                               as algoritm,
                    'Päevad ilma pühata periodis:' || p.kal_paevad_puhata::text ||
                    ' puudumised:' || p.puudumiste_periods ||
                    ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                    array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text as selg,
                    0.7 * round(a.summa_kokku / p.kal_paevad_puhata, 2):: NUMERIC(12, 2)         as avg_paeva_summa,
                    (0.7 * round((a.summa_kokku / p.kal_paevad_puhata), 2) *
                     pd.arvestatud_paevad_j):: NUMERIC(12, 2)                                    as puhkuse_summa,
                    p.kal_paevad_puhata::integer                                                 as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                         as leping_id,
                    coalesce(pd.allikas_j, a.allikas):: varchar(20)                              as allikas,
                    a.tegev:: varchar(20)                                                        as tegev,
                    a.artikkel:: varchar(20)                                                     as artikkel,
                    a.tunnus:: varchar(20)                                                       as tunnus,
                    a.projekt:: varchar(20)                                                      as projekt,
                    jsonb_build_object('details', a.details, 'lisa', a.lisa)::jsonb              as details,
                    true                                                                         as eri_arvestus

                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params,
                    puudumine             pd
                where
                      p.kal_paevad_puhata > 0
                  and l_keskpalk_haiguse_koodid @> l_vs_kooded
                  and coalesce(pd.arvestatud_paevad_j, 0) > 0
                union all
                -- ручной расчет

                select
                    'Arveldus (käsitsi)' ::varchar(100)                             as algoritm,
                    '' ::text                                                       as selg,
                    0.01 * l_puudumise_persent *
                    round(a.summa_kokku / p.kal_paevad_puhata, 2):: NUMERIC(12, 2)  as avg_paeva_summa,
                    (0.01 * l_puudumise_persent * round((a.summa_kokku / p.kal_paevad_puhata), 2) *
                     pd.arvestatud_paevad):: NUMERIC(12, 2)                         as puhkuse_summa,
                    pd.arvestatud_paevad::integer ::integer                         as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                            as leping_id,
                    '':: varchar(20)                                                as allikas,
                    '':: varchar(20)                                                as tegev,
                    '':: varchar(20)                                                as artikkel,
                    '':: varchar(20)                                                as tunnus,
                    '':: varchar(20)                                                as projekt,
                    jsonb_build_object('details', a.details, 'lisa', a.lisa)::jsonb as details,
                    false                                                           as eri_arvestus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params,
                    puudumine             pd
                where
                    l_keskpalk_haiguse_koodid @> l_vs_kooded

                union all

                -- средний за календарный дни без праздников
                select
                    'Arveldus (v.a. pühad)' ::varchar(100)                                       as algoritm,
                    'Kalendripäevad ilma pühata periodis:' || p.kal_paevad_puhata::text ||
                    ' puudumised:' || p.puudumiste_periods ||
                    ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                    array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text as selg,
                    round(a.summa_kokku / p.kal_paevad_puhata, 2):: NUMERIC                      as avg_paeva_summa,
                    (round((a.summa_kokku / p.kal_paevad_puhata), 2) *
                     params.puudumise_paevad)::numeric(12, 2)                                    as puhkuse_summa,
                    p.kal_paevad_puhata::integer                                                 as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                         as leping_id,
                    a.allikas:: varchar(20)                                                      as allikas,
                    a.tegev:: varchar(20)                                                        as tegev,
                    a.artikkel:: varchar(20)                                                     as artikkel,
                    a.tunnus:: varchar(20)                                                       as tunnus,
                    a.projekt:: varchar(20)                                                      as projekt,
                    jsonb_build_object('details', a.details, 'lisa', a.lisa)::jsonb              as details,
                    false                                                                        as eri_arvestus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params
                where
                      p.kal_paevad_puhata > 0
                  and l_keskpalk_puhata_koodid @> l_vs_kooded
                      -- только для учебных отпусков
                  and case
                          when '{ÕP}' @> l_vs_kooded and l_puudumise_tyyp = 5
                              then true
                          when not '{ÕP}' @> l_vs_kooded
                              then true
                          else false
                          end
                union all

                select
                    'Arveldus (tööpäev)' ::varchar(100)                                                 as algoritm,
                    'Tööpäevad periodis:' || p.toopaevad::text ||
                    ' puudumised:' || p.puudumiste_periods ||
                    ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                    array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text        as selg,
                    round(a.summa_kokku / p.toopaevad, 2):: NUMERIC                                     as avg_paeva_summa,
                    (round((a.summa_kokku / p.toopaevad), 2) * params.puudumise_paevad)::numeric(12, 2) as puhkuse_summa,
                    p.toopaevad::integer                                                                as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                                as leping_id,
                    a.allikas:: varchar(20)                                                             as allikas,
                    a.tegev:: varchar(20)                                                               as tegev,
                    a.artikkel:: varchar(20)                                                            as artikkel,
                    a.tunnus:: varchar(20)                                                              as tunnus,
                    a.projekt:: varchar(20)                                                             as projekt,
                    jsonb_build_object('details', a.details, 'lisa', a.lisa)::jsonb                     as details,
                    false                                                                               as eri_arvestus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params
                where
                      p.arvestatud_paevad > 0
                  and l_keskpalk_toopaev_koodid @> l_vs_kooded

                union all

                select
                    'Arveldus'::varchar(100)                                                     as algoritm,
                    'Kalendri päevad periodis:' || p.kalendri_paevad::text || ' pidupäavad:' || p.pidu_paevad::text ||
                    ' puudumised:' || p.puudumiste_periods ||
                    ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                    array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text as selg,
                    round(a.summa_kokku / p.arvestatud_paevad, 2):: NUMERIC                      as avg_paeva_summa,
                    (round((a.summa_kokku / p.arvestatud_paevad), 2) *
                     params.puudumise_paevad)::numeric(12, 2)                                    as puhkuse_summa,
                    p.arvestatud_paevad::integer                                                 as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                         as leping_id,
                    a.allikas:: varchar(20)                                                      as allikas,
                    a.tegev:: varchar(20)                                                        as tegev,
                    a.artikkel:: varchar(20)                                                     as artikkel,
                    a.tunnus:: varchar(20)                                                       as tunnus,
                    a.projekt:: varchar(20)                                                      as projekt,
                    jsonb_build_object('details', a.details, 'lisa', a.lisa)::jsonb              as details,
                    false                                                                        as eri_arvestus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params
                where
                      p.arvestatud_paevad > 0
                  and l_keskpalk_koodid @> l_vs_kooded
                union all

                select
                    'Arveldus (käsitsi)'::varchar(100)                                         as algoritm,
                    '' ::text                                                                  as selg,
                    sum(round(a.summa_kokku / p.arvestatud_paevad, 2)):: NUMERIC               as avg_paeva_summa,
                    sum((round((a.summa_kokku / p.arvestatud_paevad), 2) *
                         params.puudumise_paevad))::numeric(12, 2)                             as puhkuse_summa,
                    params.puudumise_paevad::integer                                           as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                       as leping_id,
                    '':: varchar(20)                                                           as allikas,
                    '':: varchar(20)                                                           as tegev,
                    '':: varchar(20)                                                           as artikkel,
                    '':: varchar(20)                                                           as tunnus,
                    '':: varchar(20)                                                           as projekt,
                    jsonb_agg(jsonb_build_object('details', a.details, 'lisa', a.lisa))::jsonb as details,
                    false                                                                      as eri_arvestus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid,
                                          params
                where
                      p.arvestatud_paevad > 0
                  and l_keskpalk_koodid @> l_vs_kooded
                group by a.lepingid, params.puudumise_paevad

                union
                --продолжение ЗП
                select *
                from
                    (
                        with
                            libs as (
                                        select
                                            max(l.properties::jsonb ->> 'allikas')                     as allikas,
                                            max(l.properties::jsonb ->> 'tegev')                       as tegev,
                                            max(l.properties::jsonb ->> 'artikkel')                    as artikkel,
                                            max(coalesce(l.properties::jsonb ->> 'tunnus', pk.tunnus)) as tunnus,
                                            max(coalesce(l.properties::jsonb ->> 'proj', ''))          as projekt,
                                            pk.lepingid,
                                            max(pk.summa)                                              as summa,
                                            max(pk.percent_)
                                        from
                                            palk.palk_kaart             pk
                                                inner join libs.library l on pk.libid = l.id
                                        where
                                              lepingid in (
                                                              select
                                                                  l.id
                                                              from
                                                                  lepingud l
                                                          )
                                          and (l.properties::jsonb ->> 'liik')::integer = 1
                                          and l.properties::jsonb ->> 'konto' in (
                                                                                     select
                                                                                         unnest(pohi_palk_kontod)
                                                                                     from
                                                                                         palk.palk_kulu_kontod
                                                                                 )
                                          and pk.status = 1
                                        group by pk.lepingid
                            )
                        select
                            'Palk'::varchar(100)                        as algoritm,
                            array_to_string(a.selg, ',')                as selg,
                            round(a.arv_palk / a.arv_days, 2):: NUMERIC as avg_paeva_summa,
                            round(a.arv_palk, 2)                        as puhkuse_summa,
                            a.arv_days::integer                         as arv_paevad_perioodis,
                            a.leping_id:: INTEGER                       as leping_id,
                            coalesce(libs.allikas, ''):: varchar(20)    as allikas,
                            coalesce(libs.tegev, ''):: varchar(20)      as tegev,
                            coalesce(libs.artikkel, ''):: varchar(20)   as artikkel,
                            coalesce(libs.tunnus, ''):: varchar(20)     as tunnus,
                            coalesce(libs.projekt, ''):: varchar(20)    as projekt,
                            a.details,
                            false                                       as eri_arvestus
                        from
                            (
                                select
                                    p.leping_id,
                                    array_agg(p.selg)                             as selg,
                                    sum(p.arv_palk)                               as arv_palk,
                                    max(p.arv_days)                               as arv_days,
                                    jsonb_agg(jsonb_build_object('summa', round(p.arv_palk, 2), 'paevad',
                                                                 p.work_days_in_period, 'period_start',
                                                                 p.period_start)) as details
                                from
                                    palk_leping_ p
                                group by p.leping_id
                            )           a
                                left outer join libs on libs.lepingid = a.leping_id,
                            pohi_leping pl
                        where
                              a.arv_days > 0
                          and case
                                  when l_vs_kooded <@ '{V}' and coalesce(pl.kas_ametnik, 0) = 1 then true
                                  when l_vs_kooded <@ '{V}' and coalesce(pl.kas_ametnik, 0) = 0 then false
                                  else true end
                    ) qry

                union
                -- kokkuleppe summa
                select *
                from
                    (
                        with
                            libs as (
                                        select
                                            max(l.properties::jsonb ->> 'allikas')                     as allikas,
                                            max(l.properties::jsonb ->> 'tegev')                       as tegev,
                                            max(l.properties::jsonb ->> 'artikkel')                    as artikkel,
                                            max(coalesce(l.properties::jsonb ->> 'tunnus', pk.tunnus)) as tunnus,
                                            max(coalesce(l.properties::jsonb ->> 'proj', ''))          as projekt,
                                            pk.lepingid,
                                            max(pk.summa)                                              as summa,
                                            max(pk.percent_)
                                        from
                                            palk.palk_kaart             pk
                                                inner join libs.library l on pk.libid = l.id
                                        where
                                              lepingid in (
                                                              select
                                                                  l.id
                                                              from
                                                                  lepingud l
                                                          )
                                          and (l.properties::jsonb ->> 'liik')::integer = 1
                                          and l.properties::jsonb ->> 'konto' in (
                                                                                     select
                                                                                         unnest(pohi_palk_kontod)
                                                                                     from
                                                                                         palk.palk_kulu_kontod
                                                                                 )
                                          and pk.status = 1
                                        group by pk.lepingid
                            )
                        select
                            'Kokkuleppe summa'::varchar(100)            as algoritm,
                            array_to_string(a.selg, ',')                as selg,
                            round(a.arv_palk / a.arv_days, 2):: NUMERIC as avg_paeva_summa,
                            round(a.arv_palk, 2)                        as puhkuse_summa,
                            a.arv_days::integer                         as arv_paevad_perioodis,
                            a.leping_id:: INTEGER                       as leping_id,
                            coalesce(libs.allikas, ''):: varchar(20)    as allikas,
                            coalesce(libs.tegev, ''):: varchar(20)      as tegev,
                            coalesce(libs.artikkel, ''):: varchar(20)   as artikkel,
                            coalesce(libs.tunnus, ''):: varchar(20)     as tunnus,
                            coalesce(libs.projekt, ''):: varchar(20)    as projekt,
                            a.details,
                            false                                       as eri_arvestus

                        from
                            (
                                select
                                    p.leping_id,
                                    array_agg(p.selg)                             as selg,
                                    sum(p.arv_palk)                               as arv_palk,
                                    max(p.arv_days)                               as arv_days,
                                    jsonb_agg(jsonb_build_object('summa', round(p.arv_palk, 2), 'paevad',
                                                                 p.work_days_in_period, 'period_start',
                                                                 p.period_start)) as details
                                from
                                    kokkuleppe_summa p
                                group by p.leping_id
                            ) a
                                left outer join libs on libs.lepingid = a.leping_id
                        where
                            a.arv_days > 0
                    ) qry
                union all
                --минимальная ЗП

                select *
                from
                    (
                        with
                            libs as (
                                        select
                                            max(l.properties::jsonb ->> 'allikas')                     as allikas,
                                            max(l.properties::jsonb ->> 'tegev')                       as tegev,
                                            max(l.properties::jsonb ->> 'artikkel')                    as artikkel,
                                            max(coalesce(l.properties::jsonb ->> 'tunnus', pk.tunnus)) as tunnus,
                                            max(coalesce(l.properties::jsonb ->> 'proj', ''))          as projekt,
                                            pk.lepingid,
                                            max(pk.summa)                                              as summa,
                                            max(pk.percent_)
                                        from
                                            palk.palk_kaart             pk
                                                inner join libs.library l on pk.libid = l.id
                                        where
                                              lepingid in (
                                                              select
                                                                  l.id
                                                              from
                                                                  lepingud l
                                                          )
                                          and (l.properties::jsonb ->> 'liik')::integer = 1
                                          and l.properties::jsonb ->> 'konto' in (
                                                                                     select
                                                                                         unnest(pohi_palk_kontod)
                                                                                     from
                                                                                         palk.palk_kulu_kontod
                                                                                 )
                                          and pk.status = 1
                                        group by pk.lepingid
                            )
                        select
                            'miinimunpalk'::varchar(100)                as algoritm,
                            array_to_string(a.selg, ',')                as selg,
                            round(a.arv_palk / a.arv_days, 2):: NUMERIC as avg_paeva_summa,
                            round(a.arv_palk, 2)                        as puhkuse_summa,
                            a.arv_days::integer                         as arv_paevad_perioodis,
                            a.leping_id:: INTEGER                       as leping_id,
                            coalesce(libs.allikas, ''):: varchar(20)    as allikas,
                            coalesce(libs.tegev, ''):: varchar(20)      as tegev,
                            coalesce(libs.artikkel, ''):: varchar(20)   as artikkel,
                            coalesce(libs.tunnus, ''):: varchar(20)     as tunnus,
                            coalesce(libs.projekt, ''):: varchar(20)    as projekt,
                            a.details,
                            false                                       as eri_arvestus
                        from
                            (
                                select
                                    p.leping_id,
                                    array_agg(p.selg)                             as selg,
                                    sum(p.arv_palk)                               as arv_palk,
                                    max(p.arv_days)                               as arv_days,
                                    jsonb_agg(jsonb_build_object('summa', round(p.arv_palk, 2), 'paevad',
                                                                 p.work_days_in_period, 'period_start',
                                                                 p.period_start)) as details
                                from
                                    miinimumpalk p
                                group by p.leping_id
                            ) a
                                left outer join libs on libs.lepingid = a.leping_id
                        where
                            a.arv_days > 0
                    ) qry


            )                                  qry
                inner join      palk.tooleping t on t.id = qry.leping_id
                inner join      libs.asutus    a on a.id = t.parentid
                inner join      libs.library   amet on amet.id = t.ametid
                left outer join kontod         k on k.lepingid = qry.leping_id;


END ;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION palk.calc_avg_income_vacation(INTEGER, params JSON) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.calc_avg_income_vacation(INTEGER, params JSON) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.calc_avg_income_vacation(INTEGER, params JSON) TO dbvaatleja;


/*
select
    data -> 'details' as details,
    *
from
    palk.calc_avg_income_vacation(2477::INTEGER, '{
   "alg_kpv": "20250501",
      "lopp_kpv": "20251031",
      "puudumine_id": 161864,
      "isik_id": 28624,
      "kokkulepe_summa":2802.00
    }')
*/

/*
++ 156785

select * from ou.rekv where nimetus ilike '%sademe%'

select * from palk.puudumine order by id desc limit 10

select * from ou.userid where kasutaja = 'vlad' and rekvid = 113

select * from libs.asutus where regkood = '37201309511 '

select * from palk.palk_kaart where lepingid = 41217

select * from palk.puudumine where lepingid = 32747 order by id desc limit 10

select * from palk.tooleping where id = 28310

select * from palk.puudumine where lepingid = 28310 and kpv1 > '2025-01-01'
select *
from
    palk.calc_avg_income_vacation_(4824::INTEGER, '{
      "alg_kpv": "2025-01-01",
      "lopp_kpv": "2025-06-30",
      "isik_id": 30885,
      "puudumine_id": 153181

    }':: JSON)
order by avg_paeva_summa desc

*/
