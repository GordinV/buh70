-- управление правами в зависимости от статуса

DROP FUNCTION  if exists  docs.trigU_doc_before_rights() CASCADE;

CREATE OR REPLACE FUNCTION docs.trigU_doc_before_rights()
  RETURNS trigger AS
$BODY$
declare 
	doc_rigths jsonb;
	author text = 'vlad';	
	author_id integer = 0;
	history_json json;
begin
	
	-- 1 (ативный. Права согласно роли)
	-- 2 (закрыт, права на просмотр, на редактирование прав нет, удаление у peakasutaja) 
	-- 3 (удален, права на просмотр только у peakasutaja) 

	case 
		when new.status = 0 then
			-- 0 (черновик. Права только у автора)
			-- ищем автора в истории документа

		author = ((old.history) -> 0) ->> 'user';

		select id into author_id from ou.userid where kasutaja = author and rekvId = old.rekvid limit 1; 

			select row_to_json(row) into doc_rigths from
			(select array[author_id] as "select", 
				array[author_id] as "update",
				array[author_id] as "delete") row;
				
		when new.status = 1 then
			select row_to_json(row) into doc_rigths from
			(select array(select id from ou.userid where (kasutaja_ = 1 or peakasutaja_ = 1) and rekvid = old.rekvid) as "update", 
				array(select id from ou.userid where (kasutaja_ = 1 or peakasutaja_ = 1) and rekvid = old.rekvid) as "delete",
				array(select id from ou.userid where rekvid = old.rekvid ) as "select") row; 

		when new.status = 2 then -- closed
			select row_to_json(row) into doc_rigths from
			(select array[0] as "update", 
				array[0] as "delete",
				array(select id from ou.userid where rekvid = old.rekvid ) as "select") row; 
				
		when new.status = 3 then -- deleted
			select row_to_json(row) into doc_rigths from
			(select array[0] as "update", 
				array[0] as "delete",
				array(select id from ou.userid where rekvid = old.rekvid and peakasutaja_ = 1 ) as "select") row; 
	end case;

	new.rigths = doc_rigths;
return new;

end; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER trigU_doc_before_rights
  BEFORE UPDATE
  ON docs.doc
  FOR EACH ROW
  EXECUTE PROCEDURE docs.trigU_doc_before_rights();

  	
