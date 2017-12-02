--DROP TABLE if exists public.arvtasu;
DROP TABLE if exists docs.arvtasu;

CREATE TABLE docs.arvtasu
(
  id serial,
  rekvid integer NOT NULL,
  doc_arv_id integer NOT NULL,
  doc_tasu_id integer NOT NULL,
  arvid integer NOT NULL,
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  summa numeric(14,4) NOT NULL DEFAULT 0,
  dok text,
  nomid integer,
  pankkassa smallint NOT NULL DEFAULT 0,
  journalid integer,
  sorderid integer,
  muud text,
  doklausid integer,
  CONSTRAINT arvtasu_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arvtasu TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arvtasu TO dbkasutaja;
GRANT ALL ON TABLE docs.arvtasu TO dbadmin;
GRANT SELECT ON TABLE docs.arvtasu TO dbvaatleja;

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.arvtasu TO ladukasutaja;

DROP INDEX if exists docs.arvtasu_doc_arv_id;

CREATE INDEX arvtasu_doc_arv_id
  ON docs.arvtasu
  USING btree
  (doc_arv_id);

DROP INDEX if exists docs.arvtasu_doc_tasu_id;

CREATE INDEX arvtasu_doc_tasu_id
  ON docs.arvtasu
  USING btree
  (doc_tasu_id);

DROP INDEX if exists docs.arvtasu_kpv;

CREATE INDEX arvtasu_kpv
  ON docs.arvtasu
  USING btree
  (kpv);



DROP FUNCTION if exists docs.trigd_arvtasu_after();

CREATE OR REPLACE FUNCTION docs.trigd_arvtasu_after()
  RETURNS trigger AS
$BODY$
begin

	perform docs.sp_update_arv_jaak(old.ArvId, old.Kpv);
	return null;

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP FUNCTION if exists docs.trigIU_arvtasu_after();

CREATE OR REPLACE FUNCTION docs.trigIU_arvtasu_after()
  RETURNS trigger AS
$BODY$
begin

	perform docs.sp_update_arv_jaak(new.ArvId, new.Kpv);
	return null;

end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER trigd_arvtasu_after
  AFTER DELETE
  ON docs.arvtasu
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigd_arvtasu_after();

CREATE TRIGGER trigIU_arvtasu_after
  AFTER INSERT OR UPDATE
  ON docs.arvtasu
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigIU_arvtasu_after();

/*

delete from docs.arvtasu;

select summa, jaak, * from docs.arv

insert into docs.arvtasu (rekvid, doc_arv_id, doc_tasu_id, arvid, kpv, summa, dok, pankkassa, journalid, sorderid, muud, doklausid )

Select k.rekvid, a.parentid as doc_arv_id, d.id as doc_tasu_id, a.id, k.kpv, 
	CASE when k.tyyp = 1 then k.summa else -1 * k.summa end as summa,
	alltrim(k.number) || ' ' || k.kpv::text as dok,
	1 as pankkassa, null as journalid, k.id as sorderid,
	'test' as muud, null as doklausid
	From docs.korder1 k
	inner join docs.doc d on d.id = k.parentid
	inner join docs.arv a on a.id = k.arvid
WHERE  k.arvid = 11 ;


*/
