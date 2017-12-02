DROP FUNCTION if exists libs.sp_salvesta_library(data json, userid integer, user_rekvid integer);
    
CREATE OR REPLACE FUNCTION libs.sp_salvesta_library(data json, userid integer, user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	lib_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_data json = data->>'data';
	doc_kood text = doc_data->>'kood';
	doc_nimetus text = doc_data->>'nimetus';
	doc_library text = doc_data->>'library';
	doc_muud text = doc_data->>'muud';
	doc_type text = (doc_data->>'type');
	doc_module text = doc_data->>'module';
	doc_props jsonb = doc_data->>'properties';
	json_object jsonb;
	new_history jsonb;
	new_rights jsonb;

	v_dokvaluuta record;
	lrCurRec record;
begin

select kasutaja into userName from userid u where u.rekvid = user_rekvid and u.id = userId;
if userName is null then
	raise notice 'User not found %', user;
	return 0;
end if;

if doc_library = 'DOK' and doc_module is null and doc_type = 'library' then
	-- @todo hardcode, 
	doc_module = '["Libraries"]';
	select row_to_json(row) into json_object from (select doc_module as module) row;
end if;
	
doc_props = case when doc_props is null then  json_object else doc_props || json_object end;


if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
	select row_to_json(row) into new_rights from (select array[userId] as "select", array[userId] as "update", array[userId] as "delete") row;

	-- uus kiri
	insert into libs.library (rekvid, library, kood, nimetus, muud, properties) 
		values (user_rekvid, doc_library, doc_kood, doc_nimetus, doc_muud, doc_props)
		returning id into lib_id;

else
	-- muuda 

	update libs.library set 
		kood = doc_kood,
		nimetus = doc_nimetus,
		muud = doc_muud,
		properties = doc_props
	where id = doc_id
	returning id into lib_id;
end if;

return  lib_id;

end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(data json, userid integer, user_rekvid integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_library(data json, userid integer, user_rekvid integer) TO dbpeakasutaja;
