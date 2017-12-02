
DROP FUNCTION if exists docs.sp_delete_arv(integer, integer);

CREATE OR REPLACE FUNCTION docs.sp_delete_arv(
    IN userid integer,
    IN doc_id integer, 
    OUT error_code integer, 
    OUT result integer, 
    OUT error_message text)
  AS
$BODY$

declare
	v_doc record;
	v_dependid_docs record;
	arv_id integer;
	ids integer[];	
	arv_history jsonb ;
	arv1_history jsonb ;
	arvtasu_history jsonb ;
	new_history jsonb;
	DOC_STATUS integer = 3; -- документ удален
begin
	
	select d.*, u.ametnik as user_name into v_doc
		from docs.doc d 
		left outer join ou.userid u on u.id = userid
		where d.id = doc_id;

	-- проверка на пользователя и его соответствие учреждению

	if not exists (select id 
		from ou.userid u 
		where id = userid
		and u.rekvid = v_doc.rekvid
		) then

		error_code = 5; 
		error_message = 'Kasutaja ei leitud';
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
			and l.kood in ('ARV', 'MK', 'SORDER', 'KORDER')) then

		raise notice 'Есть связанные доку менты. удалять нельзя'; 
		error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
		error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
		result  = 0;
		return;
	end if;

	-- Логгирование удаленного документа
	-- docs.arv

	arv_history = row_to_json(row.*) from (select a.* 
		from docs.arv a where a.parentid = doc_id) row;

	-- docs.arv1
		
	arv1_history = jsonb_build_array(array(select row_to_json(row.*) from (select a1.* 
		from docs.arv1 a1 
		inner join docs.arv a on a.id = a1.parentid
		where a.parentid = doc_id) row));
	-- docs.arvtasu
		
	arvtasu_history = jsonb_build_array(array(select row_to_json(row.*) from (select at.* 
		from docs.arvtasu at 
		inner join docs.arv a on a.id = at.doc_arv_id
		where a.parentid = doc_id) row));

	select row_to_json(row) into new_history from (select now() as deleted, v_doc.user_name as user, arv_history as arv, arv1_history as arv1,arvtasu_history as arvtasu ) row;

	
	-- Удаление данных из связанных таблиц (удаляем проводки)

	if (v_doc.docs_ids is not null) then
		delete from docs.journal where id in (select unnest(v_doc.docs_ids)); -- @todo процедура удаления
		delete from docs.journal1 where parentid in (select unnest(v_doc.docs_ids)); -- @todo констрейн на удаление
	end if;

	delete from docs.arv1 where parentid in (select id from docs.arv where parentid =  v_doc.id);
	delete from docs.arv where parentid = v_doc.id; --@todo констрейн на удаление

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

GRANT EXECUTE ON FUNCTION docs.sp_delete_arv(integer, integer) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_arv(integer, integer) TO dbpeakasutaja;


select error_code, result, error_message from docs.sp_delete_arv(1, 125);

/*
select docs.sp_salvesta_arv('{"id":0,"doc_type_id":"ARV","data":{"id":0,"created":"2016-05-05T21:39:57.050726","lastupdate":"2016-05-05T21:39:57.050726","bpm":null,"doc":"Arved","doc_type_id":"ARV","status":"Черновик","number":"321","summa":24,"rekvid":null,"liik":0,"operid":null,"kpv":"2016-05-05","asutusid":1,"arvid":null,"lisa":"lisa","tahtaeg":"2016-05-19","kbmta":null,"kbm":4,"tasud":null,"tasudok":null,"muud":"muud","jaak":"0.00","objektid":null,"objekt":null,"regkood":null,"asutus":null},
"details":[{"id":"NEW0.6577064044198089","[object Object]":null,"nomid":"1","kogus":2,"hind":10,"kbm":4,"kbmta":20,"summa":24,"kood":"PAIGALDUS","nimetus":"PV paigaldamine"}]}',1, 1);

*/