
DROP FUNCTION if exists docs.sp_salvesta_journal(json, integer, integer);

CREATE OR REPLACE FUNCTION docs.sp_salvesta_journal(
    data json,
    userid integer,
    user_rekvid integer)
  RETURNS integer AS
$BODY$

declare
	journal_id integer;
	journal1_id integer;
	userName text;
	doc_id integer = data->>'id';	
	doc_type_kood text = 'JOURNAL'/*data->>'doc_type_id'*/;
	doc_type_id integer = (select id from libs.library where kood = doc_type_kood and library = 'DOK' limit 1);
	doc_details json = data->>'details';
	doc_data json = data->>'data';
	doc_number text = doc_data->>'number';
	doc_asutusid integer = doc_data->>'asutusid';
	doc_dok text = doc_data->>'dok';
	doc_kpv date = doc_data->>'kpv';
	doc_selg text = doc_data->>'selg';
	doc_muud text = doc_data->>'muud';
	tcValuuta text = coalesce(doc_data->>'valuuta','EUR') ; 
	tnKuurs numeric(14,8) = coalesce(doc_data->>'kuurs','1'); 
	json_object json;
	json_record record;
	new_history jsonb;
	ids integer[];
begin

raise notice 'data.doc_details: %, jsonb_array_length %, data: %', doc_details, json_array_length(doc_details), data;

select kasutaja into userName from userid u where u.rekvid = user_rekvid and u.id = userId;
if userName is null then
	raise notice 'User not found %', user;
	return 0;
end if;

-- вставка или апдейт docs.doc
if doc_id is null or doc_id = 0 then

	select row_to_json(row) into new_history from (select now() as created, userName as user) row;
		
	
	insert into docs.doc (doc_type_id, history, rekvid ) 
		values (doc_type_id, '[]'::jsonb || new_history, user_rekvid) 
		returning id into doc_id;

	insert into docs.journal (parentid, rekvid, userid, kpv, asutusid, dok, selg, muud)
		values (doc_id, user_rekvid, userId, doc_kpv, doc_asutusid, doc_dok, doc_selg, doc_muud) 
		returning id into journal_id;

	insert into docs.journalid (journalid, rekvid, aasta, number)
		values (journal_id, user_rekvid, (date_part('year'::text, doc_kpv)::integer), (select max(number) + 1 from docs.journalid where rekvId = user_rekvid and aasta = (date_part('year'::text, doc_kpv)::integer)));

		
else
	select row_to_json(row) into new_history from (select now() as updated, userName as user) row;

	update docs.doc 
		set lastupdate = now(),
			history = coalesce(history,'[]')::jsonb || new_history
		where id = doc_id;	

	update docs.journal set 
		kpv = doc_kpv, 
		asutusid = doc_asutusid, 
		dok = doc_dok, 
		muud = doc_muud, 
		selg = doc_selg
		where parentid = doc_id returning id into journal_id;

end if;
-- вставка в таблицы документа


for json_object in 
	select * from json_array_elements(doc_details)
loop
	select * into json_record from json_to_record(json_object) as x(id text, summa numeric(14,4), deebet text, kreedit text, tunnus text, proj text,
	kood1 text, kood2 text, kood3 text, kood4 text, kood5 text, lisa_d text, lisa_k text, valuuta text, kuurs numeric(14,8));

	if json_record.id is null or json_record.id = '0' or substring(json_record.id from 1 for 3) = 'NEW' or not exists (select id from docs.journal1 where id = json_record.id::integer) then
		insert into docs.journal1 (parentid, deebet, kreedit, summa, tunnus, proj, kood1, kood2, kood3, kood4, kood5, lisa_d, lisa_k, valuuta, kuurs, valsumma)
			values (journal_id, json_record.deebet, json_record.kreedit, json_record.summa, json_record.tunnus, json_record.proj,
			json_record.kood1, json_record.kood2, json_record.kood3, json_record.kood4, json_record.kood5, json_record.lisa_d, json_record.lisa_k,
			coalesce(json_record.valuuta,'EUR'), coalesce(json_record.kuurs,1), coalesce(json_record.kuurs,1) * json_record.summa) 
			returning id into journal1_id;

		raise notice 'journal1_id %', journal1_id;	

		-- add new id into array of ids
		ids = array_append(ids,journal1_id);

		-- valuuta
		insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
			values (journal1_id, 1 ,tcValuuta, tnKuurs);

			
	else
	
		update docs.journal1 set 
			deebet = json_record.deebet, 
			kreedit = json_record.kreedit, 
			summa = json_record.summa,
			tunnus = json_record.tunnus,
			proj = json_record.proj,
			kood1 = json_record.kood1,
			kood2 = json_record.kood2,
			kood3 = json_record.kood3,
			kood4 = json_record.kood4,
			kood5 = json_record.kood5,
			lisa_d = json_record.lisa_d,
			lisa_k = json_record.lisa_k,
			kuurs = json_record.kuurs,
			valuuta = json_record.valuuta,
			valsumma = json_record.kuurs * json_record.summa
			where id = json_record.id::integer;
			
		journal1_id = json_record.id::integer;

		-- add existing id into array of ids
		ids = array_append(ids,journal1_id);


		raise notice 'for update journal1_id %', journal1_id;	


		if not exists (select id from docs.dokvaluuta1 where dokid = journal1_id and dokliik = 1) then
		-- if record does 
			insert into docs.dokvaluuta1 (dokid, dokliik, valuuta, kuurs) 
				values (journal1_id, 1, tcValuuta, tnKuurs);

		end if;		
	end if;

	-- delete record which not in json

	delete from docs.journal1 where parentid = journal_id and id not in (select unnest(ids));
	

end loop;	

return  doc_id;

end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  

GRANT EXECUTE ON FUNCTION docs.sp_salvesta_journal(json, integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_salvesta_journal(json, integer, integer) TO dbpeakasutaja;

/*
sasaving data:{"id":40,"doc_type_id":"JOURNAL","data":{"id":40,"created":"2016-05-24T14:49:46.198805","lastupdate":"2016-05-25T14:15:08.329755","bpm":null,"doc":"Lausendid","doc_type_id":"JOURNAL","status":"Черновик","number":2,"rekvid":1,"kpv":"2016-05-21","asutusid":1,"dok":"lisa 3","selg":"selg parandus","muud":"muud","summa":122.01,"regkood":"123456789           ","asutus":"isik, töötaja"},"details":[
{"id":16,"parentid":14,"summa":"100.0000","dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"113","lisa_k":null,"kreedit":"122","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"100.0000","tunnus":"tunnus","proj":"proj"},
{"id":21,"parentid":14,"summa":22.01,"dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"111","lisa_k":null,"kreedit":"222","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"22.0000","tunnus":null,"proj":null}]}

select docs.sp_salvesta_journal('{"id":40,"doc_type_id":"JOURNAL","data":{"id":40,"created":"2016-05-24T14:49:46.198805","lastupdate":"2016-05-25T14:15:08.329755","bpm":null,"doc":"Lausendid","doc_type_id":"JOURNAL","status":"Черновик","number":2,"rekvid":1,"kpv":"2016-05-21","asutusid":1,"dok":"lisa 3","selg":"selg parandus","muud":"muud","summa":122.01,"regkood":"123456789           ","asutus":"isik, töötaja"},"details":[
{"id":16,"parentid":14,"summa":"100.0000","dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"113","lisa_k":null,"kreedit":"122","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"100.0000","tunnus":"tunnus","proj":"proj"},
{"id":21,"parentid":14,"summa":22.01,"dokument":null,"muud":null,"kood1":null,"kood2":null,"kood3":null,"kood4":null,"kood5":null,"deebet":"111","lisa_k":null,"kreedit":"222","lisa_d":null,"valuuta":"EUR","kuurs":"1.000000","valsumma":"22.0000","tunnus":null,"proj":null}]}',1, 1);

select * from docs.journal1 where parentid = 14

*/
