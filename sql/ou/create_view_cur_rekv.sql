DROP VIEW IF EXISTS cur_rekv;

CREATE OR REPLACE VIEW cur_rekv AS
  SELECT
    r.id,
    r.regkood,
    r.parentid,
    r.nimetus,
    r.status
  FROM ou.rekv r
  WHERE (parentid < 999 OR r.status <> 3)
  and id <> 90 -- kakuke 
  ORDER BY regkood;

GRANT SELECT ON TABLE cur_rekv TO dbkasutaja;
GRANT SELECT ON TABLE cur_rekv TO dbvaatleja;
GRANT SELECT ON TABLE cur_rekv TO dbpeakasutaja;

