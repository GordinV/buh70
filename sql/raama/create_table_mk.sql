-- Table: docs.mk

DROP TABLE if exists docs.mk;

CREATE TABLE docs.mk
(
  id integer NOT NULL DEFAULT nextval('mk_id_seq'::regclass),
  rekvid integer NOT NULL,
  journalid integer NOT NULL DEFAULT 0,
  aaid integer NOT NULL DEFAULT 0,
  doklausid integer NOT NULL DEFAULT 0,
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  maksepaev date NOT NULL DEFAULT ('now'::text)::date,
  "number" character varying(20) NOT NULL DEFAULT space(1),
  selg text NOT NULL DEFAULT space(1),
  viitenr character varying(20) NOT NULL DEFAULT space(1),
  opt integer NOT NULL DEFAULT 1,
  muud text,
  arvid integer NOT NULL DEFAULT 0,
  doktyyp integer NOT NULL DEFAULT 0,
  dokid integer NOT NULL DEFAULT 0,
    parentId integer,
  CONSTRAINT mk_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.mk TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.mk TO dbkasutaja;
GRANT ALL ON TABLE docs.mk TO dbadmin;
GRANT SELECT ON TABLE docs.mk TO dbvaatleja;

