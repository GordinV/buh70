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
    l_isik_id  INTEGER = params ->> 'isik_id';
    l_lopp_kpv DATE    = coalesce((params ->> 'lopp_kpv') :: DATE, current_date);
    l_alg_kpv  DATE    = coalesce((params ->> 'alg_kpv') :: DATE, (l_lopp_kpv - interval '6 month'));
    l_rekvid   INTEGER = (
                             select
                                 u.rekvid
                             from
                                 ou.userid u
                             where
                                 u.id = user_id
                             limit 1
                         );

BEGIN

    /*    for v_leping in
            select
                id,
                t.algab,
                t.lopp
            from
                palk.tooleping t
            where
                  parentid = l_isik_id
              and rekvid = l_rekvid
              and (lopp is null
                or lopp >= l_alg_kpv::date)
              and status < 3

            loop
                avg_summa = 0;
                selg = 'Arvestus puudub';
                leping_id = v_leping.id;
                algorithm = 1;
                -- расчет календарных  дней в периоде, с учетом срока работы по договору
                /*
                 3.Если работник проработал у работодателя менее шести календарных месяцев, средняя заработная плата исчисляется исходя из календарных месяцев, за которые работнику наступил срок выплаты заработной платы.
                 */
                if v_leping.algab > l_alg_kpv then
                    l_alg_kpv = v_leping.algab;
                end if;
    */
    -- уменьшаем дни за счет отпусков и т.д.
    RETURN QUERY
        with
            params as
                (
                    select
                        l_alg_kpv::date  as kpv1,
                        l_lopp_kpv::date as kpv2,
                        l_isik_id        as isik_id,
                        l_rekvid         as rekv_id
                ),
            lepingud as (
                    select
                        tl.id,
                        tl.algab,
                        tl.lopp,
                        case when tl.algab > p.kpv1 then tl.algab else p.kpv1 end as perioodi_alg, -- Если работник проработал у работодателя менее шести календарных месяцев, средняя заработная плата исчисляется исходя из календарных месяцев, за которые работнику наступил срок выплаты заработной платы.
                        p.kpv2                                                    as perioodi_lopp,
                        (
                            select
                                count(id)
                            from
                                cur_tahtpaevad t
                            where
                                  rekvid = 63 -- беру данные фин. департамента
                              and make_date(t.aasta, t.kuu, t.paev) between
                                      case when tl.algab > p.kpv1 then tl.algab else p.kpv1 end::date
                                      and p.kpv2
                        )                                                         as pidu_paevad_kokku,
                        tl.palk                                                   as palk

                    from
                        palk.tooleping tl,
                        params         p
                    where
                          tl.parentid = p.isik_id
                      and tl.rekvid = p.rekv_id
                      and (tl.lopp is null
                        or tl.lopp >= p.kpv1::date)
                      and tl.status < 3

                ),
            puudumised as (
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
                                                               rekvid = 63 -- беру данные фин. департамента
                                                           and make_date(t.aasta, t.kuu, t.paev) between case when params.kpv1 > p.kpv1 then params.kpv1 else p.kpv1 end::date and case when params.kpv2 < p.kpv2 then params.kpv2 else p.kpv2 end
                                                     )                                                                     as pidu_paevad_puhkusel

                                                 from
                                                     palk.puudumine                          p
                                                         inner join lepingud                 l on l.id = p.lepingid
                                                         inner join palk.com_puudumiste_tyyp t
                                                                    on t.id = p.tyyp and t.liik = p.puudumiste_liik,
                                                                                             params
                                                 where
                                                       p.kpv1 < params.kpv2::date
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
                        pp.lepingid,
                        array_agg(to_char(pp.alg_puudumise_kpv, 'DD.MM.YYYY') || ' - ' ||
                                  to_char(pp.lopp_puudumise_kpv, 'DD.MM.YYYY')::text ||
                                  ', paevad:' ||
                                  ((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                   pidu_paevad_puhkusel)::text) as periods,
                        sum((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                            pidu_paevad_puhkusel)               as puudumiste_paevad
                    from
                        puudumiste_paevad pp
                    group by pp.lepingid

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
                        l.pidu_paevad_kokku                           as arvestatud_paevad
                    from
                        lepingud                       l
                            left outer join puudumised p on l.id = p.lepingid
                ),
            arveldus as (
                    select
                        a.algoritm,
                        a.lepingid,
                        sum(a.summa_kokku)            as summa_kokku,
                        array_agg(a.used_palk_koodid) as used_palk_koodid,
                        a.tegev,
                        a.allikas,
                        a.artikkel,
                        a.tunnus
                    from
                        (
                            -- начисления , которые идут в расчет
                            select
                                'Arveldus'             as algoritm,
                                po.lepingid,
                                (po.summa)             as summa_kokku,
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
                                                      unnest(p.pohi_palk_kontod)
                                                  from
                                                      palk.palk_kulu_kontod p
                                                  union
                                                  SELECT
                                                      unnest(p.lisa_tasud_kontod)
                                                  from
                                                      palk.palk_kulu_kontod p
                                                  union
                                                  SELECT
                                                      unnest(p.preemiad_kontod)
                                                  from
                                                      palk.palk_kulu_kontod p

                                              )


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
                    group by a.lepingid, a.tegev, a.allikas, a.artikkel, a.tunnus, a.algoritm

                ),
            -- gродолжение ЗП
            palk as (
                    select
                        'Period: ' || to_char(make_date(year(p.kpv2), month(p.kpv2), 01), 'DD.MM.YYYY') || '-' ||
                        to_char(p.kpv2, 'DD.MM.YYYY')                           as selg,
                        p.kpv2 - make_date(year(p.kpv2), month(p.kpv2), 01) + 1 as kalendri_paevad,
                        'Palk'                                                  as algoritm,
                        po.lepingid,
                        sum(po.summa)                                           as summa_kokku,
                        array_agg(ltrim(rtrim(lib.kood)))                       as used_palk_koodid,
                        po.kood1                                                as tegev,
                        po.kood2                                                as allikas,
                        po.kood5                                                as artikkel,
                        po.tunnus                                               as tunnus
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
                                              unnest(p.pohi_palk_kontod)
                                          from
                                              palk.palk_kulu_kontod p
                                          union
                                          SELECT
                                              unnest(p.lisa_tasud_kontod)
                                          from
                                              palk.palk_kulu_kontod p
                                          union
                                          SELECT
                                              unnest(p.preemiad_kontod)
                                          from
                                              palk.palk_kulu_kontod p

                                      )
                      and po.kpv >= make_date(year(p.kpv2), month(p.kpv2), 01)
                      and po.kpv <= p.kpv2
                    group by po.lepingid, po.kood1, po.kood2, po.kood5, po.tunnus, p.kpv2
                )
        select
            qry.algoritm,
            qry.selg,
            qry.avg_paeva_summa,
            qry.arv_paevad_perioodis,
            qry.leping_id,
            qry.allikas,
            qry.tegev,
            qry.artikkel,
            qry.tunnus,
            a.id                       as isik_id,
            a.nimetus::varchar(254)    as isik,
            amet.nimetus::varchar(254) as amet,
            0:: INTEGER                as error_code,
            1:: INTEGER                as result,
            null::text                 as error_message,
            null::jsonb                as data

        from
            (
                select
                    a.algoritm::varchar(100)                                                     as algoritm,
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
                    a.tunnus:: varchar(20)                                                       as tunnus
                from
                    arveldus              a
                        inner join paevad p on p.lepingid = a.lepingid
                union all
                select
                    a.algoritm::varchar(100)                                                     as algoritm,
                    a.selg || ' kalendri päevad periodis:' || a.kalendri_paevad::text ||
                    ', Arveldused kokku:' || round(a.summa_kokku, 2)::text || ' kasutatud koodid: ' ||
                    array_to_string(get_unique_value_from_array(a.used_palk_koodid), ',') ::text as selg,
                    round(a.summa_kokku / a.kalendri_paevad, 2):: NUMERIC                        as avg_paeva_summa,
                    a.kalendri_paevad::integer                                                   as arv_paevad_perioodis,
                    a.lepingid:: INTEGER                                                         as leping_id,
                    a.allikas:: varchar(20)                                                      as allikas,
                    a.tegev:: varchar(20)                                                        as tegev,
                    a.artikkel:: varchar(20)                                                     as artikkel,
                    a.tunnus:: varchar(20)                                                       as tunnus
                from
                    palk a
            )                             qry
                inner join palk.tooleping t on t.id = qry.leping_id
                inner join libs.asutus    a on a.id = t.parentid
                inner join libs.library   amet on amet.id = t.ametid;


END;
$BODY$
    LANGUAGE 'plpgsql'
    VOLATILE
    COST 100;

select *
from
    palk.calc_avg_income_vacation(2477::INTEGER, '{
      "alg_kpv": "2024-11-01",
      "lopp_kpv": "2025-04-30",
      "isik_id": 30979
    }':: JSON)
order by
    avg_paeva_summa desc


/*

*/