drop index if exists libs.library_kood_status;

CREATE UNIQUE INDEX library_kood_status
   ON libs.library USING btree (kood ASC NULLS LAST, library ASC NULLS LAST);

DROP FUNCTION if exists libs.trigd_library_before();

CREATE OR REPLACE FUNCTION libs.trigd_library_before()
  RETURNS trigger AS
$BODY$
declare 
	lnCount int;
	lcErr varchar;
begin
	-- checking status

	if trim(old.library) = 'STATUS' and exists (select 1 from docs.doc where status::text = old.kood limit 1) then
		lcErr = 'Ei saa kustuta dokumendi status';
		raise exception 'Viga: %',lcErr;
		return null;
	end if;

/*
	lnCount:= 0;
	if old.library = 'KONTOD' then
		select count(id) into lnCount from journal1 WHERE journal1.deebet = old.kood or journal1.kreedit = old.kood;
		if ifnull(lnCount,0) > 0 then 	
			lcErr := 'Selle kood kasutusel (paevaraamat)';		
		end if;
	end if;

	if old.library = 'PALK' then 
		select count(id) into lnCount from PALK_KAART WHERE libid = old.id;
		if ifnull(lnCount,0) > 0 then
			select count(id) into lnCount from PALK_oper WHERE libid = old.id;
		end if;
		if ifnull(lnCount,0) > 0 then
			lcErr := 'Selle kood kasutusel (palk)';		
		end if;
	end if;
	if old.library = 'POHIVARA' then 
		select count(id) into lnCount from PV_KAART WHERE parentid = old.id;
		if ifnull(lnCount,0) > 0 then
			lcErr := 'Selle kood kasutusel (pv)';		
		end if;
	end if;


	if old.library = 'ARTIKKEL' then 
		select count(id) into lnCount from journal1 WHERE journal1.kood5 = old.kood; 
		if ifnull(lnCount,0) > 0 then
			lcErr := 'Selle kood kasutusel (paevaraamat)';
		end if;
	end if;
	if old.library = 'TEGEV' then 
		select count(id) into lnCount from journal1 WHERE journal1.kood1 = old.kood; 	
		if ifnull(lnCount,0) > 0 then
			lcErr := 'Selle kood kasutusel (paevaraamat)';
		end if;
	end if;
	if old.library = 'ALLIKAD' then 
		select count(id) into lnCount from journal1 WHERE journal1.kood2 = old.kood;
		if ifnull(lnCount,0) > 0 then
			lcErr := 'Selle kood kasutusel (paevaraamat)';	
		end if;
	end if;
	if old.library = 'RAHA' then 
		select count(id) into lnCount from journal1 WHERE journal1.kood3 = old.kood; 
		if ifnull(lncount,0) > 0 then
			lcErr := 'Selle kood kasutusel (paevaraamat)';		
		end if;
	end if;
	if old.library = 'URITUS' then 
		select count(id) into lnCount from journal1 WHERE journal1.kood4 = old.kood;
		if ifnull(lnCount,0) > 0 then
			lcErr := 'Selle kood kasutusel (paevaraamat)';
		end if;
	end if;
	if old.library = 'PROJ' then 

		select count(id) into lnCount from journal1 WHERE journal1.proj = old.kood; 
		if ifnull(lnCount,0) then
			lcErr := 'Selle kood kasutusel (paevaraamat)';
		end if;

	end if;
	if old.library = 'TP' then 
		select count(id) into lnCount from journal1 WHERE journal1.lisa_d = old.kood or journal1.lisa_k = old.kood;
	end if;
	if ifnull(lnCount,0) > 0 then
		lcErr:= 'Selle kood kasutusel (paevaraamat)';		
	end if;
	if ifnull(lnCount,0) > 0 then
		raise exception 'Viga: %',lcErr;
		return null;
	end if;
*/
return old;

end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER IF EXISTS trigd_library_before ON libs.library;

CREATE TRIGGER trigd_library_before
  BEFORE DELETE
  ON libs.library
  FOR EACH ROW
  EXECUTE PROCEDURE libs.trigd_library_before();



-- test
/*
delete from libs.library where kood = '0' and library = 'STATUS'; 

*/
--select * from libs.library order by id limit 100