-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.sp_delete_hoo_config(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_delete_hoo_config(IN userid INTEGER,
                                                        IN doc_id INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc            RECORD;
    taotlus_history  JSONB;
    taotlus1_history JSONB;
    new_history      JSONB;
    DOC_STATUS       INTEGER = array_position((enum_range(NULL :: DOK_STATUS)), 'deleted'); -- документ удален
BEGIN

    SELECT d.*,
           u.ametnik AS user_name
    INTO v_doc
    FROM hooldekodu.hoo_config d
             LEFT OUTER JOIN ou.userid u ON u.id = userid
    WHERE d.id = doc_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF NOT exists(SELECT id
                  FROM ou.userid u
                  WHERE id = userid
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud : ' ||  ', userId:' ||
                        coalesce(userid, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- Установка статуса ("Удален")  и сохранение истории

    SELECT row_to_json(row)
    INTO new_history
    FROM (SELECT now()           AS deleted,
                 v_doc.user_name AS user) row;

    UPDATE hooldekodu.hoo_config
    SET ajalugu = coalesce(ajalugu, '[]') :: JSONB || new_history,
        status  = DOC_STATUS
    WHERE id = doc_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.sp_delete_hoo_config(INTEGER, INTEGER) TO soametnik;
