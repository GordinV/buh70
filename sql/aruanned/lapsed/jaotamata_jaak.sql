DROP FUNCTION IF EXISTS lapsed.jaotamata_jaak(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.jaotamata_jaak(l_rekvid INTEGER,
                                                 l_kpv DATE DEFAULT current_date)
    RETURNS TABLE
            (
                period       DATE,
                rekvid       INTEGER,
                ik           text,
                nimi         text,
                vn           text,
                arvete_jaak  numeric(12, 2),
                mk_jaak      numeric(12, 2),
                asutus       text,
                kulastatavus text

            )
AS
$BODY$
WITH
    params AS (
                  SELECT
                      l_rekvid                 AS rekv_id,
                      CASE
                          WHEN l_kpv IS NULL OR empty(l_kpv::TEXT) THEN current_date
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
                      (params.rekv_id <> 119 or r.rekv_id not in (
                                                                     select
                                                                         r.id
                                                                     from
                                                                         ou.rekv r
                                                                     where
                                                                         left(nimetus, 7)
                                                                             in
                                                                         ('0911006', '0911007', '0911008', '0911009',
                                                                          '0911012', '0911030', '0911036')
                                                                 )
                          )
              ),
    kreedit_arved as (
                  select
                      at.doc_tasu_id
                  from
                      docs.arvtasu            at
                          INNER JOIN docs.arv a on a.parentid = at.doc_arv_id
                  where
                        at.pankkassa = 4 -- kreeditarve
                    and at.rekvid in (
                                         select
                                             rekv_id
                                         from
                                             rekv_ids r
                                     )
                    and at.doc_tasu_id is not null
                    and at.status < 3
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
                    and a.kpv <= params.kpv
                    and a.id not in (
                                        select
                                            ka.doc_tasu_id
                                        from
                                            kreedit_arved ka
                                    )

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
                    and mk.maksepaev <= params.kpv
                    and mk.jaak <> 0
                  group by mk.laps_id, mk.rekvid
              ),
    docs as (
                  select
                      a.rekvid,
                      a.laps_id,
                      lapsed.get_viitenumber(a.rekvid, a.laps_id)::text as vn,
                      a.jaak                                            as arvete_jaak,
                      0::numeric                                        as mk_jaak
                  from
                      arved a
                  union all
                  select
                      mk.rekvid,
                      mk.laps_id,
                      lapsed.get_viitenumber(mk.rekvid, mk.laps_id)::text as vn,
                      0::numeric                                          as arvete_jaak,
                      mk.jaak                                             as mk_jaak
                  from
                      mk
              ),
    kulastavus AS (
                  SELECT
                      laps_id,
                      rekv_id,
                      MIN(alg_kpv)  AS alg_kpv,
                      max(lopp_kpv) AS lopp_kpv
                  FROM
                      (
                          SELECT
                              parentid                                                                   AS laps_id,
                              rekvid                                                                     AS rekv_id,
                              COALESCE(
                                      (lk.properties ->> 'alg_kpv')::DATE,
                                      make_date(date_part('year', CURRENT_DATE)::INTEGER, 1, 1))::DATE   AS alg_kpv,
                              COALESCE(
                                      (lk.properties ->>
                                       'lopp_kpv')::DATE,
                                      make_date(date_part('year', CURRENT_DATE)::INTEGER, 12, 31))::DATE AS lopp_kpv
                          FROM
                              lapsed.lapse_kaart lk
                          WHERE
                                lk.staatus <> 3
                            AND lk.rekvid IN (
                                                 SELECT
                                                     rekv_id
                                                 FROM
                                                     rekv_ids
                                             )
                      ) qry

                  GROUP BY
                      laps_id,
                      rekv_id
              ),
    report as (
                  select
                      sum(d.arvete_jaak) over (partition by laps_id) as laps_arv_jaak,
                      sum(d.mk_jaak) over (partition by laps_id)     as laps_mk_jaak,
                      d.rekvid                                       as rekvid,
                      trim(l.isikukood)::text                        as ik,
                      trim(l.nimi)::text                             as nimi,
                      d.vn                                           as vn,
                      d.arvete_jaak                                  as arvete_jaak,
                      d.mk_jaak                                      as mk_jaak,
                      r.nimetus::text                                as asutus,
                      l.id                                           as laps_id
                  from
                      lapsed.laps                 l
                          inner join      docs    d on d.laps_id = l.id
                          left outer join ou.rekv r on r.id = d.rekvid
              )
select
    p.kpv::date                                                          as period,
    r.rekvid::integer,
    r.ik::text,
    r.nimi::text,
    r.vn::text,
    sum(r.arvete_jaak)::numeric(12, 2)                                        as arvete_jaak,
    sum(r.mk_jaak)::numeric(12, 2)                                            as mk_jaak,
    r.asutus::text,
    case when p.kpv between k.alg_kpv and k.lopp_kpv then 'Jah' else 'Ei' end as kulastatavus
from
    params                         p,
    report                         r
        LEFT OUTER JOIN kulastavus k ON k.laps_id = r.laps_id AND k.rekv_id = r.rekvid

where
      coalesce(r.laps_arv_jaak, 0) <> 0
  and coalesce(r.laps_mk_jaak, 0) <> 0
group by
    r.rekvid, r.ik, r.nimi, r.vn, r.asutus, p.kpv,
    case when p.kpv between k.alg_kpv and k.lopp_kpv then 'Jah' else 'Ei' end
order by
    r.ik, r.asutus

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
where ik = '61208303727'
*/
