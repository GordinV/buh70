
DROP FUNCTION if exists docs.gen_lausend_arv(integer);

DROP FUNCTION if exists docs.gen_lausend_arv(integer, integer);

CREATE OR REPLACE FUNCTION docs.gen_lausend_arv(IN tnId integer, IN userId integer, OUT error_code integer, OUT result integer, OUT error_message text)
   AS
$BODY$
declare lcErrorText text = '';
	lcDbKonto varchar(20);
	lcKrKonto varchar(20);
	lcDbTp varchar(20);
	lcKrTp varchar(20);
	lcKood5 varchar(20);
	lnAsutusId int4;
	lnJournal int4;
	lcKbmTp varchar(20);
	lcDbKbmTp varchar(20);
	v_arv record;
	v_dokprop record;
	v_dokprop_details record;
	v_arv1 record;
	v_asutus record;
	lcAllikas varchar(20);
	lcSelg text;
	v_selg record;
	l_json text;
	l_json_details text;
	l_json_row text;
	l_row_count integer = 0;
	new_history jsonb;
	userName text;
	a_docs_ids integer[];
	rows_fetched integer = 0;

	
begin


	select d.docs_ids , a.*, asutus.tp as asutus_tp into v_arv 
		from docs.arv a
		inner join docs.doc d on d.id = a.parentId
		inner join libs.asutus asutus on asutus.id = a.asutusid
		where a.id = tnId;

	GET DIAGNOSTICS rows_fetched = ROW_COUNT;

	if rows_fetched = 0 then
		raise notice 'rows_fetched = 0'; 
		error_code = 4; -- No documents found 
		error_message = 'No documents found';
		result  = 0;

	end if;	
	
	If v_arv.doklausid = 0 then
		raise notice 'v_arv.doklausid = 0'; 
		error_code = 1; -- Konteerimine pole vajalik
		error_message = 'Konteerimine pole vajalik';
		result  = 0;
	End if;

	select kasutaja into userName from userid u where u.rekvid = v_arv.rekvId and u.id = userId;
	if userName is null then
		raise notice 'User not found %', userId;
		error_message = 'User not found';
		error_code = 3;
		return;
	end if;


	if result is null then
			
		if v_arv.rekvid > 1 then
			lcAllikas = 'LE-P'; -- narva LV @todo should create more flexible variant
		end if;

		SELECT library.kood,dokprop.*, details.* into v_dokprop 
			from libs.dokprop dokprop 
			inner join libs.library library on library.id = dokprop.parentid ,
			jsonb_to_record(dokprop.details) as details(konto text, kbmkonto text) 
			where dokprop.id = v_arv.doklausid limit 1;

		If not Found or v_dokprop.registr = 0 then
				raise notice 'v_dokprop.registr = 0'; 

			error_code = 1; -- Konteerimine pole vajalik
			result  = 0;
			error_message = 'Konteerimine pole vajalik';

		End if;
	end if;	

	if result is null then
		lcDbKonto = '103000';
	-- koostame selg rea
		lcSelg =  trim(v_dokprop.selg);
		if (select count(id) from rekv where parentid = 119 or id = 119) > 0 then -- Narva LV kultuuriosakond. @todo need flexible solution
			for v_selg in
				select distinct nom.nimetus 
					from docs.arv1 arv1
					inner join libs.nomenklatuur nom on arv1.nomid = nom.id 
					where arv1.parentid = v_arv.id
			loop
				lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
			end loop;
		else 	
			lcSelg = trim(v_dokprop.selg);
		end if;

		
		v_arv.asutus_tp = coalesce(v_arv.asutus_tp,'800599');	
		lcKrTp = coalesce(v_arv.asutus_tp,'800599');

	
		l_json = 
			'"id":' || v_arv.journalid || 
			',"doc_type_id":"JOURNAL"' || 
			',"data":{' || 			
			'"kpv":"' || v_arv.kpv || '"' ||
			',"selg":"' || lcSelg || '"' || 
			',"muud":"' || v_arv.muud || '"' || 
			',"asutusid":' || v_arv.Asutusid ||
			',"dok": "Arve nr.' || v_arv.number || '"';

		raise notice 'l_json 1 %', l_json;
		
		
--		l_json_details = '[]';
		for v_arv1 in 
			select arv1.*, 
				coalesce(dokvaluuta1.valuuta,'EUR')::varchar as valuuta, 
				coalesce(dokvaluuta1.kuurs,1)::numeric as kuurs 
				from docs.arv1 arv1
				left outer join docs.dokvaluuta1 dokvaluuta1 on (arv1.id = dokvaluuta1.dokid and dokvaluuta1.dokliik = 2) 
				where arv1.parentid = v_arv.Id
		loop

			raise notice 'v_arv1: %', v_arv1;	
			if not empty(v_arv1.tp) then 
				v_arv.asutus_tp:= v_arv1.tp;
			end if;
			
			if not empty(v_arv1.kood2) then
				lcAllikas = v_arv1.kood2;
			end if;
			
			lcKood5 = v_arv1.kood5;

			If v_arv.liik = 0 then	
				lcDbKonto = v_arv1.konto;
				lcKrKonto = v_dokprop.konto;
				
				l_json_row =  '{' ||
					'"id":0' ||	
					',"summa":' || case when v_arv1.kbmta = 0 then v_arv1.hind * v_arv1.kogus else v_arv1.kbmta end ||
					',"valuuta":"' || coalesce(v_arv1.valuuta,'EUR') || '"' ||  			
					',"kuurs":' || coalesce(v_arv1.kuurs,1) ||
					',"deebet":"' || lcDbKonto || '"' ||  			
					',"lisa_d":"' || coalesce(v_arv.asutus_tp,'800599') || '"' ||  			
					',"kreedit":"' || lcKrKonto || '"' ||  			
					',"lisa_k":"' || coalesce(v_arv.asutus_tp,'800599') || '"' ||  			
					',"tunnus":"' || coalesce(v_arv1.tunnus,'') || '"' ||  			
					',"proj":"' || coalesce(v_arv1.proj,'') || '"' ||  			
					',"kood1":"' || coalesce(v_arv1.kood1,'') || '"' ||  			
					',"kood2":"' || coalesce(v_arv1.kood2,'') || '"' ||  			
					',"kood3":"' || coalesce(v_arv1.kood3,'') || '"' ||  			
					',"kood4":"' || coalesce(v_arv1.kood4,'') || '"' ||  			
					',"kood5":"' || coalesce(v_arv1.kood5,'') || '"' ||  			
					'}';
					If v_arv1.kbm <> 0 then
						
						if left(trim(v_arv1.konto),6) = '103701' then
							v_arv.asutus_tp = '014001';
						end if;
						
						l_json_row = l_json_row || ',{' ||
							'"id":0' ||	
							',"summa":' || coalesce(v_arv1.kbm,0) ||
							',"valuuta":"' || coalesce(v_arv1.valuuta,'EUR') || '"' ||  			
							',"kuurs":' || coalesce(v_arv1.kuurs,1) ||
							',"deebet":"' || coalesce(v_dokprop.konto,'601000') || '"' || 
							',"lisa_d":"' || coalesce(v_arv.asutus_tp,'800599') || '"' ||  									 			
							',"kreedit":"' || coalesce(v_dokprop.kbmkonto,'203010') || '"' ||  			
							',"lisa_k":"' || coalesce(v_arv.asutus_tp,'014001') || '"' ||  									 			
							',"tunnus":"' || coalesce(v_arv1.tunnus,'') || '"' ||  			
							',"proj":"' || coalesce(v_arv1.proj,'') || '"' ||  			
							',"kood1":"' || coalesce(v_arv1.kood1,'') || '"' ||  			
							',"kood2":"' || coalesce(v_arv1.kood2,'') || '"' ||  			
							',"kood3":"' || coalesce(v_arv1.kood3,'') || '"' ||  			
							',"kood4":"' || coalesce(v_arv1.kood4,'') || '"' ||  			
							',"kood5":"' || coalesce(v_arv1.kood5,'') || '"' ||  			
							'}';

					end if;

			
			Else
				if v_arv1.konto = '601000' or v_arv1.konto = '203000' or left(ltrim(rtrim(v_arv1.konto)),6) = '103701' then
					v_arv.asutus_tp := '014001';
				end if;
				
				l_json_row =  '{' ||
					'"id":0' ||	
					',"summa":' || case when v_arv1.kbmta = 0 then v_arv1.hind * v_arv1.kogus else v_arv1.kbmta end ||
					',"valuuta":"' || coalesce(v_arv1.valuuta,'EUR') || '"' ||  			
					',"kuurs":' || coalesce(v_arv1.kuurs,1) ||
					',"deebet":"' || coalesce(v_arv1.konto,'103000') || '"' ||  			
					',"lisa_d":"' || coalesce(v_arv.asutus_tp,'014001') || '"' ||  			
					',"kreedit":"' || coalesce(v_dokprop.konto,'203010') || '"' ||  			
					',"lisa_k":"' || coalesce(lcKrTp,'014001') || '"' ||  			
					',"tunnus":"' || coalesce(v_arv1.tunnus,'') || '"' ||  			
					',"proj":"' || coalesce(v_arv1.proj,'') || '"' ||  			
					',"kood1":"' || coalesce(v_arv1.kood1,'') || '"' ||  			
					',"kood2":"' || coalesce(v_arv1.kood2,'') || '"' ||  			
					',"kood3":"' || coalesce(v_arv1.kood3,'') || '"' ||  			
					',"kood4":"' || coalesce(v_arv1.kood4,'') || '"' ||  			
					',"kood5":"' || coalesce(v_arv1.kood5,'') || '"' ||  			
					'}';
				If v_arv1.kbm <> 0 then
						
						if left(trim(v_arv1.konto),6) = '103701' then
							v_arv.asutus_tp = '014001';
						end if;
						
						l_json_row = l_json_row || ',{' ||
							'"id":0' ||	
							',"summa":' || coalesce(v_arv1.kbm,0) ||
							',"valuuta":"' || coalesce(v_arv1.valuuta,'EUR') || '"' ||  			
							',"kuurs":' || coalesce(v_arv1.kuurs,1) ||
							',"deebet":"' || coalesce(v_dokprop.kbmkonto,'601000') || '"' || 
							',"lisa_d":"' || '014001' || '"' ||  									 			
							',"kreedit":"' || coalesce(v_dokprop.konto,'') || '"' ||  			
							',"lisa_k":"' || coalesce(lcKrTp,'014001') || '"' ||  									 			
							',"tunnus":"' || coalesce(v_arv1.tunnus,'') || '"' ||  			
							',"proj":"' || coalesce(v_arv1.proj,'') || '"' ||  			
							',"kood1":"' || coalesce(v_arv1.kood1,'') || '"' ||  			
							',"kood2":"' || coalesce(v_arv1.kood2,'') || '"' ||  			
							',"kood3":"' || coalesce(v_arv1.kood3,'') || '"' ||  			
							',"kood4":"' || coalesce(v_arv1.kood4,'') || '"' ||  			
							',"kood5":"' || coalesce(v_arv1.kood5,'') || '"' ||  			
							'}';
				end if;
			end if;

			if l_row_count > 0 then
				l_json_details =  l_json_details || ',' || l_json_row;
			else 
				l_json_details =  l_json_row;
			end if;
				
			raise notice 'l_json_details %', l_json_details;
			l_row_count = l_row_count + 1;
			
		End loop;
		if l_json_details is null then
			l_json_details = '';
		end if;
		l_json = '{' || l_json || ',"details":[' || l_json_details || ']}}';
		raise notice 'l_json 2 %', l_json::json;

		

		/* salvestan lausend */

		result = docs.sp_salvesta_journal(l_json::json, userId, v_arv.rekvId);


		
		if result is not null and result > 0 then
			/*
			ajalugu
			*/
			
			select row_to_json(row) into new_history from (select now() as updated, userName as user) row;

			-- will add docs into doc's pull
			-- arve



			update docs.doc set docs_ids = array(select distinct unnest(array_append(v_arv.docs_ids, result))), 
				lastupdate = now(),
				history = coalesce(history,'[]')::jsonb || new_history
			where id = v_arv.parentId;

			-- lausend
			select docs_ids into a_docs_ids from docs.doc where id = result;

			-- add new id into docs. ref. array 
			a_docs_ids = array(select distinct unnest(array_append(a_docs_ids, v_arv.parentId)));
			
			update docs.doc set docs_ids = a_docs_ids where id = result;
		
			-- direct ref to journal	
			update docs.arv set 
				journalId = (select parentId from docs.journal where parentid = result)
				where id = v_arv.id;

				
			error_code = 0;	
		else 
			error_code = 2;
		end if;
	end if;


	
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_arv(integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_arv(integer, integer) TO dbpeakasutaja;

select docs.gen_lausend_arv(121, 1)

/*

select kasutaja from userid u 
	where u.rekvid = v_arv.rekvId and u.id = 1
select * from userid

select * from docs.arv where id = 

select array(select distinct unnest(array[1,1,2]))


select id, docs_ids from docs.doc where id = 75

select * from docs.arv where parentid = 81

select * from docs.arv where parentid = 75


update docs.arv set doklausid = 1

select * from libs.library where library = 'DOK' 

select * from docs.arv 

*/
