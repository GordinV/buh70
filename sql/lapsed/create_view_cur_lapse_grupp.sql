DROP VIEW IF EXISTS lapsed.cur_lapse_grupp;

CREATE OR REPLACE VIEW lapsed.cur_lapse_grupp AS

SELECT lg.id    AS id,
       lg.kood,
       lg.nimetus,
       lg.rekvid,
       ltrim(rtrim((properties::jsonb->>'all_yksused'),']'),'[') as all_yksused
FROM libs.library lg
WHERE lg.library = 'LAPSE_GRUPP'
  and lg.status <> 3;

GRANT SELECT ON TABLE lapsed.cur_lapse_grupp TO arvestaja;
GRANT SELECT ON TABLE lapsed.cur_lapse_grupp TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.cur_lapse_grupp TO dbpeakasutaja;

