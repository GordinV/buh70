DROP FUNCTION IF EXISTS lapsed.jaotamata_jaak(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.jaotamata_jaak(l_rekvid INTEGER,
                                                 l_kpv DATE DEFAULT current_date)
    RETURNS TABLE
            (
                period      DATE,
                rekvid      INTEGER,
                ik          text,
                nimi        text,
                vn          text,
                arvete_jaak numeric(12, 2),
                mk_jaak     numeric(12, 2),
                asutus text

            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      l_rekvid                 AS rekv_id,
                      CASE
                          WHEN l_kpv IS NULL OR empty(l_kpv::TEXT) THEN date(year(current_date), 12, 31)
                          ELSE l_kpv END::DATE AS kpv
              ),
    rekv_ids AS (
                  SELECT
                      r.rekv_id
                  FROM
                      params,
                      public.get_asutuse_struktuur(params.rekv_id) r
                  where
                      -- убрать закрытые садики при своде А. Варгунин 28.10.2025
                      (l_rekvid <> 119 or r.rekv_id not in (
                                                               select
                                                                   r.id
                                                               from
                                                                   ou.rekv r
                                                               where
                                                                   left(nimetus, 7)
                                                                       in ('0911006', '0911007', '0911008', '0911009',
                                                                           '0911012', '0911030', '0911036')
                                                           )
                          )
              ),

    arved as (
                  select
                      sum(jaak) as jaak,
                      a.laps_id,
                      a.rekvid
                  from
                      params,
                      lapsed.cur_laste_arved a
                  where
                        a.rekvid in (
                                        select
                                            r.rekv_id
                                        from
                                            rekv_ids r
                                    )
                    and a.jaak <> 0
                    and a.kpv < params.kpv
                  group by a.laps_id, a.rekvid
              ),
    mk as (
                  select
                      sum(mk.jaak) as jaak,
                      mk.laps_id,
                      mk.rekvid
                  from
                      params,
                      lapsed.cur_lapsed_mk mk
                  where
                        mk.rekvid in (
                                         select
                                             r.rekv_id
                                         from
                                             rekv_ids r
                                     )
                    and mk.maksepaev < params.kpv
                    and mk.jaak <> 0
                  group by mk.laps_id, mk.rekvid
              )
select
    l_kpv                                                           as period,
    coalesce(r.id, r_mk.id)                                         as rekvid,
    trim(l.isikukood)::text                                         as ik,
    trim(l.nimi)::text                                              as nimi,
    lapsed.get_viitenumber(coalesce(arved.rekvid, mk.rekvid), l.id) as vn,
    arved.jaak                                                      as arvete_jaak,
    mk.jaak                                                         as mk_jaak,
    trim(coalesce(r.nimetus, r_mk.nimetus))::text                   as asutus
from
    lapsed.laps                 l
        full outer join arved on arved.laps_id = l.id
        full outer join mk on mk.laps_id = l.id
        left outer join ou.rekv r on r.id = arved.rekvid
        left outer join ou.rekv r_mk on r_mk.id = mk.rekvid
where
      coalesce(arved.jaak, 0) <> 0
  and coalesce(mk.jaak, 0) <> 0
    order by l.isikukood, coalesce(r.nimetus, r_mk.nimetus)
$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.jaotamata_jaak(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.jaotamata_jaak(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.jaotamata_jaak(INTEGER, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.jaotamata_jaak(INTEGER, DATE) TO dbvaatleja;


/*
SELECT * from lapsed.jaotamata_jaak(119,current_date )
*/
