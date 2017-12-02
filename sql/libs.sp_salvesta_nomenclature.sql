DROP FUNCTION if exists libs.sp_salvesta_nomenclature(data json, userid integer, user_rekvid integer);
    
CREATE OR REPLACE FUNCTION libs.sp_salvesta_nomenclature(data json, userid integer, user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	nom_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_data json = data->>'data';
	doc_kood text = doc_data->>'kood';
	doc_nimetus text = doc_data->>'nimetus';
	doc_dok text = doc_data->>'dok';
	doc_uhik text = doc_data->>'uhik';
	doc_hind numeric = coalesce((doc_data->>'hind')::numeric,0);
	doc_ulehind numeric = coalesce((doc_data->>'ulehind')::numeric,0);
	doc_kogus numeric = coalesce((doc_data->>'kogus')::numeric,0);
	doc_formula text = doc_data->>'formula';
	doc_kuurs numeric = coalesce((doc_data->>'kuurs')::numeric,1);
	doc_valuuta text = coalesce(doc_data->>'valuuta','EUR');
	doc_muud text = doc_data->>'muud';
	doc_vat integer = (doc_data->>'vat')::integer;
	doc_konto_db text = doc_data->>'konto_db';
	doc_konto_kr text = doc_data->>'konto_kr';
	doc_projekt text = doc_data->>'projekt';
	doc_tunnus text = doc_data->>'tunnus';
	doc_props jsonb = doc_data->>'properties';
	json_object jsonb;
	json_record record;
	new_history jsonb;
	new_rights jsonb;
	ids integer[];

	v_dokvaluuta record;
	lrCurRec record;
begin

select kasutaja into userName from userid u where u.rekvid = user_rekvid and u.id = userId;
if userName is null then
	raise notice 'User not found %', user;
	return 0;
end if;

select row_to_json(row) into json_object from (select doc_vat as vat, doc_konto_db as konto_db, doc_konto_kr as konto_kr, doc_projekt as projekt, doc_tunnus as tunnus) row;
doc_props = case when doc_props is null then  json_object else doc_props || json_object end;


if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
	select row_to_json(row) into new_rights from (select array[userId] as "select", array[userId] as "update", array[userId] as "delete") row;

	-- uus kiri
	insert into libs.nomenklatuur (rekvid, dok, kood, nimetus, uhik, hind, muud, ulehind, kogus, formula, properties) 
		values (user_rekvid, doc_dok, doc_kood, doc_nimetus, doc_uhik, doc_hind, doc_muud, doc_ulehind, doc_kogus, doc_formula, doc_props)
		returning id into nom_id;

	-- valuuta

	insert into docs.dokvaluuta1 (dokliik,dokid, valuuta, kuurs) 
		values (17, nom_id, doc_valuuta, doc_kuurs);


else
	-- muuda 

	update libs.nomenklatuur set 
		dok = doc_dok,
		kood = doc_kood,
		nimetus = doc_nimetus,
		uhik = doc_uhik,
		hind = doc_hind,
		muud = doc_muud,
		ulehind = doc_ulehind,
		kogus = doc_kogus,
		formula = doc_formula,
		properties = doc_props
	where id = doc_id
	returning id into nom_id;
end if;

-- valuuta
if not exists (select id from docs.dokvaluuta1 
	where dokliik = 17 and dokid = nom_id) then

	insert into docs.dokvaluuta1 (dokliik, dokid, valuuta, kuurs) 
		values (17, nom_id, doc_valuuta, doc_kuurs);

else
	update docs.dokvaluuta1 set 
		valuuta = doc_valuuta, 
		kuurs = doc_kuurs 
		where id in (select id from docs.dokvaluuta1 
			where dokliik = 17 and dokid = nom_id);
	
end if;

return  nom_id;

end;$BODY$
  LANGUAGE 'plpgsql' VOLATILE
  COST 100;
  
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_nomenclature(data json, userid integer, user_rekvid integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_nomenclature(data json, userid integer, user_rekvid integer) TO dbpeakasutaja;
