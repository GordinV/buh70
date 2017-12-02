
DROP FUNCTION if exists docs.sp_salvesta_konto(json, integer, integer);
DROP FUNCTION if exists libs.sp_salvesta_konto(json, integer, integer);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_konto(
    data json,
    userid integer,
    user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	lib_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_data json = data->>'data';
	doc_kood text = doc_data->>'kood';
	doc_nimetus text = doc_data->>'nimetus';
	doc_library text = 'KONTOD';
	doc_tun1 integer = doc_data->>'tun1';
	doc_tun2 integer = doc_data->>'tun2';
	doc_tun3 integer = doc_data->>'tun3';
	doc_tun4 integer = doc_data->>'tun4';
	doc_tun5 integer = doc_data->>'tun5';
	doc_tyyp integer = doc_data->>'tyyp';
	doc_valid date = doc_data->>'valid';
	doc_properties text = doc_data->>'properties';
	doc_muud text = doc_data->>'muud';
	json_object json;
	json_record record;
	new_history jsonb;
	new_rights jsonb;
	ids integer[];
begin


select kasutaja into userName from userid u where u.rekvid = user_rekvid and u.id = userId;
if userName is null then
	raise notice 'User not found %', user;
	return 0;
end if;

if doc_valid is not null then
	doc_properties = coalesce(doc_properties,'') || '{"valid":"' || doc_valid || '"}'; 
end if;

raise notice 'doc_properties %, valid %', doc_properties, doc_valid;
-- вставка или апдейт docs.doc
if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
	select row_to_json(row) into new_rights from (select array[userId] as "select", array[userId] as "update", array[userId] as "delete") row;
		
	insert into libs.library (rekvid, kood, nimetus, library, tun1, tun2, tun3, tun4, tun5, muud, properties)
		values (user_rekvid, doc_kood, doc_nimetus, doc_library, doc_tun1, doc_tun2, doc_tun3, doc_tun4, doc_tyyp, doc_muud, doc_properties::jsonb) 
		returning id into lib_id;

		
else
	-- history
	select row_to_json(row) into new_history from (select now() as updated, userName as user) row;

	update libs.library set 
		kood = doc_kood,
		nimetus = doc_nimetus,
		library = doc_library,
		tun1 = doc_tun1,
		tun2 = doc_tun2,
		tun3 = doc_tun3,
		tun4 = doc_tun4,
		tun5 =  doc_tyyp,
		properties = doc_properties::jsonb,
		muud = doc_muud
		where id = doc_id returning id into lib_id;

end if;

return  lib_id;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_konto(json,integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_konto(json,integer, integer) TO dbpeakasutaja;



select libs.sp_salvesta_konto('{"id":135,"data":{"id":135,"tyyp":2,"rekvid":1,"kood":"291","nimetus":"Osakapital  nimiväärtuses","library":"KONTOD","muud":"test 123", "valid":"2017-10-31"},"details":[]}',1, 1);

/*
select * from libs.asutus


select case when l.tun5 = 1 then 'SD' when l.tun5 = 2 then 'SK' when l.tun5 = 3 then 'D' when l.tun5 = 4 then 'K' else null end::text as konto_tyyp, 
                l.id, trim(l.kood) as kood, trim(l.nimetus) as nimetus, l.library, l.tun1, l.tun2, l.tun3, l.tun4, l.muud, l.properties, 1::integer as userid, 'KONTOD' as doc_type_id, l.tun5 as tyyp, 
                (l.properties::jsonb ->> 'valid')::text as valid
                from libs.library l 
                where id = 135
*/