-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_laps(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_laps(IN user_id INTEGER,
                                                 IN doc_id INTEGER,
                                                 OUT error_code INTEGER,
                                                 OUT result INTEGER,
                                                 OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
    DOC_STATUS   INTEGER = 3; -- документ удален
BEGIN

    SELECT l.*,
           u.ametnik::TEXT                      AS kasutaja,
           (u.roles ->> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.laps l
             JOIN ou.userid u ON u.id = user_id
    WHERE l.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF (v_doc.kasutaja IS NULL
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- проверка на права. Предполагает наличие прописанных прав на удаление для данного пользователя в поле rigths


    --	ids =  v_doc.rigths->'delete';
    IF (v_doc.is_arvestaja IS NULL OR NOT v_doc.is_arvestaja)
    THEN
        RAISE NOTICE 'У пользователя нет прав на удаление';
        error_code = 4;
        error_message = 'Ei saa kustuta dokument. Puudub õigused';
        result = 0;
        RETURN;

    END IF;

    -- Проверка на наличие связанных документов и их типов (если тип не проводка, то удалять нельзя кроме проводки)
/*
            IF exists(
            SELECT d.id
            FROM docs.doc d
                     INNER JOIN libs.library l ON l.id = d.doc_type_id
            WHERE d.id IN (SELECT unnest(v_doc.docs_ids))
              AND l.kood IN (
                SELECT kood
                FROM libs.library
                WHERE library = 'DOK'
                  AND kood NOT IN ('JOURNAL')
                  AND (properties IS NULL OR properties :: JSONB @> '{"type":"document"}')
            ))
    THEN

        RAISE NOTICE 'Есть связанные доку менты. удалять нельзя';
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid';
        result = 0;
        RETURN;
    END IF;
*/
    -- Логгирование удаленного документа

    SELECT to_jsonb(row) INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.laps
    SET staatus = DOC_STATUS,
        ajalugu = coalesce(ajalugu, '[]')::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_laps(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_laps(INTEGER, INTEGER) TO dbpeakasutaja;


/*
select lapsed.sp_delete_laps(4450,37)

select * from lapsed.laps

select * from ou.userid where id = 4450 or id = 70

update ou.userid set roles = roles || '{"is_arvestaja": true}' where id = 4450
 */