DROP TABLE if exists docs.pv_oper;

CREATE TABLE docs.pv_oper
(
  id serial,
  parentid integer NOT NULL,
  pv_kaart_id integer NOT NULL,
  nomid integer NOT NULL DEFAULT 0,
  liik integer NOT NULL DEFAULT 0,
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  muud text,
  kood1 character varying(20) NOT NULL DEFAULT space(20),
  kood2 character varying(20) NOT NULL DEFAULT space(20),
  kood3 character varying(20) NOT NULL DEFAULT space(20),
  kood4 character varying(20) NOT NULL DEFAULT space(20),
  kood5 character varying(20) NOT NULL DEFAULT space(20),
  konto character varying(20) NOT NULL DEFAULT space(20),
  tp character varying(20) NOT NULL DEFAULT space(20),
  asutusid integer NOT NULL DEFAULT 0,
  tunnus character varying(20) NOT NULL DEFAULT space(20),
  proj character varying(20) NOT NULL DEFAULT space(1),
  CONSTRAINT pv_oper_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.pv_oper TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT ON TABLE docs.pv_oper TO dbkasutaja;
GRANT ALL ON TABLE docs.pv_oper TO dbadmin;
GRANT SELECT ON TABLE public.pv_oper TO dbvaatleja;

CREATE INDEX pv_oper_parentid_idx
  ON docs.pv_oper
  USING btree
  (parentid);

CREATE INDEX pv_oper_kaart_id_idx
  ON docs.pv_oper
  USING btree
  (pv_kaart_id);

CREATE INDEX pv_oper_nomid_idx
  ON docs.pv_oper
  USING btree
  (nomid);


CREATE INDEX pv_oper_journalid_idx
  ON docs.pv_oper using btree (journalid);

CREATE TRIGGER trigi_pv_oper_before
  BEFORE INSERT
  ON docs.pv_oper
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigi_check_docs_before();


/*
select * from docs.pv_oper

insert into docs.pv_oper (pv_kaart_id, nomid, liik, kpv, summa, asutusId)
	values (1, 1, 1, date(), 100, 1)
*/