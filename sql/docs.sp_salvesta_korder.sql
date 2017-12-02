
DROP FUNCTION if exists docs.sp_salvesta_korder(json, integer, integer);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_korder(
    data json,
    userid integer,
    user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	korder_id integer;
	korder1_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_data json = data->>'data';
	doc_tyyp text = coalesce(doc_data->>'tyyp','1'); -- 1 -> sorder, 2 -> vorder
	doc_type_kood text = case when doc_tyyp = '1' then 'SORDER' else 'VORDER' end/*data->>'doc_type_id'*/;
	doc_type_id integer = (select id from libs.library where ltrim(rtrim(upper(kood))) = ltrim(rtrim(upper(doc_type_kood))) and library = 'DOK' limit 1);
	doc_details json = data->>'details';
	doc_number text = coalesce(doc_data->>'number','1');
	doc_kpv date = doc_data->>'kpv';
	doc_asutusid integer = doc_data->>'asutusid';
	doc_kassa_id integer = doc_data->>'kassa_id';
	doc_dokument text = doc_data->>'dokument';
	doc_nimi text = doc_data->>'nimi';
	doc_aadress text = doc_data->>'aadress';
	doc_alus text = doc_data->>'alus';
	doc_arvid integer = doc_data->>'arvid';
	doc_muud text = doc_data->>'muud';
	doc_summa numeric = doc_data->>'summa';
	tcValuuta text = coalesce(doc_data->>'valuuta','EUR') ; 
	tnKuurs numeric(14,8) = coalesce(doc_data->>'kuurs','1'); 
	json_object json;
	json_record record;
	new_history jsonb;
	ids integer[];
	docs integer[];
	arv_parent_id integer;
begin

raise notice 'data.doc_details: %, jsonb_array_length %, data: %', doc_details, json_array_length(doc_details), data;

select kasutaja into userName from userid u where u.rekvid = user_rekvid and u.id = userId;
if userName is null then
	raise notice 'User not found %', user;
	return 0;
end if;

raise notice 'kassaId %', doc_kassa_id;

if doc_kassa_id is null then
	select id into doc_kassa_id from ou.aa where parentId = user_rekvid and kassa = 1  order by default_ desc limit 1;
	if not found then
		raise notice 'Kassa not found %', doc_kassa_id;
		return 0;
	else 
		raise notice 'kassa: %', doc_kassa_id;	
	end if;
end if;
-- вставка или апдейт docs.doc
if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
		
	
	insert into docs.doc (doc_type_id, history, rekvid ) 
		values (doc_type_id, '[]'::jsonb || new_history, user_rekvid) 
		returning id into doc_id;

	insert into docs.korder1 (parentid, rekvid, userid, kpv, asutusid, tyyp, kassaId, number, dokument, nimi, aadress, alus, muud, summa, arvid)
		values (doc_id, user_rekvid, userId, doc_kpv, doc_asutusid, doc_tyyp::integer, doc_kassa_id, doc_number, doc_dokument, doc_nimi, 
		doc_aadress, doc_alus, doc_muud, doc_summa, doc_arvid) 
		returning id into korder_id;

		
else
	select row_to_json(row) into new_history from (select now() as updated, userName as user) row;


	-- устанавливаем связи с документами

	-- получим связи документа
	select docs_ids into docs from docs.doc where id = doc_id;	

	
	if doc_arvid is not null then
		select parentid into arv_parent_id from docs.arv where id = doc_arvid;
		if (select count(*) from (
				select unnest(docs) as element) qry
				where element = arv_parent_id) = 0
		then
			docs = 	array_append(docs,arv_parent_id);
		end if;
	end if;

	update docs.doc 
		set 
			docs_ids = docs,
			lastupdate = now(),
			history = coalesce(history,'[]')::jsonb || new_history
		where id = doc_id;	


	update docs.korder1 set 
		kpv = doc_kpv, 
		asutusid = doc_asutusid, 
		dokument = doc_dokument, 
		kassaid = doc_kassa_id, 
		number = doc_number, 
		nimi = doc_nimi, 
		aadress = doc_aadress, 
		muud = doc_muud, 
		alus = doc_alus,
		summa = doc_summa,
		arvid = doc_arvid
		where parentid = doc_id returning id into korder_id;

end if;
-- вставка в таблицы документа


for json_object in 
	select * from json_array_elements(doc_details)
loop
	select * into json_record from json_to_record(json_object) as x(id text, nomid integer, summa numeric(14,4), nimetus text, tunnus text, proj text,
	konto text, kood1 text, kood2 text, kood3 text, kood4 text, kood5 text, tp text,  valuuta text, kuurs numeric(14,8));

	if json_record.nimetus is null then
		json_record.nimetus = (select nimetus from libs.nomenklatuur where id = json_record.nomid);
	end if;	

	if json_record.id is null or json_record.id = '0' or substring(json_record.id from 1 for 3) = 'NEW' or not exists (select id from docs.journal1 where id = json_record.id::integer) then
		insert into docs.korder2 (parentid, nomid, nimetus, summa, tunnus, proj,konto, kood1, kood2, kood3, kood4, kood5, tp)
			values (korder_id, json_record.nomid, json_record.nimetus, json_record.summa, json_record.tunnus, json_record.proj,json_record.konto,
			json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5, json_record.tp)
			 
			returning id into korder1_id;

		-- add new id into array of ids
		ids = array_append(ids, korder1_id);

		-- valuuta
		insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
			values (korder1_id, 10 ,tcValuuta, tnKuurs);

			
	else
	
		update docs.korder2 set 
			nomid =json_record.nomid,
			nimetus =json_record.nimetus,
			summa = json_record.summa,
			tunnus = json_record.tunnus,
			proj = json_record.proj,
			kood1 = json_record.kood1,
			kood2 = json_record.kood2,
			kood3 = json_record.kood3,
			kood4 = json_record.kood4,
			kood5 = json_record.kood5,
			tp = json_record.tp
			where id = json_record.id::integer;
			
		korder1_id = json_record.id::integer;

		-- add existing id into array of ids
		ids = array_append(ids,korder1_id);

		if not exists (select id from docs.dokvaluuta1 where dokid = korder1_id and dokliik = 1) then
		-- if record does 
			insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
				values (korder1_id, 10, tcValuuta, tnKuurs);

		end if;		
	end if;

	-- delete record which not in json

	delete from docs.korder2 where parentid = korder_id and id not in (select unnest(ids));
	
	
end loop;	

return  doc_id;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_korder(json, integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_korder(json, integer, integer) TO dbpeakasutaja;

/*
saving data:
{"id":59,"doc_type_id":"SORDER","data":{"id":59,"docs_ids":null,"created":"2016-06-01T09:54:40.504143","lastupdate":"2016-06-01T09:54:40.504143",
"bpm":null,"doc":"Sissemakse kassaorder","doc_type_id":"SORDER","status":"Черновик","number":"1","summa":"100.0000","rekvid":1,"kpv":"2016-05-31",
"asutusid":1,"dokument":"Arve сохранен","alus":"test","muud":"muud","nimi":"isik","aadress":"адрес","regkood":"123456789           ","asutus":"isik, töötaja"},
"details":[
{"kood":"PANK","nimetus":"paNK","uhik":"","id":6,"parentid":14,"nomid":3,"summa":"100.0000","konto":"113","kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"tp":null,"tunnus":"tunnus","proj":"proj"}]}

select docs.sp_salvesta_korder('{"id":0,"doc_type_id":"VORDER","data":{"id":59,"docs_ids":null,"created":"2016-06-01T09:54:40.504143","lastupdate":"2016-06-01T09:54:40.504143",
"bpm":null,"doc":"Sissemakse kassaorder","doc_type_id":"VORDER","status":"Черновик","number":"1","summa":"100.0000","rekvid":1,"kpv":"2016-05-31",
"asutusid":1,"dokument":"Arve сохранен","alus":"test","muud":"muud","nimi":"isik","aadress":"адрес","tyyp":2, "regkood":"123456789           ","asutus":"isik, töötaja"},
"details":[
{"kood":"PANK","nimetus":"paNK","uhik":"","id":6,"parentid":14,"nomid":3,"summa":"100.0000","konto":"113","kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"tp":null,"tunnus":"tunnus","proj":"proj"}]}
',1, 1);

select * from libs.nomenklatuur where dok = 'SORDER' limit 10
*/
