-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION if exists docs.sp_salvesta_mk(json, integer, integer);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_mk(
    data json,
    userid integer,
    user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	mk_id integer;
	mk1_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_type_kood text = data->>'doc_type_id';
	doc_type_id integer = (select id from libs.library where ltrim(rtrim(kood)) = ltrim(rtrim(upper(doc_type_kood))) and library = 'DOK' limit 1);
	doc_details json = data->>'details';
	doc_data json = data->>'data';
	doc_number text = coalesce(doc_data->>'number','1');
	doc_opt text = coalesce(doc_data->>'opt','0'); -- 0 -> smk, 1 -> vmk
	doc_kpv date = doc_data->>'kpv';
	doc_aa_id integer = doc_data->>'aa_id';
	doc_arvid integer = doc_data->>'arvid';
	doc_muud text = doc_data->>'muud';
	tcValuuta text = coalesce(doc_data->>'valuuta','EUR') ; 
	tnKuurs numeric(14,8) = coalesce(doc_data->>'kuurs','1'); 
	doc_doklausid integer = doc_data->>'doklausid';
	doc_maksepaev date = doc_data->>'maksepaev';
	doc_selg text = doc_data->>'selg'; 
	doc_viitenr text = doc_data->>'viitenr'; 
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

if doc_aa_id is null then
	select id into doc_aa_id from ou.aa where parentId = user_rekvid and pank = 1  order by default_ desc limit 1;
	if not found then
		raise notice 'pank not found %', doc_aa_id;
		return 0;
	else 
		raise notice 'pank: %', doc_aa_id;	
	end if;
end if;

-- вставка или апдейт docs.doc

	raise notice 'doc_id %', doc_id; 

if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
		
	
	insert into docs.doc (doc_type_id, history, rekvid ) 
		values (doc_type_id, '[]'::jsonb || new_history, user_rekvid) 
		returning id into doc_id;

	insert into docs.mk (parentid, rekvid, kpv, opt, aaId, number, muud,  arvid, doklausid, maksepaev, selg, viitenr)
		values (doc_id, user_rekvid, doc_kpv, doc_opt::integer, doc_aa_id, doc_number, doc_muud,  coalesce(doc_arvid,0), 
		coalesce(doc_doklausid,0), coalesce(doc_maksepaev,doc_kpv), coalesce(doc_selg,''), coalesce(doc_viitenr,'')) 
		returning id into mk_id;
		
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


	update docs.mk set 
		kpv = doc_kpv, 
		aaid = doc_aa_id, 
		number = doc_number, 
		muud = doc_muud, 
		arvid = coalesce(doc_arvid,0),
		doklausid = coalesce(doc_doklausid,0), 
		maksepaev = coalesce(doc_maksepaev,doc_kpv), 
		selg = coalesce(doc_selg,''), 
		viitenr = coalesce(doc_viitenr,'')
		where parentid = doc_id returning id into mk_id;

end if;
-- вставка в таблицы документа


for json_object in 
	select * from json_array_elements(doc_details)
loop
	select * into json_record from json_to_record(json_object) as x(id text,asutusid integer, nomid integer, summa numeric(14,4), aa text, pank text,  
	tunnus text, proj text,	konto text, kood1 text, kood2 text, kood3 text, kood4 text, kood5 text, tp text,  valuuta text, kuurs numeric(14,8));

	if json_record.id is null or json_record.id = '0' or substring(json_record.id from 1 for 3) = 'NEW' or not exists (select id from docs.mk1 where id = json_record.id::integer) then

		insert into docs.mk1 (parentid, asutusid, nomid, summa, aa, pank, tunnus, proj,konto, kood1, kood2, kood3, kood4, kood5, tp)
			values (mk_id, json_record.asutusid, json_record.nomid, json_record.summa, json_record.aa, json_record.pank, 
			json_record.tunnus, json_record.proj,json_record.konto,
			json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5, json_record.tp)
			 
			returning id into mk1_id;

		-- add new id into array of ids
		ids = array_append(ids, mk1_id);

		-- valuuta
		insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
			values (mk1_id, 4 ,tcValuuta, tnKuurs);

			
	else
	
		update docs.mk1 set 
			nomid =json_record.nomid,
			asutusid = json_record.asutusid,
			summa = json_record.summa,
			aa = json_record.aa,
			pank = json_record.pank,
			tunnus = json_record.tunnus,
			proj = json_record.proj,
			kood1 = json_record.kood1,
			kood2 = json_record.kood2,
			kood3 = json_record.kood3,
			kood4 = json_record.kood4,
			kood5 = json_record.kood5,
			tp = json_record.tp
			where id = json_record.id::integer;
			
		mk1_id = json_record.id::integer;

		-- add existing id into array of ids
		ids = array_append(ids,mk1_id);

		if not exists (select id from docs.dokvaluuta1 where dokid = mk1_id and dokliik = 1) then
		-- if record does 
			insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
				values (mk1_id, 4, tcValuuta, tnKuurs);

		end if;		
	end if;

	-- delete record which not in json

	delete from docs.korder2 where parentid = mk_id and id not in (select unnest(ids));
	
	
end loop;	

return  doc_id;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(json, integer, integer) TO public;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(json, integer, integer) TO postgres;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(json, integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_mk(json, integer, integer) TO dbpeakasutaja;


/*
select docs.sp_salvesta_mk('{"id":0,"doc_type_id":"SMK","data":{"id":0,"created":"2017-06-24T21:39:57.050726","lastupdate":"2017-06-24T21:39:57.050726","selg":"test mk",
"bpm":null,"doc":"v mk","doc_type_id":"SMK","status":"Черновик","number":"001-SMK","summa":24,"rekvid":null,"opt":1,"kpv":"2017-06-24","asutusid":1, "maksepaev":"2017-06-24",
"arvid":null,"lisa":"lisa","tahtaeg":"2017-07-01","muud":"smk muud"},
"details":[{"id":"NEW0.6577064044198089","nomid":"1","summa":24,"aa":"aatest","pank":"767", "asutusid":1}]}',1, 1);


insert into libs.library (rekvid, kood, nimetus, library)
	values (1, 'SMK','Sissemakse korraldus','DOK')

select * from libs.library where library = 'DOK'

select * from ou.aa

insert into ou.aa (parentid, arve, nimetus, pank, konto)
	values (1, 'EE1000', 'PANK1', 1, '113')
select * from docs.mk

delete from docs.mk1 where parentid > 10
*/