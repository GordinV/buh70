
CREATE TABLE docs.leping2
(
  id serial NOT NULL,
  parentid integer NOT NULL,
  nomid integer NOT NULL,
  kogus numeric(12,3) NOT NULL DEFAULT 0,
  hind numeric(12,4) NOT NULL DEFAULT 0,
  soodus smallint NOT NULL DEFAULT 0,
  soodusalg date,
  sooduslopp date,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  status smallint NOT NULL DEFAULT 1,
  muud text,
  formula text,
  kbm integer NOT NULL DEFAULT 1,
  CONSTRAINT leping2_pkey PRIMARY KEY (id)
)
WITH (OIDS=TRUE);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.leping2 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.leping2 TO dbkasutaja;
GRANT ALL ON TABLE docs.leping2 TO dbadmin;
GRANT SELECT ON TABLE docs.leping2 TO dbvaatleja;

DROP INDEX if exists leping2_nomid;

CREATE INDEX leping2_nomid
  ON docs.leping2
  USING btree
  (nomid);

DROP INDEX if exists leping2_parentid;

CREATE INDEX leping2_parentid
  ON docs.leping2
  USING btree
  (parentid);

