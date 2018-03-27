
DROP TABLE if exists docs.korder2;

CREATE TABLE docs.korder2
(
  id serial,
  parentid integer NOT NULL,
  nomid integer NOT NULL,
  nimetus text NOT NULL,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  konto character varying(20),
  kood1 character varying(20),
  kood2 character varying(20),
  kood3 character varying(20),
  kood4 character varying(20),
  kood5 character varying(20),
  tp character varying(20),
  tunnus character varying(20),
  proj character varying(20)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT ON TABLE docs.korder2 TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.korder2 TO dbpeakasutaja;
GRANT ALL ON TABLE docs.korder2 TO dbadmin;
GRANT SELECT ON TABLE docs.korder2 TO dbvaatleja;

DROP INDEX if exists docs.korder2_parentid_idx;

CREATE INDEX korder2_parentid_idx
  ON docs.korder2
  USING btree
  (parentid);

DROP INDEX if exists docs.korder2_nomid_idx;

CREATE INDEX korder2_nomid_idx
  ON docs.korder2
  USING btree
  (nomid);

