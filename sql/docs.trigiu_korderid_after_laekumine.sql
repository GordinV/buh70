-- Function: docs.trigiu_korderid_after_laekumine()

-- DROP FUNCTION docs.trigiu_korderid_after_laekumine();

CREATE OR REPLACE FUNCTION docs.trigiu_korderid_after_laekumine()
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

	if new.arvid is null and TG_OP = 'UPDATE' and old.arvid is not null then
		delete from docs.arvtasu where arvid = new.arvid and doc_tasu_id = new.parentid;
	end if;
	return null;
end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION docs.trigiu_korderid_after_laekumine()
  OWNER TO postgres;
