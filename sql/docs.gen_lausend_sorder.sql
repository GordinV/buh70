
DROP FUNCTION if exists docs.gen_lausend_sorder(integer, integer);

CREATE OR REPLACE FUNCTION docs.gen_lausend_sorder(
    IN tnid integer,
    IN userid integer,
    OUT error_code integer,
    OUT result integer,
    OUT error_message text)
  RETURNS record AS
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
	v_sorder record;
	v_dokprop record;
	v_dokprop_details record;
	v_sorder1 record;
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


	select d.docs_ids , k.*, asutus.tp as asutus_tp into v_sorder 
		from docs.korder1 k
		inner join docs.doc d on d.id = k.parentId
		inner join libs.asutus asutus on asutus.id = k.asutusid
		where k.id = tnId;

	GET DIAGNOSTICS rows_fetched = ROW_COUNT;

	if rows_fetched = 0 then
		raise notice 'rows_fetched = 0'; 
		error_code = 4; -- No documents found 
		error_message = 'No documents found';
		result  = 0;

	end if;	
	
	If v_sorder.doklausid = 0 then
		raise notice 'v_sorder.doklausid = 0'; 
		error_code = 1; -- Konteerimine pole vajalik
		error_message = 'Konteerimine pole vajalik';
		result  = 0;
	End if;

	select kasutaja into userName from userid u where u.rekvid = v_sorder.rekvId and u.id = userId;
	if userName is null then
		raise notice 'User not found %', userId;
		error_message = 'User not found';
		error_code = 3;
		return;
	end if;


	if result is null then
			
		if v_sorder.rekvid > 1 then
			lcAllikas = 'LE-P'; -- narva LV @todo should create more flexible variant
		end if;

		SELECT library.kood,dokprop.*, details.* into v_dokprop 
			from libs.dokprop dokprop 
			inner join libs.library library on library.id = dokprop.parentid ,
			jsonb_to_record(dokprop.details) as details(konto text, kbmkonto text) 
			where dokprop.id = v_sorder.doklausid limit 1;

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
					from docs.korder2 k1
					inner join libs.nomenklatuur nom on k1.nomid = nom.id 
					where k1.parentid = v_sorder.id
			loop
				lcSelg = lcSelg || ', ' || trim(v_selg.nimetus);
			end loop;
		else 	
			lcSelg = trim(v_dokprop.selg);
		end if;

		
		v_sorder.asutus_tp = coalesce(v_sorder.asutus_tp,'800599');	
		lcKrTp = coalesce(v_sorder.asutus_tp,'800599');

	
		l_json = 
			'"id":' || coalesce(v_sorder.journalid,0) || 
			',"doc_type_id":"JOURNAL"' || 
			',"data":{' || 			
			'"kpv":"' || v_sorder.kpv || '"' ||
			',"selg":"' || lcSelg || '"' || 
			',"muud":"' || coalesce(v_sorder.muud,'null') || '"' || 
			',"asutusid":' || v_sorder.Asutusid ||
			',"dok": "Arve nr.' || coalesce(v_sorder.number,'null') || '"';

		raise notice 'l_json 1 %', l_json;
		
		
--		l_json_details = '[]';
		for v_sorder1 in 
			select k1.*, 
				coalesce(dokvaluuta1.valuuta,'EUR')::varchar as valuuta, 
				coalesce(dokvaluuta1.kuurs,1)::numeric as kuurs 
				from docs.korder2 k1
				left outer join docs.dokvaluuta1 dokvaluuta1 on (k1.id = dokvaluuta1.dokid and dokvaluuta1.dokliik = 10) 
				where k1.parentid = v_sorder.Id
		loop

			if not empty(v_sorder1.tp) then 
				v_sorder.asutus_tp:= v_sorder1.tp;
			end if;
			
			if not empty(v_sorder1.kood2) then
				lcAllikas = v_sorder1.kood2;
			end if;
			
			lcKood5 = v_sorder1.kood5;

			/* sisse kassa order*/	
				lcDbKonto = v_dokprop.konto;
				lcKrKonto = coalesce(v_sorder1.konto,'puudub');
				
				l_json_row =  '{' ||
					'"id":0' ||	
					',"summa":' || coalesce(v_sorder1.summa,0) ||
					',"valuuta":"' || coalesce(v_sorder1.valuuta,'EUR') || '"' ||  			
					',"kuurs":' || coalesce(v_sorder1.kuurs,1) ||
					',"deebet":"' || lcDbKonto || '"' ||  			
					',"lisa_d":"' || coalesce(v_sorder.asutus_tp,'800599') || '"' ||  			
					',"kreedit":"' || lcKrKonto || '"' ||  			
					',"lisa_k":"' || coalesce(v_sorder.asutus_tp,'800599') || '"' ||  			
					',"tunnus":"' || coalesce(v_sorder1.tunnus,'') || '"' ||  			
					',"proj":"' || coalesce(v_sorder1.proj,'') || '"' ||  			
					',"kood1":"' || coalesce(v_sorder1.kood1,'') || '"' ||  			
					',"kood2":"' || coalesce(v_sorder1.kood2,'') || '"' ||  			
					',"kood3":"' || coalesce(v_sorder1.kood3,'') || '"' ||  			
					',"kood4":"' || coalesce(v_sorder1.kood4,'') || '"' ||  			
					',"kood5":"' || coalesce(v_sorder1.kood5,'') || '"' ||  			
					'}';

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

		result = docs.sp_salvesta_journal(l_json::json, userId, v_sorder.rekvId);
		
		if result is not null and result > 0 then
			/*
			ajalugu
			*/
			
			select row_to_json(row) into new_history from (select now() as updated, userName as user) row;

			-- will add docs into doc's pull
			-- arve



			update docs.doc set docs_ids = array(select distinct unnest(array_append(v_sorder.docs_ids, result))), 
				lastupdate = now(),
				history = coalesce(history,'[]')::jsonb || new_history
			where id = v_sorder.parentId;

			-- lausend
			select docs_ids into a_docs_ids from docs.doc where id = result;

			-- add new id into docs. ref. array 
			a_docs_ids = array(select distinct unnest(array_append(a_docs_ids, v_sorder.parentId)));
			
			update docs.doc set docs_ids = a_docs_ids where id = result;
		
			-- direct ref to journal	
			update docs.korder1 set 
				journalId = (select parentId from docs.journal where parentid = result)
				where id = v_sorder.id;

				
			error_code = 0;	
		else 
			error_code = 2;
		end if;
	end if;


	
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
ALTER FUNCTION docs.gen_lausend_sorder(integer, integer)
  OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.gen_lausend_sorder(integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.gen_lausend_sorder(integer, integer) TO dbpeakasutaja;


select * from docs.gen_lausend_sorder(74, 1)

/*


select * from libs.dokprop

select * from libs.library where library = 'DOK'
-- 7

insert into libs.dokprop (parentid, registr, selg, details, tyyp)
	values (7, 1, 'Sorder', '{"konto":"100000"}'::jsonb, 1 )

update docs.korder1 set doklausid = 4 where tyyp = 1
*/
