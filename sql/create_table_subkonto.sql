-- Table: public.subkonto

DROP TABLE if exists libs.subkonto;

CREATE TABLE libs.subkonto
(
  id       SERIAL,
  kontoid  INTEGER,
  asutusid INTEGER,
  algsaldo NUMERIC(16, 4) NOT NULL DEFAULT 0,
  aasta    INTEGER        NOT NULL DEFAULT year(),
  rekvid   INTEGER,
  CONSTRAINT subkonto_pkey PRIMARY KEY (id)
)
WITH (
OIDS = TRUE
)
TABLESPACE pg_default;

GRANT ALL ON TABLE libs.subkonto TO dbadmin;

GRANT SELECT, DELETE, INSERT, UPDATE ON TABLE libs.subkonto TO dbkasutaja;

GRANT SELECT, UPDATE, DELETE, INSERT ON TABLE libs.subkonto TO dbpeakasutaja;

GRANT SELECT ON TABLE libs.subkonto TO dbvaatleja;

DROP INDEX IF EXISTS libs.subkonto_asutusid;

CREATE INDEX subkonto_asutusid
  ON libs.subkonto USING BTREE
  (asutusid)
TABLESPACE pg_default;

DROP INDEX IF EXISTS libs.subkonto_kontoid;

CREATE INDEX subkonto_kontoid
  ON libs.subkonto USING BTREE
  (kontoid)
TABLESPACE pg_default;

DROP INDEX IF EXISTS libs.subkonto_rekvid;

CREATE INDEX subkonto_rekvid
  ON libs.subkonto USING BTREE
  (rekvid)
TABLESPACE pg_default;

ALTER TABLE libs.subkonto
  CLUSTER ON subkonto_rekvid;