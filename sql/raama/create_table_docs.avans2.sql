DROP TABLE if exists docs.avans2;

CREATE TABLE docs.avans2
(
  id serial NOT NULL,
  parentid integer NOT NULL,
  nomid integer NOT NULL,
  konto character varying(20) NOT NULL DEFAULT space(1),
  kood1 character varying(20) NOT NULL DEFAULT space(1),
  kood2 character varying(20) NOT NULL DEFAULT space(1),
  kood3 character varying(20) NOT NULL DEFAULT space(1),
  kood4 character varying(20) NOT NULL DEFAULT space(1),
  kood5 character varying(20) NOT NULL DEFAULT space(1),
  tunnus character varying(20) NOT NULL DEFAULT space(1),
  summa numeric(12,4) NOT NULL DEFAULT 0,
  kbm numeric(12,4) NOT NULL DEFAULT 0,
  kokku numeric(12,4) NOT NULL DEFAULT 0,
  muud text,
  proj character varying(20) NOT NULL DEFAULT space(20),
  CONSTRAINT avans2_pkey PRIMARY KEY (id)
)
WITH (OIDS=TRUE);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.avans2 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.avans2 TO dbkasutaja;
GRANT all ON TABLE docs.avans2 TO dbadmin;
GRANT SELECT ON TABLE docs.avans2 TO dbvaatleja;

DROP INDEX if exists avans2_idx1;

CREATE INDEX avans2_idx1
  ON docs.avans2
  USING btree
  (parentid);

ALTER TABLE docs.avans2 CLUSTER ON avans2_idx1;

DROP INDEX if exists avans2_idx2;

CREATE INDEX avans2_idx2
  ON docs.avans2
  USING btree
  (nomid, konto, kood1, kood2, kood3, kood4, tunnus);


