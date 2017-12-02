
drop function if exists libs.trigU_library_before();

CREATE OR REPLACE FUNCTION libs.trigU_library_before()
  RETURNS trigger AS
$BODY$
declare 
	lcErr varchar;
begin
	-- checking status

	if trim(new.library) = 'STATUS' and new.kood <> old.kood and exists (select 1 from docs.doc where status::text = old.kood limit 1) then
		lcErr = 'Ei saa muuda dokumendi status';
		raise exception 'Viga: %',lcErr;
		return null;
	end if;

return new;

end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER IF EXISTS trigU_library_before ON libs.library;

CREATE TRIGGER trigU_library_before
  BEFORE UPDATE
  ON libs.library
  FOR EACH ROW
  EXECUTE PROCEDURE libs.trigU_library_before();


-- test

/*
update libs.library set kood = '000' where kood = '0' and library = 'STATUS';

*/  

