DROP FUNCTION IF EXISTS hooldekodu.sp_delete_hooleping(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION hooldekodu.sp_delete_hooleping(IN userid INTEGER,
                                                          IN doc_id INTEGER,
                                                          OUT error_code INTEGER,
                                                          OUT result INTEGER,
                                                          OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc        RECORD;
    json_ajalugu JSONB;
BEGIN

    SELECT l.*,
           u.ametnik AS user_name,
           u.rekvid  AS kasutaja_rekvid
    INTO v_doc
    FROM hooldekodu.hooleping l
             LEFT OUTER JOIN ou.userid u ON u.id = userid
    WHERE l.id = doc_id;

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
                    AND (u.rekvid = v_doc.kasutaja_rekvid OR v_doc.kasutaja_rekvid IS NULL OR v_doc.kasutaja_rekvid = 0)
        )
    THEN

        error_code = 5;
        error_message = 'Kasutaja ei leitud, rekvId: ' || coalesce(v_doc.rekvid, 0) :: TEXT || ', userId:' ||
                        coalesce(userid, 0) :: TEXT;
        result = 0;
        RETURN;

    END IF;

    -- логгирование
    json_ajalugu = to_jsonb(row)
                   FROM (SELECT now()           AS deleted,
                                v_doc.user_name AS user) row;


    UPDATE hooldekodu.hooleping
    SET status  = 3,
        ajalugu = coalesce(ajalugu, '[]'::JSONB)::JSONB || json_ajalugu
    WHERE id = doc_id;

    result = 1;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % % %', MESSAGE_TEXT, PG_EXCEPTION_DETAIL, PG_EXCEPTION_HINT;
            error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
            error_message = MESSAGE_TEXT;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.sp_delete_hooleping(INTEGER, INTEGER) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.sp_delete_hooleping(INTEGER, INTEGER) TO hkametnik;

/*
SELECT *
FROM libs.sp_delete_library(2477, 121358)

select * from libs.library where kood = 'Kood'

*/