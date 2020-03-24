DROP VIEW IF EXISTS lapsed.cur_day_taabel;
DROP VIEW IF EXISTS lapsed.cur_paeva_taabel;

CREATE OR REPLACE VIEW lapsed.cur_paeva_taabel AS
SELECT t.id,
       t.kpv,
       g.nimetus AS yksus,
       t.rekv_id,
       s.nimetus::text as staatus
FROM lapsed.day_taabel t
         INNER JOIN libs.library g ON t.grupp_id = g.id
         LEFT OUTER JOIN libs.library s ON s.library = 'STATUS' AND s.kood = t.staatus :: TEXT
WHERE t.staatus <> 3;


GRANT SELECT ON TABLE lapsed.cur_paeva_taabel TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_paeva_taabel TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_paeva_taabel TO dbpeakasutaja;


/*
select * from lapsed.cur_day_taabel
 */