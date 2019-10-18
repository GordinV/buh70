DROP VIEW IF EXISTS lapsed.com_lapse_grupp;

CREATE OR REPLACE VIEW lapsed.com_lapse_grupp AS

SELECT lg.id    AS id,
       lg.kood,
       lg.nimetus,
       lg.rekvid,
       lg.properties::jsonb ->'all_yksused' as all_yksused,
       lg.properties::jsonb ->'teenused' as teenused
FROM libs.library lg
WHERE lg.library = 'LAPSE_GRUPP'
  and lg.status <> 3;

GRANT SELECT ON TABLE lapsed.com_lapse_grupp TO arvestaja;
GRANT SELECT ON TABLE lapsed.com_lapse_grupp TO dbvaatleja;
GRANT SELECT ON TABLE lapsed.com_lapse_grupp TO dbpeakasutaja;

