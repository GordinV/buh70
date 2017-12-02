
DROP FUNCTION if exists libs.sp_delete_library(integer, integer);

CREATE OR REPLACE FUNCTION libs.sp_delete_library(
    IN userid integer,
    IN doc_id integer,
    OUT error_code integer,
    OUT result integer,
    OUT error_message text)
  RETURNS record AS
$BODY$

declare
	v_doc record;
	v_dependid_docs record;
	ids integer[];	
	lib_history jsonb ;
	new_history jsonb;
begin
	
	select l.*, u.ametnik as user_name into v_doc
		from libs.library l 
		left outer join ou.userid u on u.id = userid
		where l.id = doc_id;

	if v_doc is null then
		error_code = 6; 
		error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id,0)::text ;
		result  = 0;
		return;

	end if;

	if not exists (select id 
		from ou.userid u 
		where id = userid
		and (u.rekvid = v_doc.rekvid or v_doc.rekvid is null or v_doc.rekvid = 0) 
		) then

		error_code = 5; 
		error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid,0)::text || ', userId:' || coalesce(userid,0)::text;
		result  = 0;
		return;

	end if;	


--	ids =  v_doc.rigths->'delete';
/*
	if not v_doc.rigths->'delete' @> jsonb_build_array(userid) then
		error_code = 4; 
		error_message = 'Ei saa kustuta dokument. Puudub õigused';
		result  = 0;
		return;

	end if;
*/			

	if exists (
		select 1 from (
			select id  from docs.doc where doc_type_id = v_doc.id 
		) qry
	) then

		error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
		error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
		result  = 0;
		return;
	end if;

	lib_history = row_to_json(row.*) from (select l.* 
		from libs.library l where l.id = doc_id) row;

	select row_to_json(row) into new_history from (select now() as deleted, v_doc.user_name as user, lib_history as library) row;

	delete from libs.library where id = doc_id;
	
/*
	update docs.doc 
		set lastupdate = now(),
			history = coalesce(history,'[]')::jsonb || new_history,
			rekvid = v_doc.rekvid,
			status = DOC_STATUS
		where id = doc_id;	
*/		
	result  = 1;		
	return;
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

GRANT EXECUTE ON FUNCTION libs.sp_delete_library(integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_library(integer, integer) TO dbpeakasutaja;



select * from libs.sp_delete_library(1, 186)