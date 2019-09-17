-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_lapse_kaart(IN user_id INTEGER,
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

    SELECT v.*,
           u.ametnik::TEXT                      AS kasutaja,
           (u.roles -> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.vanemad v
             JOIN ou.userid u ON u.id = user_id
    WHERE v.id = doc_id;

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

    -- Логгирование удаленного документа

    SELECT to_jsonb(row) INTO json_ajalugu
    FROM (SELECT now()          AS deleted,
                 v_doc.kasutaja AS user) row;

    UPDATE lapsed.lapse_kaart
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

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_lapse_kaart(INTEGER, INTEGER) TO dbpeakasutaja;


/*
select lapsed.sp_delete_lapse_kaart(70,3)

select * from lapsed.lapse_kaart
 */