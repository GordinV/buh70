DROP VIEW IF EXISTS lapsed.cur_teenused;
DROP VIEW IF EXISTS lapsed.cur_lapse_kaart;

CREATE OR REPLACE VIEW lapsed.cur_lapse_kaart AS

SELECT l.id                                                                 AS lapsid,
       lk.id,
       l.isikukood,
       l.nimi,
       lk.rekvid,
       lk.hind,
       lk.properties ->> 'yksus'                                            AS yksus,
       lk.properties ->> 'all_yksus'                                        AS all_yksus,
       n.kood,
       n.nimetus,
       coalesce((lk.properties ->> 'alg_kpv')::DATE, date(year(), 1, 1))    AS alg_kpv,
       coalesce((lk.properties ->> 'lopp_kpv')::DATE, date(year(), 12, 31)) AS lopp_kpv,
       case WHEN  (lk.properties->>'kas_inf3')::BOOLEAN then 'INF3' else '' end as inf3

FROM lapsed.laps l
         INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.id
         INNER JOIN libs.nomenklatuur n ON lk.nomid = n.id
WHERE lk.staatus <> 3;

GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_kaart TO dbpeakasutaja;

/*

select * from lapsed.cur_lapsed
select * from lapsed.laps
 */