-- Table: public.arv

DROP TABLE if exists docs.arv;

CREATE TABLE docs.arv
(
  id serial,
  rekvid integer NOT NULL,
  userid integer NOT NULL,
  journalid integer NOT NULL DEFAULT 0,
  doklausid integer NOT NULL DEFAULT 0,
  liik smallint NOT NULL DEFAULT 0,
  operid integer NOT NULL DEFAULT 0,
  "number" character(20) NOT NULL DEFAULT space(1),
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  asutusid integer NOT NULL DEFAULT 0,
  arvid integer NOT NULL DEFAULT 0,
  lisa character(120) NOT NULL DEFAULT space(1),
  tahtaeg date,
  kbmta numeric(12,4) NOT NULL DEFAULT 0,
  kbm numeric(12,4) NOT NULL DEFAULT 0,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  tasud date,
  tasudok character(254),
  muud text,
  jaak numeric(12,4) NOT NULL DEFAULT 0,
  objektid integer NOT NULL DEFAULT 0,
  objekt character varying(20),
  parentId integer,
  CONSTRAINT arv_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arv TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arv TO dbkasutaja;
GRANT ALL ON TABLE docs.arv TO dbadmin;
GRANT SELECT ON TABLE docs.arv TO dbvaatleja;


insert into docs.arv
	select * from arv
