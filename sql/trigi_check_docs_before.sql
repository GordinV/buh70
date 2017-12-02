-- Function: docs.trigi_check_docs_before()

-- DROP FUNCTION docs.trigi_check_docs_before();

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

		case
			when (select relname::text  from pg_class where oid = TG_RELID order by oid limit 1) = 'palk_oper' then	 
				select id into doc_type_id from libs.library where library = 'DOK' and kood	= 'PALK';	
				raise notice ' palk_oper: %',doc_type_id;
			when (select relname::text  from pg_class where oid = TG_RELID order by oid limit 1) = 'palk_taabel1' then	 
				select id into doc_type_id from libs.library where library = 'DOK' and kood	= 'TAABEL';	
				raise notice ' palk_taabel: %',doc_type_id;
			when (select relname::text  from pg_class where oid = TG_RELID order by oid limit 1) = 'pv_kaart' then	 
				select id into doc_type_id from libs.library where library = 'DOK' and kood	= 'PVKAART';	
				raise notice ' pv_kaart: %',doc_type_id;
			when (select relname::text  from pg_class where oid = TG_RELID order by oid limit 1) = 'pv_oper' then	 
				select id into doc_type_id from libs.library where library = 'DOK' and kood	= 'PVOPER';	
				raise notice ' pv_oper: %',doc_type_id;
		end case;
		
		if doc_type_id is not null then
			insert into docs.doc ( doc_type_id)	
				values (doc_type_id) returning id into new.parentId;
		end if;	
	end if;
	
	return new;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION docs.trigi_check_docs_before()
  OWNER TO postgres;
