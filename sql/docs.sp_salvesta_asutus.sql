
DROP FUNCTION if exists docs.sp_salvesta_asutus(json, integer, integer);
DROP FUNCTION if exists libs.sp_salvesta_asutus(json, integer, integer);

CREATE OR REPLACE FUNCTION libs.sp_salvesta_asutus(
    data json,
    userid integer,
    user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	asutus_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_data json = data->>'data';
	doc_regkood text = doc_data->>'regkood';
	doc_nimetus text = doc_data->>'nimetus';
	doc_omvorm text = doc_data->>'omvorm';
	doc_kontakt text = doc_data->>'kontakt';
	doc_aadress text = doc_data->>'aadress';
	doc_tel text = doc_data->>'tel';
	doc_email text = doc_data->>'email';
	doc_mark text = doc_data->>'mark';
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

-- вставка или апдейт docs.doc
if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
	select row_to_json(row) into new_rights from (select array[userId] as "select", array[userId] as "update", array[userId] as "delete") row;
		
	insert into libs.asutus (rekvid, regkood, nimetus,omvorm, kontakt, aadress, tel, email, mark, muud)
		values (user_rekvid, doc_regkood, doc_nimetus, doc_omvorm, doc_kontakt, doc_aadress, doc_tel, doc_email, doc_mark, doc_muud) 
		returning id into asutus_id;

		
else
	-- history
	select row_to_json(row) into new_history from (select now() as updated, userName as user) row;

	update libs.asutus set 
		regkood = doc_regkood,
		nimetus = doc_nimetus,
		omvorm = doc_omvorm,
		kontakt = doc_kontakt,
		aadress = doc_aadress,
		tel = doc_tel,
		email = doc_email,
		mark =  doc_mark,
		muud = doc_muud
		where id = doc_id returning id into asutus_id;

end if;

return  asutus_id;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_salvesta_asutus(json,integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_salvesta_asutus(json,integer, integer) TO dbpeakasutaja;


/*
select docs.sp_salvesta_asutus('{"id":0,"data":{"id":0,"number":"321","summa":24,"rekvid":null,"liik":0,"operid":null,"kpv":"2016-05-05","asutusid":1,"arvid":null,"lisa":"lisa","tahtaeg":"2016-05-19","kbmta":null,"kbm":4,"tasud":null,"tasudok":null,"muud":"muud","jaak":"0.00","objektid":null,"objekt":null,"regkood":null,"asutus":null},
"details":[{"id":"NEW0.6577064044198089","[object Object]":null,"nomid":"1","kogus":2,"hind":10,"kbm":4,"kbmta":20,"summa":24,"kood":"PAIGALDUS","nimetus":"PV paigaldamine"}]}',1, 1);

select * from libs.asutus

*/