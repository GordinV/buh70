DROP FUNCTION IF EXISTS docs.sp_delete_arvtasu(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.sp_delete_arvtasu(IN userid INTEGER,
                                                  IN doc_id INTEGER,
                                                  OUT error_code INTEGER,
                                                  OUT result INTEGER,
                                                  OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc    RECORD;
    l_doc_id INTEGER = 0;
BEGIN

    SELECT d.*,
           u.ametnik AS user_name
    INTO v_doc
    FROM docs.arvtasu d
             LEFT OUTER JOIN ou.userid u ON u.id = userid
    WHERE d.id = doc_id
    LIMIT 1;

    IF v_doc IS NULL
    THEN
        error_code = 6;
        error_message = 'Dokument ei leitud, docId: ' || coalesce(doc_id, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- 0 = открыт
    -- 1 закрыт
    IF NOT docs.is_period_opened(v_doc.doc_tasu_id)
    THEN
        error_code = 1;
        error_message = 'Period on suletatud';
        result = 0;
    END IF;


    IF NOT exists(SELECT id
                  FROM ou.userid u
                  WHERE id = userid
                    AND (u.rekvid = v_doc.rekvid OR v_doc.rekvid IS NULL OR v_doc.rekvid = 0)
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                        coalesce(userid, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    UPDATE docs.arvtasu
    SET status = 3
    WHERE id = doc_id RETURNING ID
        INTO l_doc_id;

-- уберем связи
    UPDATE docs.doc SET docs_ids = array_remove(docs_ids, v_doc.doc_tasu_id) WHERE id = v_doc.doc_arv_id;
    UPDATE docs.doc SET docs_ids = array_remove(docs_ids, v_doc.doc_arv_id) WHERE id = v_doc.doc_tasu_id;

    -- update arv jaak
    PERFORM docs.sp_update_arv_jaak(v_doc.doc_arv_id);

    -- сальдо платежа
    PERFORM docs.sp_update_mk_jaak(v_doc.doc_tasu_id);

    result = 1;

    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.sp_delete_arvtasu(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.sp_delete_arvtasu(INTEGER, INTEGER) TO dbpeakasutaja;

/*
SELECT *
FROM libs.sp_delete_library(1, 186)

*/