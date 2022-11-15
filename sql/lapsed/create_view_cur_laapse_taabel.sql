DROP VIEW IF EXISTS lapsed.cur_lapse_taabel;

CREATE OR REPLACE VIEW lapsed.cur_lapse_taabel AS

SELECT lt.id,
       lt.parentid,
       lt.rekvid,
       lt.nomid,
       lt.kuu,
       lt.aasta,
       coalesce(lt.kogus, 0)                                               AS kogus,
       lt.hind                                                             AS hind,
       coalesce(n.properties ->> 'tyyp', '')                               AS tyyp,
       lt.umberarvestus::BOOLEAN                                           AS umberarvestus,
       lt.soodustus                                                        AS soodustus,
       (lk.properties ->> 'kas_protsent')::BOOLEAN                         AS kas_protsent,
       CASE WHEN lt.properties ->> 'sooduse_alg' IS NULL THEN 1 ELSE 0 END AS sooduse_kehtivus,
       (lt.properties ->> 'alus_soodustus')::NUMERIC(12, 2)                AS alus_soodustus,
       coalesce(lt.summa, 0)                                               AS summa,
       l.isikukood,
       l.nimi,
       n.kood::TEXT,
       n.nimetus::TEXT                                                     AS teenus,
       n.uhik::TEXT,
       grupp.nimetus::TEXT                                                 AS yksus,
       lk.properties ->> 'all_yksus'                                       AS all_yksus,
       lt.lapse_kaart_id,
       (lt.properties ->> 'sooduse_alg')::DATE                             AS sooduse_alg,
       (lt.properties ->> 'sooduse_lopp')::DATE                            AS sooduse_lopp,
       (lk.properties ->> 'viitenr')::TEXT                                 AS viitenr,
       lt.muud,
       coalesce((lt.properties ->> 'kulastused')::INTEGER, 0)              AS kulastused,
       coalesce((lt.properties ->> 'too_paevad')::INTEGER, 0)              AS too_paevad,
       coalesce((lt.properties ->> 'kovid')::INTEGER, 0)                   AS kovid,
       lt.vahe
FROM lapsed.lapse_taabel lt
         INNER JOIN lapsed.laps l ON l.id = lt.parentid
         INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
         INNER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
         LEFT OUTER JOIN libs.library grupp
                         ON grupp.library::TEXT = 'LAPSE_GRUPP'::TEXT AND grupp.rekvid = lk.rekvid AND grupp.status <> 3
                             AND grupp.kood::TEXT = (lk.properties ->> 'yksus')::TEXT
WHERE lt.staatus <> 3
  --AND coealslt.kogus <> 0
  AND n.status <> 3
  AND lt.hind <> 0
  AND NOT coalesce((lk.properties ->> 'kas_ettemaks')::BOOLEAN, FALSE)
ORDER BY aasta, kuu, nimi, kood;

GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbpeakasutaja;

/*

select vahe, * from lapsed.cur_lapse_taabel
where rekvid = 99
and kuu = 1 and aasta = 2022
and parentid = 8021
limit 10
select * from lapsed.laps
 */