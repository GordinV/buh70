
DROP TABLE if exists ou.aa;

CREATE TABLE ou.aa
(
  id serial,
  parentid integer NOT NULL,
  arve character(20) NOT NULL,
  nimetus character(254) NOT NULL,
  saldo numeric(12,4) NOT NULL DEFAULT 0,
  default_ smallint NOT NULL DEFAULT 0,
  kassa integer NOT NULL DEFAULT 0,
  pank integer NOT NULL DEFAULT 0,
  konto character(20),
  muud text,
  tp character varying(20),
  CONSTRAINT aa_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE ou.aa TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE ou.aa TO dbkasutaja;
GRANT all ON TABLE ou.aa TO dbadmin;
GRANT SELECT ON TABLE ou.aa TO dbvaatleja;

-- Index: public.aa_parentid

DROP INDEX if exists public.aa_parentid;

CREATE INDEX aa_parentid
  ON public.aa
  USING btree
  (parentid);


