-- Table: docs.mk1

DROP TABLE if exists docs.mk1 ;

CREATE TABLE docs.mk1
(
  id integer NOT NULL DEFAULT nextval('mk1_id_seq'::regclass),
  parentid integer NOT NULL,
  asutusid integer NOT NULL,
  nomid integer NOT NULL,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  aa character varying(20) NOT NULL,
  pank character varying(3),
  journalid integer,
  kood1 character varying(20),
  kood2 character varying(20),
  kood3 character varying(20),
  kood4 character varying(20),
  kood5 character varying(20),
  konto character varying(20),
  tp character varying(20),
  tunnus character varying(20),
  proj character varying(20),
  CONSTRAINT mk1_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.mk1 TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.mk1 TO dbkasutaja;
GRANT ALL ON TABLE docs.mk1 TO dbadmin;
GRANT SELECT ON TABLE docs.mk1 TO dbvaatleja;
