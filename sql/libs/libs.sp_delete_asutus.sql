DROP FUNCTION IF EXISTS docs.sp_delete_asutus(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS libs.sp_delete_asutus(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION libs.sp_delete_asutus(IN userid INTEGER,
                                                 IN doc_id INTEGER,
                                                 OUT error_code INTEGER,
                                                 OUT result INTEGER,
                                                 OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc           RECORD;
    v_dependid_docs RECORD;
    ids             INTEGER[];
    asutus_history  JSONB ;
    new_history     JSONB;
BEGIN

    SELECT a.*, u.ametnik AS user_name INTO v_doc
    FROM libs.asutus a
             LEFT OUTER JOIN ou.userid u ON u.id = userid
    WHERE a.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0)::TEXT;
        result = 0;
        RETURN;

    END IF;


    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


--	ids =  v_doc.rigths->'delete';
/*
	if not v_doc.rigths->'delete' @> jsonb_build_array(userid) then
		raise notice 'У пользователя нет прав на удаление'; 
		error_code = 4; 
		error_message = 'Ei saa kustuta dokument. Puudub õigused';
		result  = 0;
		return;

	end if;
*/
    -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя)

    IF exists(
            SELECT 1
            FROM (
                     SELECT id
                     FROM docs.journal
                     WHERE asutusId = doc_id
                     UNION
                     SELECT id
                     FROM docs.arv
                     WHERE asutusid = doc_id
                     UNION
                     SELECT id
                     FROM docs.korder1
                     WHERE asutusid = doc_id
                     UNION
                     SELECT id
                     FROM docs.mk1
                     WHERE asutusId = doc_id
                     UNION
                     SELECT id
                     FROM rekl.luba
                     WHERE asutusId = doc_id
                     UNION
                     SELECT id
                     FROM palk.tooleping
                     WHERE parentid = doc_id
                 ) qry
        )
    THEN

        RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;
        RETURN;
    END IF;

    -- Логгирование удаленного документа

    asutus_history = row_to_json(row.*)
                     FROM (SELECT a.*
                           FROM libs.asutus a
                           WHERE a.id = doc_id) row;

    SELECT row_to_json(row) INTO new_history
    FROM (SELECT now() AS deleted, v_doc.user_name AS user, asutus_history AS asutus) row;

    -- Установка статуса ("Удален")  и сохранение истории
    UPDATE libs.asutus SET staatus = 3 WHERE id = doc_id;

/*
	update docs.doc 
		set lastupdate = now(),
			history = coalesce(history,'[]')::jsonb || new_history,
			rekvid = v_doc.rekvid,
			status = DOC_STATUS
		where id = doc_id;	
*/
    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;
ALTER FUNCTION libs.sp_delete_asutus(INTEGER, INTEGER)
    OWNER TO postgres;

GRANT EXECUTE ON FUNCTION libs.sp_delete_asutus(INTEGER, INTEGER) TO postgres;
GRANT EXECUTE ON FUNCTION libs.sp_delete_asutus(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION libs.sp_delete_asutus(INTEGER, INTEGER) TO dbpeakasutaja;


/*

select * from libs.sp_delete_asutus(1, 6)
*/
