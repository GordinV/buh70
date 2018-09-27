DROP TABLE if exists libs.asutus;

CREATE TABLE libs.asutus
(
  id serial,
  rekvid integer NOT NULL,
  regkood character(20) NOT NULL DEFAULT space(1),
  nimetus character(254) NOT NULL DEFAULT space(1),
  omvorm character(20) NOT NULL DEFAULT space(1),
  aadress text NOT NULL DEFAULT space(1),
  kontakt text NOT NULL DEFAULT space(1),
  tel character(60) NOT NULL DEFAULT space(1),
  faks character(60) NOT NULL DEFAULT space(1),
  email character(60) NOT NULL DEFAULT space(1),
  muud text DEFAULT space(1),
  tp character varying(20) NOT NULL DEFAULT space(20),
  staatus integer DEFAULT 1,
  mark text,
  CONSTRAINT asutus_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE libs.asutus TO dbpeakasutaja;
GRANT ALL ON TABLE libs.asutus TO dbadmin;
GRANT SELECT ON TABLE libs.asutus TO dbvaatleja;
GRANT SELECT ON TABLE libs.asutus TO taabel;
GRANT SELECT, UPDATE, INSERT ON TABLE libs.asutus TO dbkasutaja;

-- Index: libs.asutus_nimetus

-- DROP INDEX libs.asutus_nimetus;

CREATE INDEX asutus_nimetus
  ON libs.asutus
  USING btree
  (nimetus COLLATE pg_catalog."default", omvorm COLLATE pg_catalog."default");

-- Index: libs.kood_asutus

-- DROP INDEX libs.kood_asutus;

CREATE INDEX kood_asutus
  ON libs.asutus
  USING btree
  (regkood COLLATE pg_catalog."default");

  /*
select * from libs.asutus
insert into libs.asutus (rekvid, regkood, nimetus, omvorm, staatus)
	values (1,'123456789', 'isik, töötaja', 'ISIK', 1)

  */


CREATE INDEX asutus_staatus
  ON libs.asutus (staatus)
where staatus <> 3;




