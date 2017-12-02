
DROP TABLE if exists docs.pv_kaart;

CREATE TABLE docs.pv_kaart
(
  id serial,
  parentid integer NOT NULL,
  kood text not null,
  nimetus text not null,
  rekvId integer,
  selgitus text,
  vastisikid integer NOT NULL DEFAULT 0,
  soetmaks numeric(18,4) NOT NULL DEFAULT 0,
  soetkpv date NOT NULL DEFAULT ('now'::text)::date,
  kulum numeric(12,4) NOT NULL DEFAULT 0,
  algkulum numeric(18,4) NOT NULL DEFAULT 0,
  gruppid integer NOT NULL DEFAULT 0,
  konto character varying(20) NOT NULL DEFAULT space(1),
  tunnus smallint NOT NULL DEFAULT 0,
  mahakantud date,
  otsus text,
  muud text,
  parhind numeric(18,4) NOT NULL DEFAULT 0,
  vanaid integer,
  jaak numeric(18,2) DEFAULT 0,
  CONSTRAINT pv_kaart_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.pv_kaart TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE docs.pv_kaart TO dbkasutaja;
GRANT ALL ON TABLE docs.pv_kaart TO dbadmin;
GRANT SELECT ON TABLE docs.pv_kaart TO dbvaatleja;

-- Index: public.pv_kaart_parentid_idx

-- DROP INDEX public.pv_kaart_parentid_idx;

CREATE INDEX pv_kaart_parentid_idx
  ON docs.pv_kaart
  USING btree
  (parentid);

CREATE INDEX pv_kaart_gruppid_idx
  ON docs.pv_kaart
  USING btree
  (gruppid);



CREATE TRIGGER trigi_pv_kaart_before
  BEFORE INSERT
  ON docs.pv_kaart
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigi_check_docs_before();


/*

select * from docs.pv_kaart

select * from libs.library
update libs.library set kood = 'PVOPER', nimetus = 'PV tehingud' where id = 3

insert into libs.library (kood, nimetus, library, rekvId) values ('PVKAART', 'PV kaart', 'DOK', 1)

insert into docs.pv_kaart (kood, nimetus, rekvid, selgitus, status, vastisikId, soetmaks, soetkpv, kulum, algkulum, gruppid, konto, jaak, parhind)
	values ('001', 'PV kaart', 1, 'PV selg', 1, 2, 100, date(), 20, 10,7, '1550',90,100 )
	
*/