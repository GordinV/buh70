DROP FUNCTION IF EXISTS palk.calc_avg_income_vacation(INTEGER, params JSON);

CREATE OR
    REPLACE FUNCTION palk.calc_avg_income_vacation(IN user_id INTEGER, IN params JSON)
    RETURNS TABLE
            (
                algorithm            varchar(100),
                selg                 TEXT,
                avg_paeva_summa      NUMERIC,
                arv_paevad_perioodis INTEGER,
                leping_id            INTEGER,
                allikas              varchar(20),
                tegev                varchar(20),
                artikkel             varchar(20),
                tunnus               varchar(20),
                isik_id              INTEGER,
                isik                 varchar(254),
                amet                 varchar(254),
                error_code           INTEGER,
                result               INTEGER,
                error_message        TEXT,
                data                 JSONB
            )
AS
$BODY$
DECLARE
    l_isik_id        INTEGER = params ->> 'isik_id';
    l_lopp_kpv       DATE    = coalesce((params ->> 'lopp_kpv') :: DATE, current_date);
    l_alg_kpv        DATE    = coalesce((params ->> 'alg_kpv') :: DATE, (l_lopp_kpv - interval '6 month'));
    l_rekvid         INTEGER = (select u.rekvid
                                from ou.userid u
                                where u.id = user_id
                                limit 1);
    l_puudumine_id   integer = params ->> 'puudumine_id'; -- for calculation algorithm continue salary
    l_pohi_leping_id integer;
    l_jsonb_params   jsonb;
    l_puudumise_kpv1 date;
    l_puudumise_kpv2 date;

BEGIN

    if l_puudumine_id is null then
        -- if no parameter, we will look for id to realise this algorith (temporaryly)
/*        l_puudumine_id = (select id
                          from palk.puudumine p
                          where kpv1 > l_lopp_kpv
                            and p.lepingid in (select id
                                               from palk.tooleping t
                                               where t.rekvid = l_rekvid
                                                 and (t.lopp is null or t.lopp >= l_lopp_kpv)
                                                 and t.parentid = l_isik_id)
                          order by p.kpv2 desc
                          limit 1);
*/
        with po as (select (po.properties ->> 'puudumise_id')::integer as puudumise_id
                    from palk.palk_oper po
                    where lepingid in (select id from palk.tooleping t where t.parentid = l_isik_id)
                      and po.rekvid = l_rekvid
                      and kpv >= l_lopp_kpv::date
                      and po.properties ->> 'puudumise_id' is not null)
        select p.id, p.lepingid, p.kpv1, p.kpv2
        into l_puudumine_id, l_pohi_leping_id, l_puudumise_kpv1, l_puudumise_kpv2
        from palk.puudumine p
        where p.kpv1 > l_lopp_kpv
--          and kpv2 <= l_lopp_kpv
          and p.lepingid in (select id
                             from palk.tooleping t
                             where t.rekvid = l_rekvid
                               and (t.lopp is null or t.lopp >= l_lopp_kpv)
                               and t.parentid = l_isik_id)
          and p.status <> 'deleted'
          and p.id not in (select puudumise_id
                           from po)
        order by p.kpv1, p.id
        limit 1;

        -- все уже насчитано, неет свободных отпусков, берем последний
        if l_puudumine_id is null then
            select p.id, p.lepingid, p.kpv1, p.kpv2
            into l_puudumine_id, l_pohi_leping_id, l_puudumise_kpv1, l_puudumise_kpv2
            from palk.puudumine p
            where kpv1 > l_lopp_kpv
              and kpv1 < gomonth(l_lopp_kpv, 2)
--          and kpv2 <= l_lopp_kpv
              and p.lepingid in (select id
                                 from palk.tooleping t
                                 where t.rekvid = l_rekvid
                                   and (t.lopp is null or t.lopp >= l_lopp_kpv)
                                   and t.parentid = l_isik_id)
              and p.status <> 'deleted'
            order by p.kpv1 desc, p.id
            limit 1;
        end if;
    end if;

    raise notice 'l_puudumine_id %, l_isik_id %, l_lopp_kpv %',l_puudumine_id, l_isik_id, l_lopp_kpv;

    -- готовим параментры
    l_jsonb_params = jsonb_build_object(
            'alg_kpv', l_puudumise_kpv1,
            'lopp_kpv', l_puudumise_kpv2);

    -- уменьшаем дни за счет отпусков и т.д.
    RETURN QUERY
        with params as
                 (with puudumine as (select month(p.kpv1) as kuu,
                                            year(p.kpv2)  as aasta,
                                            p.kpv1        as puudumise_alg_kpv,
                                            p.kpv2        as puudumise_lopp_kpv,
                                            p.lepingid
                                     from palk.puudumine p
                                     where p.id = l_puudumine_id)
                  select (select puudumise_alg_kpv from puudumine)  as puudumise_alg_kpv,
                         (select puudumise_lopp_kpv from puudumine) as puudumise_lopp_kpv,
                         l_alg_kpv::date                            as kpv1,
                         l_lopp_kpv::date                           as kpv2,
                         l_isik_id                                  as isik_id,
                         l_pohi_leping_id                           as leping_id,
                         l_puudumine_id                             as puudumine_id,
                         l_rekvid                                   as rekv_id,
                         month(l_alg_kpv)                           as kuu,
                         year(l_alg_kpv)                            as aasta),
             pohi_leping as (select t.id, t.algab as pohi_leping_algus
                             from palk.tooleping t,
                                  params p
                             where t.parentid = p.isik_id
                                 and t.rekvid = p.rekv_id
                                 and t.lopp is null
                                or t.lopp > p.puudumise_alg_kpv
                                 and t.status < 3
                             order by t.algab, t.palk
                             limit 1),

             lepingud as (select tl.id,
                                 pl.pohi_leping_algus as algab,
                                 tl.lopp,
                                 case
                                     when pl.pohi_leping_algus > p.kpv1 then pl.pohi_leping_algus
                                     else p.kpv1 end  as perioodi_alg, -- Если работник проработал у работодателя менее шести календарных месяцев, средняя заработная плата исчисляется исходя из календарных месяцев, за которые работнику наступил срок выплаты заработной платы.
                                 p.kpv2               as perioodi_lopp,
                                 (select count(id)
                                  from cur_tahtpaevad t
                                  where rekvid = 63 -- беру данные фин. департамента
                                    and make_date(t.aasta, t.kuu, t.paev) between
                                      case when pohi_leping_algus > p.kpv1 then pohi_leping_algus else p.kpv1 end::date
                                      and p.kpv2)     as pidu_paevad_kokku,
                                 tl.palk              as palk

                          from palk.tooleping tl,
                               pohi_leping pl,
                               params p
                          where tl.parentid = p.isik_id
--                            and tl.id = p.leping_id
                            and tl.rekvid = p.rekv_id
                            and (tl.lopp is null
                              or tl.lopp >= p.kpv1::date)
                            and tl.status < 3),
             puudumised as (with puudumiste_paevad as (select p.lepingid,
                                                              t.vs_kooded,
                                                              case when params.kpv1 > p.kpv1 then params.kpv1 else p.kpv1 end::date                                                                                                                       as alg_puudumise_kpv, -- дата начала отсутствия с поправкой на период расчета
                                                              case when params.kpv2 < p.kpv2 then params.kpv2 else p.kpv2 end                                                                                                                             AS lopp_puudumise_kpv,
                                                              (select count(id)
                                                               from cur_tahtpaevad t
                                                               where rekvid = 63 -- беру данные фин. департамента
                                                                 and make_date(t.aasta, t.kuu, t.paev) between case when params.kpv1 > p.kpv1 then params.kpv1 else p.kpv1 end::date and case when params.kpv2 < p.kpv2 then params.kpv2 else p.kpv2 end) as pidu_paevad_puhkusel

                                                       from palk.puudumine p
                                                                inner join lepingud l on l.id = p.lepingid
                                                                inner join palk.com_puudumiste_tyyp t
                                                                           on t.id = p.tyyp and t.liik = p.puudumiste_liik,
                                                            params
                                                       where p.kpv1 < params.kpv2::date
--                                                         and p.lepingid = params.leping_id
                                                         and p.status <> 'deleted'
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
                                                                 'K', 'M'])
                            select pp.lepingid,
                                   array_agg(to_char(pp.alg_puudumise_kpv, 'DD.MM.YYYY') || ' - ' ||
                                             to_char(pp.lopp_puudumise_kpv, 'DD.MM.YYYY')::text ||
                                             ', paevad:' ||
                                             ((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                              pidu_paevad_puhkusel)::text) as periods,
                                   sum((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                       pidu_paevad_puhkusel)               as puudumiste_paevad
                            from puudumiste_paevad pp
                            group by pp.lepingid),
             paevad as (select l.id                                          as lepingid,
                               l.perioodi_alg,
                               l.perioodi_lopp,
                               coalesce(p.puudumiste_paevad, 0)              as puudumised,
                               coalesce(array_to_string(p.periods, ','), '') as puudumiste_periods,
                               l.pidu_paevad_kokku                           as pidu_paevad,
                               (l.perioodi_lopp - l.perioodi_alg) + 1        as kalendri_paevad,
                               (l.perioodi_lopp - l.perioodi_alg) + 1 - coalesce(p.puudumiste_paevad, 0) -
                               l.pidu_paevad_kokku                           as arvestatud_paevad
                        from lepingud l
                                 left outer join puudumised p on l.id = p.lepingid),
             arveldus as (select a.algoritm,
                                 a.lepingid,
                                 sum(a.summa_kokku)            as summa_kokku,
                                 array_agg(a.used_palk_koodid) as used_palk_koodid,
                                 a.tegev,
                                 a.allikas,
                                 a.artikkel,
                                 a.tunnus
                          from (
                                   -- начисления , которые идут в расчет
                                   select 'Arveldus'             as algoritm,
                                          po.lepingid,
                                          (po.summa)             as summa_kokku,
                                          ltrim(rtrim(lib.kood)) as used_palk_koodid,
                                          po.kood1               as tegev,
                                          po.kood2               as allikas,
                                          po.kood5               as artikkel,
                                          po.tunnus              as tunnus
                                   from palk.palk_oper po
                                            inner join lepingud l on l.id = po.lepingid
                                       and po.kpv >= l.perioodi_alg and po.kpv <= l.perioodi_lopp
                                            inner join libs.library lib on lib.id = po.libid
                                       and (lib.properties::jsonb ->> 'liik')::integer = 1,
                                        params p
                                   where po.summa <> 0
                                     and po.properties ->> 'paranduse_kpv' is null
--                                     and po.lepingid = l_pohi_leping_id
                                     and po.konto in (SELECT unnest(p.pohi_palk_kontod)
                                                      from palk.palk_kulu_kontod p
                                                      union
                                                      SELECT unnest(p.lisa_tasud_kontod)
                                                      from palk.palk_kulu_kontod p
                                                      union
                                                      SELECT unnest(p.preemiad_kontod)
                                                      from palk.palk_kulu_kontod p)
                                   -- korrigeerimised
                                   union all
                                   select 'Arveldus'             as algoritm,
                                          po.lepingid,
                                          (po.summa)             as summa_kokku,
                                          ltrim(rtrim(lib.kood)) as used_palk_koodid,
                                          po.kood1               as tegev,
                                          po.kood2               as allikas,
                                          po.kood5               as artikkel,
                                          po.tunnus              as tunnus
                                   from palk.palk_oper po
                                            inner join lepingud l on l.id = po.lepingid
                                            inner join libs.library lib on lib.id = po.libid
                                       and (lib.properties::jsonb ->> 'liik')::integer = 1
                                   where po.summa <> 0
--                                     and po.lepingid = l_pohi_leping_id
                                     and po.properties ->> 'paranduse_kpv' is not null
                                     and (po.properties ->> 'paranduse_kpv')::date >= l.perioodi_alg
                                     and (po.properties ->> 'paranduse_kpv')::date <= l.perioodi_lopp
                                     and po.konto in (SELECT unnest(p.pohi_palk_kontod)
                                                      from palk.palk_kulu_kontod p
                                                      union
                                                      SELECT unnest(p.lisa_tasud_kontod)
                                                      from palk.palk_kulu_kontod p
                                                      union
                                                      SELECT unnest(p.preemiad_kontod)
                                                      from palk.palk_kulu_kontod p)
/*                            union all
                            -- вычитания (отпускные)
                            select
                                po.lepingid,
                                -1 * (po.summa)        as summa_kokku,
                                ltrim(rtrim(lib.kood)) as used_palk_koodid,
                                po.kood1               as tegev,
                                po.kood2               as allikas,
                                po.kood5               as artikkel,
                                po.tunnus              as tunnus
                            from
                                palk.palk_oper              po
                                    inner join lepingud     l on l.id = po.lepingid
                                    and po.kpv >= l.perioodi_alg and po.kpv <= l.perioodi_lopp
                                    inner join libs.library lib on lib.id = po.libid
                                    and (lib.properties::jsonb ->> 'liik')::integer = 1,
                                params                      p
                            where
                                  po.summa <> 0
                              and po.konto in (
                                                  SELECT
                                                      unnest(p.puhkused_kontod)
                                                  from
                                                      palk.palk_kulu_kontod p
                                              )
*/
                               ) a
                          group by a.lepingid, a.tegev, a.allikas, a.artikkel, a.tunnus, a.algoritm),
             -- gродолжение ЗП
             palk_leping_ as (select l.id                                                    as leping_id,
                                     p.period_start,
                                     p.period_finish,
                                     p.work_days_in_period,
                                     p.work_days_in_month,
                                     sum(p.work_days_in_period) over (partition by l.id)     as arv_days,
                                     params.puudumise_alg_kpv,
                                     params.puudumise_lopp_kpv,
                                     l.palk,
                                     (l.palk / p.work_days_in_month) * p.work_days_in_period as arv_palk,
                                     'Period: ' || to_char(p.period_start, 'DD.MM.YYYY') || '-' ||
                                     to_char(p.period_finish, 'DD.MM.YYYY') || 'kuu tööpäevad:' ||
                                     p.work_days_in_month::text ||
                                     ' periodi tööpäevad:' || p.work_days_in_period::text    as selg
                              from lepingud l,
                                   params,
                                   palk.fnc_get_periodis_from_date_range(l_jsonb_params) p
                              where l_puudumine_id is not null)

        select qry.algoritm,
               qry.selg,
               qry.avg_paeva_summa,
               qry.arv_paevad_perioodis,
               qry.leping_id,
               coalesce(qry.allikas, 'LE-P')::varchar(20) as allikas,
               qry.tegev,
               qry.artikkel,
               qry.tunnus,
               a.id                                       as isik_id,
               a.nimetus::varchar(254)                    as isik,
               amet.nimetus::varchar(254)                 as amet,
               0:: INTEGER                                as error_code,
               1:: INTEGER                                as result,
               null::text                                 as error_message,
               details::jsonb                             as data

        from (select a.algoritm::varchar(100)                                                     as algoritm,
                     'Kalendri päevad periodis:' || p.kalendri_paevad::text || ' pidupäavad:' || p.pidu_paevad::text ||
                     ' puudumised:' || p.puudumiste_periods ||
                     ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                     array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text as selg,
                     round(a.summa_kokku / p.arvestatud_paevad, 2):: NUMERIC                      as avg_paeva_summa,
                     p.arvestatud_paevad::integer                                                 as arv_paevad_perioodis,
                     a.lepingid:: INTEGER                                                         as leping_id,
                     a.allikas:: varchar(20)                                                      as allikas,
                     a.tegev:: varchar(20)                                                        as tegev,
                     a.artikkel:: varchar(20)                                                     as artikkel,
                     a.tunnus:: varchar(20)                                                       as tunnus,
                     null::jsonb                                                                  as details
              from arveldus a
                       inner join paevad p on p.lepingid = a.lepingid
              where p.arvestatud_paevad > 0
              union all
              select *
              from (with libs as (select max(l.properties::jsonb ->> 'allikas')              as allikas,
                                         max(l.properties::jsonb ->> 'tegev')                as tegev,
                                         max(l.properties::jsonb ->> 'artikkel')             as artikkel,
                                         max(coalesce(l.properties::jsonb ->> 'tunnus', '')) as tunnus,
                                         pk.lepingid,
                                         max(pk.summa)                                       as summa,
                                         max(pk.percent_)
                                  from palk.palk_kaart pk
                                           inner join libs.library l on pk.libid = l.id
                                  where lepingid in (select l.id from lepingud l)
                                    and (l.properties::jsonb ->> 'liik')::integer = 1
                                    and l.properties::jsonb ->> 'konto' in (select unnest(pohi_palk_kontod)
                                                                            from palk.palk_kulu_kontod)
                                    and pk.status = 1
                                  group by pk.lepingid)
                    select 'Palk'::varchar(100)                        as algoritm,
                           array_to_string(a.selg, ',')                as selg,
                           round(a.arv_palk / a.arv_days, 2):: NUMERIC as avg_paeva_summa,
                           a.arv_days::integer                         as arv_paevad_perioodis,
                           a.leping_id:: INTEGER                       as leping_id,
                           coalesce(libs.allikas, ''):: varchar(20)    as allikas,
                           coalesce(libs.tegev, ''):: varchar(20)      as tegev,
                           coalesce(libs.artikkel, ''):: varchar(20)   as artikkel,
                           coalesce(libs.tunnus, ''):: varchar(20)     as tunnus,
                           a.details
                    from (select p.leping_id,
                                 array_agg(p.selg)                             as selg,
                                 sum(p.arv_palk)                               as arv_palk,
                                 max(p.arv_days)                               as arv_days,
                                 jsonb_agg(jsonb_build_object('summa', round(p.arv_palk, 2), 'paevad',
                                                              p.work_days_in_period, 'period_start',
                                                              p.period_start)) as details
                          from palk_leping_ p
                          group by p.leping_id) a
                             left outer join libs on libs.lepingid = a.leping_id
                    where a.arv_days > 0) qry) qry
                 inner join palk.tooleping t on t.id = qry.leping_id
                 inner join libs.asutus a on a.id = t.parentid
                 inner join libs.library amet on amet.id = t.ametid;


END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

select *
from palk.calc_avg_income_vacation(4711::INTEGER, '{
  "alg_kpv": "2025-01-01",
  "lopp_kpv": "2025-05-31",
  "isik_id": 30752
}':: JSON) a


/*
select *
from
    palk.calc_avg_income_vacation(2477::INTEGER, '{
      "alg_kpv": "2025-01-01",
      "lopp_kpv": "2025-05-31",
      "isik_id": 28624
    }':: JSON)
order by avg_paeva_summa desc

*/
