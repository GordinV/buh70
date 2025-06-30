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
                isiku_nimi          TEXT,
                isiku_IK            TEXT,
                jaak                NUMERIC(14, 2),
                raamatu_jaak        numeric(14, 2),
                vanemate_jaak_kogus integer,
                rekvid              INTEGER,
                kas_viga            boolean,
                vea_selgitus        text
            )
AS
$BODY$
WITH laste_jaak as (select qry.lopp_db - qry.lopp_kr as jaak,
                           qry.isik_id               as laps_id,
                           qry.rekvid
                    FROM lapsed.saldo_ja_kaibeandmik(l_rekvid, l_kpv::date, l_kpv::date, null::integer) qry),
     params as (select jsonb_build_object('laps_id', to_jsonb(array_agg(lj.laps_id))) as laps_ids
                from laste_jaak lj),
     raamatu_jaak as (SELECT (rep.alg_saldo + rep.deebet - rep.kreedit)          as laps_jaak_kokku,
                             count(*) over (partition by rep.laps_id, rep.rekv_id) as laps_vastisik_jaak_kogus,
                             rep.rekv_id,
                             rep.laps_id                                         as laps_id,
                             rep.asutus_id                                         as isik_id
                      FROM params p,
                           docs.kaibeasutusandmik('10300029', null::integer, l_kpv::date, l_kpv::date,
                                                  l_rekvid, '%', 1, jsonb_build_object('laps_id', p.laps_ids)) rep
                      where (rep.alg_saldo + deebet - kreedit) <> 0
                        and rep.rekv_id not in (999999))

SELECT count(*) OVER (PARTITION BY lj.laps_id)::bigint                               as id,
       l_kpv                                                                         as period,
       l.nimi::text                                                                  as lapse_nimi,
       l.isikukood::text                                                             as lapse_isikukood,
       lapsed.get_viitenumber(lj.rekvid, lj.laps_id)::text                           as viitenumber,
       a.nimetus::text                                                               as isiku_nimi,
       a.regkood::text                                                               as isiku_IK,
       lj.jaak::NUMERIC(14, 2)                                                       as jaak,
       rj.laps_jaak_kokku::NUMERIC(14, 2)                                            as raamatu_jaak,
       rj.laps_vastisik_jaak_kogus::integer                                          as vanemate_jaak_kogus,
       lj.rekvid::integer,
       case when lj.jaak <> coalesce(rj.laps_jaak_kokku, 0) then true else false end as kas_viga,
       null::text
from laste_jaak lj
         inner join lapsed.laps l on l.id = lj.laps_id
         left outer join raamatu_jaak rj on rj.laps_id = lj.laps_id and lj.rekvid = rj.rekv_id
         inner join libs.asutus a on a.id = rj.isik_id

where lj.jaak <> 0
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
    lapsed.saldo_aruanne(72, '2025-06-01'::DATE)
where
    lapse_isikukood = '61702170126'
*/
