DROP FUNCTION IF EXISTS palk.get_paevad_perioodis(JSONB);

CREATE FUNCTION palk.get_paevad_perioodis(IN params JSONB)
    RETURNS TABLE
            (
                arvestatud_paevad INTEGER,
                kalendri_paevad   INTEGER,
                puudumiste_paevad integer,
                pidu_paevad       integer
            )
as
$BODY$

DECLARE
    l_puudumine_id integer = params ->> 'puudumine_id';
    l_alg_kpv      date    = params ->> 'alg_kpv';
    l_lopp_kpv     date = params ->>'lopp_kpv';
BEGIN

    with puudumine as (select month(p.kpv1) as kuu,
                              year(p.kpv2)  as aasta,
                              p.lepingid    as leping_id,
                              p.kpv1        as puudumise_alg_kpv,
                              p.kpv2        as puudumise_lopp_kpv
                       from palk.puudumine p
                       where p.id = l_puudumine_id),
         paevad as (select (select count(id)
                            from cur_tahtpaevad t
                            where rekvid = 63 -- беру данные фин. департамента
                              and make_date(t.aasta, t.kuu, t.paev) between
                                l_alg_kpv and l_lopp_kpv) as pidu_paevad,
                           (l_lopp_kpv - l_alg_kpv) + 1   as kalendri_paevad),

         puudumised as (with puudumiste_paevad as
                                 (select p.lepingid,
                                         t.vs_kooded,
                                         case when l_alg_kpv > p.kpv1 then l_alg_kpv else p.kpv1 end::date as alg_puudumise_kpv, -- дата начала отсутствия с поправкой на период расчета
                                         case when l_lopp_kpv < p.kpv2 then l_lopp_kpv else p.kpv2 end     AS lopp_puudumise_kpv,
                                         (select count(id)
                                          from cur_tahtpaevad t
                                          where rekvid = 63 -- беру данные фин. департамента
                                            and make_date(t.aasta, t.kuu, t.paev) between case
                                                                                              when l_alg_kpv > p.kpv1
                                                                                                  then l_alg_kpv
                                                                                              else p.kpv1 end::date
                                              and case
                                                      when l_lopp_kpv < p.kpv2 then l_lopp_kpv
                                                      else p.kpv2 end)                                     as pidu_paevad_puhkusel

                                  from palk.puudumine p
                                           inner join palk.com_puudumiste_tyyp t
                                                      on t.id = p.tyyp and t.liik = p.puudumiste_liik,
                                       params
                                  where p.kpv1 < l_lopp_kpv::date
                                    and p.status <> 'deleted'
                                    and create_date_range(p.kpv1, case
                                                                      when p.kpv2 = p.kpv1
                                                                          then p.kpv2 + 1
                                                                      else p.kpv2 end) &&
                                        create_date_range(l_alg_kpv, l_lopp_kpv)
                                    and t.vs_kooded <@
                                        array ['P','A', 'AP', 'AT', 'EMP', 'IP', 'LHP', 'LP', 'LPA', 'MTV', 'PIH', 'PL', 'PLP', 'TE', 'TLP', 'TP', 'V', 'VK', 'VP', 'ÕP',
                                            'AH','H', 'HD', 'HL', 'HP', 'PH',
                                            'STR',
                                            'EKK',
                                            'K', 'M'])
                        select pp.lepingid,
                               sum((pp.lopp_puudumise_kpv - pp.alg_puudumise_kpv) + 1 -
                                   pidu_paevad_puhkusel) as puudumiste_paevad
                        from puudumiste_paevad pp
                        group by pp.lepingid)
    select paevad.kalendri_paevad - coalesce(p.puudumiste_paevad, 0) -
           paevad.pidu_paevad               as arvestatud_paevad,
           paevad.kalendri_paevad,
           coalesce(p.puudumiste_paevad, 0) as puudumiste_paevad,
           paevad.pidu_paevad
    from puudumised p,
         paevad;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;

GRANT EXECUTE ON FUNCTION palk.get_paevad_perioodis( JSONB ) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION palk.get_paevad_perioodis( JSONB ) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION palk.get_paevad_perioodis( JSONB ) TO dbvaatleja;

-- lepingid, kuu, aasta, alg_kpv , lopp_kpv, toograf

select *
from
    palk.get_paevad_perioodis('{
      "alg_kpv": "2025-03-20",
      "lopp_kpv": "2025-03-31"
    }')

/*
SELECT *
FROM palk.fnc_get_sunnipaev(1, '{
  "isikukood": "37303023721"
}');
*/