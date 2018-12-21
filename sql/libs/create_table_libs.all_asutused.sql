
DROP TABLE if exists libs.all_asutused;

CREATE TABLE libs.all_asutused
(
  id serial NOT NULL,
  parentid integer NOT NULL,
  childid integer NOT NULL
)
  WITH (OIDS=TRUE);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.all_asutused TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.all_asutused TO dbkasutaja;
GRANT SELECT ON TABLE libs.all_asutused TO dbvaatleja;
