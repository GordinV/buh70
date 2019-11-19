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
       l.isikukood,
       l.nimi,
       n.kood::TEXT,
       n.nimetus::TEXT               AS teenus,
       n.uhik::TEXT,
       lk.properties ->> 'yksus'     AS yksus,
       lk.properties ->> 'all_yksus' AS all_yksus,
       lt.lapse_kaart_id
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