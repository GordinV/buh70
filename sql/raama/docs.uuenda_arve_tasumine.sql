-- Function: docs.sp_salvesta_mk(json, integer, integer)

DROP FUNCTION IF EXISTS docs.uuenda_arve_tasumine(INTEGER, INTEGER, INTEGER, NUMERIC);

CREATE OR REPLACE FUNCTION docs.uuenda_arve_tasumine(IN l_user_id INTEGER,
                                                     IN l_tasu_id INTEGER,
                                                     OUT error_code INTEGER,
                                                     OUT result INTEGER,
                                                     OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_user    RECORD;
    v_tasud   RECORD;
    v_tulemus RECORD;
BEGIN
    SELECT * INTO v_user FROM ou.userid WHERE id = l_user_id LIMIT 1;
    IF v_user IS NULL
    THEN
        error_code = 5;
        error_message = 'Kasutaja ei leitud';
        result = 0;
        RETURN;
    END IF;

    IF l_tasu_id IS NULL
    THEN
        -- Документ не найден
        error_code = 3; -- Ei saa kustuta dokument. Kustuta enne kõik seotud dokumendid
        error_message = 'Puudum dok. id';
        result = 0;
        RETURN;
    END IF;

-- идем по платежам и удаляем оплату
    FOR v_tasud IN
        SELECT *
        FROM docs.arvtasu a
        WHERE status <> 3
          AND doc_tasu_id = l_tasu_id
        LOOP
            SELECT error_code, result, error_message INTO v_tulemus
            FROM docs.sp_delete_arvtasu(l_user_id, v_tasud.doc_tasu_id);
            IF coalesce(v_tulemus.error_code, 0) > 0
            THEN
                -- error
                EXIT;
            END IF;
        END LOOP;
    error_message = v_tulemus.error_message;
    error_code = v_tulemus.error_code;
    result = v_tulemus.result;
    RETURN;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.uuenda_arve_tasumine(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.uuenda_arve_tasumine(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.uuenda_arve_tasumine(INTEGER, INTEGER) TO arvestaja;

/*
SELECT *
FROM docs.sp_tasu_arv(2289602::INTEGER, 2275674::INTEGER, 4941::INTEGER);
*/