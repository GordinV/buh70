DROP TABLE if exists libs.nomenklatuur;

CREATE TABLE libs.nomenklatuur
(
  id serial,
  rekvid integer NOT NULL,
  dok character(20) NOT NULL DEFAULT space(1),
  kood character(20) NOT NULL DEFAULT space(1),
  nimetus character(254) NOT NULL DEFAULT space(1),
  uhik character(20) NOT NULL DEFAULT space(1),
  hind numeric(12,4) NOT NULL DEFAULT 0,
  muud text,
  ulehind numeric(12,4) NOT NULL DEFAULT 0,
  kogus numeric(12,3) NOT NULL DEFAULT 0,
  formula text NOT NULL DEFAULT space(1),
  vanaid integer,
  status integer not null default 0,
  properties jsonb,
  CONSTRAINT nomenklatuur_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.nomenklatuur TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.nomenklatuur TO dbkasutaja;
GRANT ALL ON TABLE libs.nomenklatuur TO dbadmin;
GRANT SELECT ON TABLE public.nomenklatuur TO dbvaatleja;



CREATE INDEX nomenklatuur_rekvid
  ON libs.nomenklatuur
  USING btree
  (rekvid);

/*

select * from libs.nomenklatuur

insert into libs.nomenklatuur (rekvId, dok, kood, nimetus, uhik, hind, status)
	values (1, 'PVOPER', 'PAIGALDUS', 'PV paigaldamine', '', 100, 1)

*/