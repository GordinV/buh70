DROP VIEW IF EXISTS com_rekv;

CREATE OR REPLACE VIEW com_rekv AS
  SELECT
    r.id,
    r.regkood,
    r.parentid,
    r.nimetus
  FROM ou.rekv r
  WHERE (parentid < 999 OR r.status <> 3)
  ORDER BY regkood;

GRANT SELECT ON TABLE com_rekv TO dbkasutaja;
GRANT SELECT ON TABLE com_rekv TO dbvaatleja;
GRANT SELECT ON TABLE com_rekv TO dbpeakasutaja;

