DROP FUNCTION IF EXISTS lapsed.saldo_aruanne(INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.saldo_aruanne(l_rekvid INTEGER,
                                                l_kpv DATE DEFAULT current_date)
    RETURNS TABLE
            (
                id                  BIGINT,
                period              date,
                lapse_nimi          TEXT,
                lapse_isikukood     TEXT,
                viitenumber         TEXT,
                jaak                NUMERIC(14, 2),
                raamatu_jaak        numeric(14, 2),
                vanemate_jaak_kogus integer,
                vanemate_ids        integer[],
                rekvid              INTEGER,
                kas_viga            boolean,
                vea_selgitus        text
            )
AS
$BODY$
WITH
    raamatu_jaak as (
                        SELECT
                            sum(rep.alg_saldo + deebet - kreedit) as laps_jaak_kokku,
                            count(*)                              as laps_vastisik_jaak_kogus,
                            rep.rekv_id,
                            array_agg(rep.asutus_id)              as isik_ids,
                            va.parentid                           as laps_id
                        FROM
                            docs.kaibeasutusandmik('10300029', null::integer, l_kpv::date, l_kpv::date,
                                                   l_rekvid, '%', 1) rep
                                inner join lapsed.vanem_arveldus     va
                                           on va.asutusid = rep.asutus_id and va.rekvid = rep.rekv_id
                        where
                              (rep.alg_saldo + deebet - kreedit) <> 0
                          and rep.rekv_id not in (999999)
                        group by va.parentid, va.rekvid, rep.rekv_id
                    ),
    laste_jaak as (
                        select
                            qry.lopp_db - qry.lopp_kr as jaak,
                            qry.isik_id               as laps_id,
                            qry.rekvid
                        FROM
                            lapsed.saldo_ja_kaibeandmik(l_rekvid, l_kpv::date, l_kpv::date, null::integer) qry
                    )

SELECT
    count(*) OVER (PARTITION BY lj.laps_id)::bigint                               as id,
    l_kpv                                                                         as period,
    l.nimi::text                                                                  as lapse_nimi,
    l.isikukood::text                                                             as lapse_isikukood,
    lapsed.get_viitenumber(lj.rekvid, lj.laps_id)::text                           as viitenumber,
    lj.jaak::NUMERIC(14, 2)                                                       as jaak,
    rj.laps_jaak_kokku::NUMERIC(14, 2)                                            as raamatu_jaak,
    rj.laps_vastisik_jaak_kogus::integer                                          as vanemate_jaak_kogus,
    rj.isik_ids::integer[]                                                        as vanemate_ids,
    lj.rekvid::integer,
    case when lj.jaak <> coalesce(rj.laps_jaak_kokku, 0) then true else false end as kas_viga,
    null::text
from
    laste_jaak                       lj
        inner join      lapsed.laps  l on l.id = lj.laps_id
        left outer join raamatu_jaak rj on rj.laps_id = lj.laps_id and lj.rekvid = rj.rekv_id
where
      lj.jaak <> 0
  and coalesce(rj.laps_jaak_kokku, 0) <> 0
  and coalesce(rj.laps_vastisik_jaak_kogus, 0) > 1


$BODY$
    LANGUAGE SQL
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION lapsed.saldo_aruanne(INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_aruanne(INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_aruanne(INTEGER, DATE) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.saldo_aruanne(INTEGER, DATE) TO dbvaatleja;


/*
select *
from
    lapsed.saldo_aruanne(119, '2025-05-31'::DATE)
where
    lapse_isikukood = '61006143727'
*/
