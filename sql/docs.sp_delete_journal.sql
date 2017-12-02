
DROP FUNCTION if exists docs.sp_delete_journal(integer, integer);

CREATE OR REPLACE FUNCTION docs.sp_delete_journal(
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
	journal_history jsonb ;
	journal1_history jsonb ;
	new_history jsonb;
	DOC_STATUS integer = 3; -- документ удален
begin
	
	select d.*, u.ametnik as user_name into v_doc
		from docs.doc d 
		left outer join ou.userid u on u.id = userid
		where d.id = doc_id;

	-- проверка на пользователя и его соответствие учреждению

	if v_doc is null then
		error_code = 6; 
		error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id,0)::text ;
		result  = 0;
		return;

	end if;

	if not exists (select id 
		from ou.userid u 
		where id = userid
		and u.rekvid = v_doc.rekvid
		) then

		error_code = 5; 
		error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid,0)::text || ', userId:' || coalesce(userid,0)::text;
		result  = 0;
		return;

	end if;	

	-- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


--	ids =  v_doc.rigths->'delete';
	if not v_doc.rigths->'delete' @> jsonb_build_array(userid) then
		raise notice 'У пользователя нет прав на удаление'; 
		error_code = 4; 
		error_message = 'Ei saa kustuta dokument. Puudub õigused';
		result  = 0;
		return;

	end if;
			
	-- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

	if exists (
		select d.id 
			from docs.doc d 
			inner join libs.library l on l.id = d.doc_type_id
			where d.id in (select unnest(v_doc.docs_ids))
			and (l.rekvid is null or l.rekvid = v_doc.rekvid)
			and l.kood in (
				select kood from libs.library where library = 'DOK' 
					AND (properties is  null or properties::jsonb  @> '{"type":"document"}' )
			)) then

		raise notice 'Есть связанные доку менты. удалять нельзя'; 
		error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
		error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
		result  = 0;
		return;
	end if;

	-- Логгирование удаленного документа
	-- docs.journal

	journal_history = row_to_json(row.*) from (select a.* 
		from docs.journal a where a.parentid = doc_id) row;

	-- docs.journal1
		
	journal1_history = jsonb_build_array(array(select row_to_json(row.*) from (select k1.* 
		from docs.journal1 k1 
		inner join docs.journal k on k.id = k1.parentid
		where k.parentid = doc_id) row));

	select row_to_json(row) into new_history from (select now() as deleted, v_doc.user_name as user, journal_history as journal, journal1_history as journal1 ) row;

	
	delete from docs.journal1 where parentid in (select id from docs.journal where parentid =  v_doc.id);
	delete from docs.journal where parentid = v_doc.id; --@todo констрейн на удаление

	-- Установка статуса ("Удален")  и сохранение истории

	update docs.doc 
		set lastupdate = now(),
			history = coalesce(history,'[]')::jsonb || new_history,
			rekvid = v_doc.rekvid,
			status = DOC_STATUS
		where id = doc_id;	
		
	result  = 1;		
	return;
end;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
ALTER FUNCTION docs.sp_delete_journal(integer, integer)
  OWNER TO postgres;

GRANT EXECUTE ON FUNCTION docs.sp_delete_journal(integer, integer) TO postgres;
GRANT EXECUTE ON FUNCTION docs.sp_delete_journal(integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_journal(integer, integer) TO dbpeakasutaja;


select * from docs.sp_delete_journal(1, 91)

/*
select error_code, result, error_message from docs.sp_delete_mk(1, 422)

select * from docs.doc where id =422 

select d.*, u.ametnik as user_name 
		from docs.doc d 
		left outer join ou.userid u on u.id = 1
		where d.id = 91

select * from libs.library where id = 2
		
*/
