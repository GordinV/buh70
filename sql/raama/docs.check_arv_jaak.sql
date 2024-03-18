DROP FUNCTION IF EXISTS docs.check_arv_jaak(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION docs.check_arv_jaak(IN tnId INTEGER, IN user_id INTEGER, OUT error_code INTEGER,
                                               OUT result INTEGER, OUT error_message TEXT)
    -- проверка и вызов пересчета сальдо
AS
$BODY$
DECLARE
    v_arv RECORD;
BEGIN
    error_code = 0;
    result = 0;

    FOR v_arv IN
        SELECT d.id, a.jaak, a.tasud
        FROM docs.doc d
                 INNER JOIN docs.arv a ON a.parentid = d.id
        WHERE d.rekvid IN (SELECT rekvid FROM ou.userid WHERE id = user_id)
          AND a.jaak > 0
          AND a.tasud IS NOT NULL
          AND a.tasud <= CURRENT_DATE
          AND d.id = CASE WHEN tnId IS NOT NULL THEN tnId ELSE D.id END

        LOOP
            -- update arv jaak
            PERFORM docs.sp_update_arv_jaak(v_arv.id);
            result = result + 1;

        END LOOP;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            error_code = 1;
            error_message = SQLERRM;
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION docs.check_arv_jaak(INTEGER, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.check_arv_jaak(INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.check_arv_jaak(INTEGER, INTEGER) TO dbvaatleja;


SELECT docs.check_arv_jaak(null, 4711);

