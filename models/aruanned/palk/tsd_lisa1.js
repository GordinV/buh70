module.exports = {
    grid: {
        gridConfiguration: [
            {id: "konto", name: "konto", width: "25px", show: false},
            {id: "nimetus", name: "Nimetus", width: "100px"},
            {id: "alg_db", name: "Alg.Deebet", width: "100px"},
            {id: "alg_kr", name: "Alg.Kreedit", width: "75px"},
            {id: "deebet", name: "Deebet", width: "100px"},
            {id: "kreedit", name: "Kreedit", width: "100px"},
            {id: "lopp_db", name: "Lõpp deebet", width: "100px"},
            {id: "lopp_kr", name: "Lõpp kreedit", width: "200px"}
        ],
        sqlString: `with
                        params as (
                                      select
                                          case
                                              when $1::date > $2 then date(year($2), month($2), 1)
                                              else $1 end::date as kpv1,
                                          $2::date              as kpv2,
                                          r.id                  as rekv_id,
                                          $4                    as kond,
                                          r.regkood
                                      from
                                          ou.rekv r
                                      where
                                          id = $3

                                  ),
                        report as (
                                      select
                                          isikukood:: VARCHAR(20),
                                          isik:: VARCHAR(254),
                                          tululiik:: VARCHAR(20),
                                          liik:: INTEGER,
                                          regkood::text                            as regkood,
                                          year(p.kpv2)                             as aasta,
                                          month(p.kpv2)                            as kuu,
                                          max(minsots):: NUMERIC(14, 2)            as minsots,
                                          max(sm_arv):: INTEGER                    as sm_arv,
                                          max(tk_arv):: INTEGER                    as tk_arv,
                                          max(minpalk):: NUMERIC(14, 2)            as minpalk,
                                          sum(summa):: NUMERIC(14, 2)              as summa,
                                          sum(puhkused):: NUMERIC(14, 2)           as puhkused,
                                          sum(haigused):: NUMERIC(14, 2)           as haigused,
                                          sum(tm):: NUMERIC(14, 2)                 as tm,
                                          sum(sm):: NUMERIC(14, 2)                 as sm,
                                          sum(tki):: NUMERIC(14, 2)                as tki,
                                          sum(pm):: NUMERIC(14, 2)                 as pm,
                                          sum(tka):: NUMERIC(14, 2)                as tka,
                                          sum(tulubaas):: NUMERIC(14, 2)           as tulubaas,
                                          sum(puhkus):: NUMERIC(14, 2)             as puhkus,
                                          max(v1040):: NUMERIC(14, 2)              as v1040,
                                          max(lopp):: DATE                         as lopp,
                                          sum(arv_min_sots):: NUMERIC(14, 2)       as arv_min_sots,
                                          sum(min_sots_alus):: NUMERIC(14, 2)      as min_sots_alus,
                                          sum(sm + arv_min_sots)::numeric          as v1100,
                                          sum(eri_tm):: NUMERIC(14, 2)             as eri_tm,
                                          sum(eri_sm):: NUMERIC(14, 2)             as eri_sm,
                                          sum(lisa_min_sots):: NUMERIC(14, 2)      as lisa_min_sots,
                                          sum(lisa_sm_alus):: NUMERIC(14, 2)       as lisa_sm_alus,
                                          sum(sm_kokku):: NUMERIC(14, 2)           as sm_kokku,
                                          sum(lisa_sm_arvestatud):: NUMERIC(14, 2) as lisa_sm_arvestatud,
                                          sum(alus_sm_arvestatud):: NUMERIC(14, 2) as alus_sm_arvestatud,
                                          max(kas_pensionar):: INTEGER             as kas_pensionar
                                      FROM
                                          params                           p,
                                          palk.tsd_lisa_1(p.kpv1::date, p.kpv2::date, p.rekv_id::integer,
                                                          p.kond::integer) qry
                                      group by regkood, isikukood, isik, tululiik, liik, p.kpv2

                                  )
                    select
                        sum(tm) over ()                                         as tm_kokku,
                        sum(sm) over ()                                         as kokku_sm,
                        sum(tki + tka) over ()                                  as tki_kokku,
                        sum(pm) over ()                                         as pm_kokku,
                        sum(tm + tki + tka + pm) over ()::numeric(14, 2) +
                        r.sm_kokku::numeric(14, 2)                              as kohustused_kokku,
                        r.summa * sm_arv                                        as v1120,
                        case when r.kas_pensionar > 0 then '650' else '610' end as tuli_kood,
                        count(*) over (partition by isikukood)                  as tululiik_kogus,
                        r.*
                    from
                        report r
                    order by
                        r.isikukood, r.tululiik`,     //  $1 - kpv1, $2 - kpv2, $3 - rekvid, $4 svod (null)
        params: '',
        alias: 'tsd_lisa1'
    }
};
