
DROP FUNCTION if exists docs.sp_salvesta_arv(json, integer, integer);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_arv(
    data json,
    userid integer,
    user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	arv_id integer;
	arv1_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_type_kood text = 'ARV'/*data->>'doc_type_id'*/;
	doc_type_id integer = (select id from libs.library where kood = doc_type_kood and library = 'DOK' limit 1);
	doc_details json = data->>'details';
	doc_data json = data->>'data';
	doc_number text = doc_data->>'number';
	doc_summa numeric(14,4) = coalesce((doc_data->>'summa')::numeric,0);
	doc_liik integer = doc_data->>'liik';
	doc_operid integer = doc_data->>'operid';
	doc_asutusid integer = doc_data->>'asutusid';
	doc_lisa text = doc_data->>'lisa';
	doc_kpv date = doc_data->>'kpv';
	doc_tahtaeg date = doc_data->>'tahtaeg';
	doc_kbmta numeric(14,4) = coalesce((doc_data->>'kbmta')::numeric,0);
	doc_kbm numeric(14,4) = coalesce((doc_data->>'kbm')::numeric,0);
	doc_muud text = doc_data->>'muud';
	doc_objektid integer = doc_data->>'objektid';
	doc_objekt text = doc_data->>'objekt';
	tcValuuta text = coalesce(doc_data->>'valuuta','EUR'); 
	tnKuurs numeric(14,8) = coalesce(doc_data->>'kuurs','1'); 
	tnDokLausId integer = coalesce((doc_data->>'doklausid')::integer,1);
	json_object json;
	json_record record;
	new_history jsonb;
	new_rights jsonb;
	ids integer[];
begin

if doc_number is null or doc_number = '' then
	-- присвоим новый номер
	doc_number = docs.sp_get_number(user_rekvid, 'ARV', YEAR(doc_kpv), tnDokLausId);
end if;

raise notice 'data.doc_details: %, jsonb_array_length %, data: %', doc_details, json_array_length(doc_details), data;

select kasutaja into userName from userid u where u.rekvid = user_rekvid and u.id = userId;
if userName is null then
	raise notice 'User not found %', user;
	return 0;
end if;

-- вставка или апдейт docs.doc
if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
	select row_to_json(row) into new_rights from (select array[userId] as "select", array[userId] as "update", array[userId] as "delete") row;
		
	
	insert into docs.doc (doc_type_id, history, rigths, rekvId ) 
		values (doc_type_id, '[]'::jsonb || new_history,new_rights, user_rekvid) 
		returning id into doc_id;

	insert into docs.arv (parentid, rekvid, userid, liik ,operid, number, kpv, asutusid, lisa, tahtaeg, kbmta, kbm, summa, muud, objektid, objekt, doklausid)
		values (doc_id, user_rekvid, userId, doc_liik ,doc_operid, doc_number, doc_kpv, doc_asutusid, doc_lisa, doc_tahtaeg, doc_kbmta, doc_kbm, doc_summa, 
		doc_muud, doc_objektid, doc_objekt, tnDokLausId) 
		returning id into arv_id;

	insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
		values (arv_id,3,tcValuuta, tnKuurs);

		
else
	-- history
	select row_to_json(row) into new_history from (select now() as updated, userName as user) row;

	update docs.doc 
		set lastupdate = now(),
			history = coalesce(history,'[]')::jsonb || new_history,
			rekvid = user_rekvid
		where id = doc_id;	

	update docs.arv set 
		liik = doc_liik,
		operid = doc_operid, 
		number = doc_number, 
		kpv = doc_kpv, 
		asutusid = doc_asutusid, 
		lisa = doc_lisa, 
		tahtaeg = doc_tahtaeg, 
		kbmta = coalesce(doc_kbmta,0), 
		kbm = coalesce(doc_kbm,0), 
		summa = coalesce(doc_summa,0), 
		muud = doc_muud, 
		objektid = doc_objektid, 
		objekt = doc_objekt,
		doklausid = tnDokLausId
		where parentid = doc_id returning id into arv_id;

	-- arv jaak 	

	perform docs.sp_update_arv_jaak(arv_id, doc_kpv);

end if;
-- вставка в таблицы документа


for json_object in 
	select * from json_array_elements(doc_details)
loop
	select * into json_record from json_to_record(json_object) as x(id text, nomId integer, kogus numeric(14,4), hind numeric(14,4), kbm numeric(14,4),summa numeric(14,4), kood text, nimetus text);
--	raise notice 'json_record: %, nomid %', json_record, json_record.nomid;
	if json_record.id is null or json_record.id = '0' or substring(json_record.id from 1 for 3) = 'NEW' then
		insert into docs.arv1 (parentid, nomid, kogus, hind, kbm, summa)
			values (arv_id, json_record.nomid, 
			coalesce(json_record.kogus,0), 
			coalesce(json_record.hind,0),  
			coalesce(json_record.kbm,0), 
			coalesce(json_record.summa,0)) returning id into arv1_id;

		-- valuuta
		insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
			values (arv1_id,2,tcValuuta, tnKuurs);

		-- add new id into array of ids
		ids = array_append(ids,arv1_id);	
			
	else
		update docs.arv1 set 
			parentid = arv_id, 
			nomid = json_record.nomid, 
			kogus = coalesce(json_record.kogus,0), 
			hind = coalesce(json_record.hind,0), 
			kbm = coalesce(json_record.kbm,0), 
			summa = coalesce(json_record.summa, kogus * hind)
			where id = json_record.id::integer returning id into arv1_id;

		-- add new id into array of ids
		ids = array_append(ids,arv1_id);		

		if not exists (select id from docs.dokvaluuta1 where dokid = arv1_id and dokliik = 2) then
		-- if record does 
			insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
				values (arv1_id,2,tcValuuta, tnKuurs);

		end if;		
	end if;

end loop;	


-- delete record which not in json

delete from docs.arv1 where parentid = arv_id and id not in (select unnest(ids));


-- update arv summad
select sum(summa) as summa, sum(kbm) as kbm into doc_summa, doc_kbm
	from docs.arv1 
	where parentid = arv_id;

update docs.arv set 
	kbmta = coalesce(doc_summa,0) - coalesce(doc_kbm,0), 
	kbm = coalesce(doc_kbm,0), 
	summa = coalesce(doc_summa,0)
	where parentid = doc_id;

	

/*
perform docs.sp_updatearvjaak(arv_id, date());
	perform sp_updatearvjaak(tnParentId, date());

-- Ladu

	if (select count(id) from ladu_grupp where ladu_grupp.nomId = tnnomId) > 0 then
		select rekvid into lnRekvid from arv where id = tnParentid;
		perform sp_recalc_ladujaak(lnRekvId, tnNomId, 0);
	end if;
*/
         return  doc_id;
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(json,integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_arv(json,integer, integer) TO dbpeakasutaja;



select docs.sp_salvesta_arv('{"id":0,"doc_type_id":"ARV","data":{"id":0,"created":"2016-05-05T21:39:57.050726","lastupdate":"2016-05-05T21:39:57.050726","bpm":null,"doc":"Arved","doc_type_id":"ARV","status":"Черновик","number":"321","summa":24,"rekvid":null,"liik":0,"operid":null,"kpv":"2016-05-05","asutusid":1,"arvid":null,"lisa":"lisa","tahtaeg":"2016-05-19","kbmta":null,"kbm":4,"tasud":null,"tasudok":null,"muud":"muud","jaak":"0.00","objektid":null,"objekt":null,"regkood":null,"asutus":null},
"details":[{"id":"NEW0.6577064044198089","[object Object]":null,"nomid":"1","kogus":2,"hind":10,"kbm":4,"kbmta":20,"summa":24,"kood":"PAIGALDUS","nimetus":"PV paigaldamine"}]}',1, 1);

