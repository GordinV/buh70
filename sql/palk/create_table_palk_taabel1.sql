-- Table: docs.palk_taabel1

DROP TABLE if exists docs.palk_taabel1;

CREATE TABLE docs.palk_taabel1
(
  id serial,
  parentId integer,
  toolepingid integer NOT NULL DEFAULT 0,
  kuu smallint NOT NULL DEFAULT month(('now'::text)::date),
  aasta smallint NOT NULL DEFAULT year(('now'::text)::date),
  muud text,
  kokku numeric(12,4) DEFAULT 0,
  too numeric(12,4) DEFAULT 0,
  paev numeric(12,4) DEFAULT 0,
  ohtu numeric(12,4) DEFAULT 0,
  oo numeric(12,4) DEFAULT 0,
  tahtpaev numeric(12,4) DEFAULT 0,
  puhapaev numeric(12,4) DEFAULT 0,
  uleajatoo numeric(12,4) DEFAULT 0,
  CONSTRAINT palk_taabel1_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.palk_taabel1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE docs.palk_taabel1 TO dbkasutaja;
GRANT ALL ON TABLE docs.palk_taabel1 TO dbadmin;
GRANT SELECT ON TABLE docs.palk_taabel1 TO dbvaatleja;
GRANT ALL ON TABLE docs.palk_taabel1 TO taabel;

-- Index: docs.ix_palk_taabel1

-- DROP INDEX docs.ix_palk_taabel1;

CREATE INDEX ix_palk_taabel1
  ON docs.palk_taabel1
  USING btree
  (toolepingid);
ALTER TABLE docs.palk_taabel1 CLUSTER ON ix_palk_taabel1;

-- Index: docs.palk_taabel1_period

-- DROP INDEX docs.palk_taabel1_period;

CREATE INDEX palk_taabel1_period
  ON docs.palk_taabel1
  USING btree
  (kuu, aasta);



CREATE TRIGGER trigi_taabel_before
  BEFORE INSERT
  ON docs.palk_taabel1
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigi_check_docs_before();


/*
delete from docs.palk_taabel1

insert into docs.palk_taabel1 (toolepingId, kuu, aasta, kokku, too)
	values (2, 1, 2016, 160, 160)

select * from libs.library

*/