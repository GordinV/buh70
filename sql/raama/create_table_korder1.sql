-- Table: public.korder1

DROP TABLE if exists docs.korder1;

CREATE TABLE docs.korder1
(
  id serial,
  parentid integer NOT NULL,
  rekvid integer NOT NULL,
  userid integer NOT NULL,
  journalid integer NOT NULL,
  kassaid integer NOT NULL,
  tyyp integer NOT NULL DEFAULT 1,
  doklausid integer,
  "number" text NOT NULL,
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  asutusid integer NOT NULL,
  nimi text NOT NULL,
  aadress text,
  dokument text,
  alus text,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  muud text,
  arvid integer,
  doktyyp integer,
  dokid integer
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT ON TABLE docs.korder1 TO dbkasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.korder1 TO dbpeakasutaja;
GRANT ALL ON TABLE docs.korder1 TO dbadmin;
GRANT SELECT ON TABLE docs.korder1 TO dbvaatleja;


DROP INDEX if exists docs.korder1_rekv_idx;

CREATE INDEX korder1_rekv_idx
  ON docs.korder1
  USING btree
  (rekvid);

DROP INDEX if exists docs.korder1_kpv_idx;

CREATE INDEX korder1_kpv_idx
  ON docs.korder1
  USING btree
  (kpv);

DROP INDEX if exists docs.korder1_number_idx;

CREATE INDEX korder1_number_idx
  ON docs.korder1
  USING btree
  (number);

DROP INDEX if exists docs.korder1_parent_idx;

CREATE INDEX korder1_parent_idx
  ON docs.korder1
  USING btree
  (parentid);


CREATE INDEX korder1_asuitus_idx
  ON docs.korder1
  USING btree
  (asutusid);

  -- triggers

drop function if exists docs.trigiu_korderid_after_laekumine();
  
CREATE OR REPLACE FUNCTION docs.trigIU_korderid_after_laekumine()
  RETURNS trigger AS
$BODY$
declare 
	v_userid record;
	lresult int;
	lcNotice varchar;
begin

	if new.arvid is not null then

		delete from docs.arvtasu where arvid = new.arvid and doc_tasu_id = new.parentid;
		
		insert into docs.arvtasu (rekvid, doc_arv_id, doc_tasu_id, arvid, kpv, summa, dok, pankkassa, journalid, sorderid, muud, doklausid )
		Select k.rekvid, a.parentid as doc_arv_id, d.id as doc_tasu_id, a.id, k.kpv, 
			CASE when k.tyyp = 1 then k.summa else -1 * k.summa end as summa,
			alltrim(k.number) || ' ' || k.kpv::text as dok,
			1 as pankkassa, null as journalid, k.id as sorderid,
			k.muud as muud, null as doklausid
			From docs.korder1 k
			inner join docs.doc d on d.id = k.parentid
			inner join docs.arv a on a.id = k.arvid
			WHERE  k.arvid = new.arvid 
			and d.status > 0;

	end if;	

	if new.arvid is null and old.arvid is not null then
		delete from docs.arvtasu where arvid = new.arvid and doc_tasu_id = new.parentid;
	end if;
	return null;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER trigiu_korder1_after
  AFTER INSERT OR UPDATE
  ON docs.korder1
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigiu_korderid_after_laekumine();

/*
select * from docs.korder1

update docs.korder1 set muud = 'test' where id = 22

*/