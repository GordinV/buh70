DROP VIEW IF EXISTS lapsed.cur_teenused;
DROP VIEW IF EXISTS lapsed.cur_lapse_kaart;

CREATE OR REPLACE VIEW lapsed.cur_lapse_kaart AS

SELECT l.id as lapsid,
       lk.id,
       l.isikukood,
       l.nimi,
       lk.rekvid,
       lk.hind,
       lk.properties ->> 'yksus' AS yksus,
       n.kood,
       n.nimetus
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