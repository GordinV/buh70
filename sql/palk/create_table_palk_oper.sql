-- Table: public.palk_oper

DROP TABLE if exists docs.palk_oper;

CREATE TABLE docs.palk_oper
(
  id serial,
  parentId integer NOT NULL,
  rekvid integer NOT NULL,
  libid integer NOT NULL DEFAULT 0,
  lepingid integer NOT NULL DEFAULT 0,
  kpv date NOT NULL DEFAULT ('now'::text)::date,
  summa numeric(12,4) NOT NULL DEFAULT 0,
  doklausid integer NOT NULL DEFAULT 0,
  journalid integer NOT NULL DEFAULT 0,
  journal1id integer NOT NULL DEFAULT 0,
  muud text,
  kood1 character varying(20) NOT NULL DEFAULT space(20),
  kood2 character varying(20) NOT NULL DEFAULT space(20),
  kood3 character varying(20) NOT NULL DEFAULT space(20),
  kood4 character varying(20) NOT NULL DEFAULT space(20),
  kood5 character varying(20) NOT NULL DEFAULT space(20),
  konto character varying(20) NOT NULL DEFAULT space(20),
  tp character varying(20) NOT NULL DEFAULT space(20),
  tunnus character varying(20) NOT NULL DEFAULT space(20),
  proj character varying(20) NOT NULL DEFAULT space(1),
  palk_lehtid integer,
  tulumaks numeric(18,2),
  sotsmaks numeric(18,2),
  tootumaks numeric(18,2),
  pensmaks numeric(18,2),
  tulubaas numeric(18,2),
  tka numeric(18,2),
  period date,
  pohjus character varying(20),
  CONSTRAINT palk_oper_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=TRUE
);

GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.palk_oper TO dbpeakasutaja;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE docs.palk_oper TO dbkasutaja;
GRANT ALL ON TABLE docs.palk_oper TO dbadmin;
GRANT SELECT ON TABLE docs.palk_oper TO dbvaatleja;

-- Index: public.ix_palk_oper

-- DROP INDEX public.ix_palk_oper;

CREATE INDEX ix_palk_oper
  ON docs.palk_oper
  USING btree
  (rekvid);

-- Index: public.ix_palk_oper_1

-- DROP INDEX public.ix_palk_oper_1;

CREATE INDEX ix_palk_oper_1
  ON docs.palk_oper
  USING btree
  (libid);

-- Index: public.ix_palk_oper_kpv

-- DROP INDEX public.ix_palk_oper_kpv;

CREATE INDEX ix_palk_oper_kpv
  ON docs.palk_oper
  USING btree
  (kpv);

-- Index: public.palk_oper_journalid

-- DROP INDEX public.palk_oper_journalid;

CREATE INDEX palk_oper_journalid
  ON docs.palk_oper
  USING btree
  (journalid);

-- Index: public.palk_oper_lepingid

-- DROP INDEX public.palk_oper_lepingid;

CREATE INDEX palk_oper_lepingid
  ON docs.palk_oper
  USING btree
  (lepingid);



CREATE OR REPLACE FUNCTION docs.trigi_check_docs_before()
  RETURNS trigger AS
$BODY$
declare 
	doc_type_id integer;
begin
	if (select id from docs.doc d where id = new.parentId) is null then
		-- will find id in library according to code (doktype)	

		-- find table name (TG_RELID)
		raise notice ' called from %', TG_RELID;

		if (select relname::text  from pg_class where oid = TG_RELID order by oid limit 1) = 'palk_oper' then	 
			select id into doc_type_id from library where library = 'DOK' and kood	= 'PALK';	
			raise notice ' palk_oper: %',doc_type_id;
		end if;
		
		if doc_type_id is not null then
			insert into docs.doc ( doc_type_id)	
				values (doc_type_id);
				--returning id into new.parentId;
            SELECT currval('docs.doc_id_seq') into new.parentId;

        end if;
	end if;
	
	return new;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER trigi_palk_oper_before
  BEFORE INSERT
  ON docs.palk_oper
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigi_check_docs_before();

/*
select * from docs.palk_oper

insert into docs.palk_oper (rekvid, libid, lepingid, kpv, summa)
	values (1, 0, 1, date(), 200)

select relname  from pg_class where oid = 28149 order by oid limit 1

select * from docs.doc

update docs.palk_oper set lepingid = 2 where lepingid = 0

*/