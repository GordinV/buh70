-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.sp_delete_pank_vv(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.sp_delete_pank_vv(IN user_id INTEGER,
                                                    IN pank_vv_id INTEGER,
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
           u.ametnik::TEXT                       AS kasutaja,
           (u.roles ->> 'is_arvestaja')::BOOLEAN AS is_arvestaja
           INTO v_doc
    FROM lapsed.pank_vv v
             JOIN ou.userid u ON u.id = user_id
    WHERE v.id = pank_vv_id;

    -- проверка на пользователя и его соответствие учреждению

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(pank_vv_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    IF v_doc.kasutaja IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud: ' || ', userId:' ||
                        coalesce(user_id, 0) :: TEXT;
        result = 0;
        RETURN;
    END IF;

    IF v_doc.doc_id IS NOT NULL AND v_doc.doc_id > 0
    THEN
        -- уже импортирован, нельзя
        error_code = 6;
        error_message = 'Makse juba importeeritud ja selle kirjaga on seotud dokument' :: TEXT;
        result = 0;
        RETURN;
    END IF;

    DELETE FROM lapsed.pank_vv WHERE id = pank_vv_id;

    result = 1;
    RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.sp_delete_pank_vv(INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_pank_vv(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.sp_delete_pank_vv(INTEGER, INTEGER) TO dbkasutaja;


/*
select lapsed.sp_delete_laps(70,1)

select * from lapsed.laps
 */