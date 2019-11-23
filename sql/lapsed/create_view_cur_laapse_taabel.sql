DROP VIEW IF EXISTS lapsed.cur_lapse_taabel;

CREATE OR REPLACE VIEW lapsed.cur_lapse_taabel AS

SELECT lt.id,
       lt.parentid,
       lt.rekvid,
       lt.nomid,
       lt.kuu,
       lt.aasta,
       lt.kogus,
       lk.hind::NUMERIC(12, 2),
       coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC AS soodustus,
       (lk.properties ->> 'kas_protsent')::BOOLEAN                 AS kas_protsent,
       CASE
           WHEN month((lk.properties ->> 'sooduse_alg')::DATE) <= lt.kuu AND
                year((lk.properties ->> 'sooduse_alg')::DATE) <= lt.aasta
               AND month((lk.properties ->> 'sooduse_lopp')::DATE) >= lt.kuu AND
                year((lk.properties ->> 'sooduse_lopp')::DATE) >= lt.aasta THEN 1
           ELSE 0 END                                              AS sooduse_kehtivus,
       l.isikukood,
       l.nimi,
       n.kood::TEXT,
       n.nimetus::TEXT                                             AS teenus,
       n.uhik::TEXT,
       lk.properties ->> 'yksus'                                   AS yksus,
       lk.properties ->> 'all_yksus'                               AS all_yksus,
       lt.lapse_kaart_id,
       (lk.properties ->> 'sooduse_alg')::DATE                     AS sooduse_alg,
       (lk.properties ->> 'sooduse_lopp')::DATE                    AS sooduse_lopp

FROM lapsed.lapse_taabel lt
         INNER JOIN lapsed.laps l ON l.id = lt.parentid
         INNER JOIN libs.nomenklatuur n ON n.id = lt.nomid
         LEFT OUTER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
WHERE lt.staatus <> 3
ORDER BY aasta, kuu, nimi, kood;

GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_taabel TO dbpeakasutaja;

/*

select * from lapsed.cur_lapsed
select * from lapsed.laps
 */