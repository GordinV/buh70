DROP FUNCTION IF EXISTS ou.sp_delete_twin_useris();

CREATE OR REPLACE FUNCTION ou.sp_delete_twin_useris(OUT error_code INTEGER,
                                                    OUT result INTEGER,
                                                    OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    v_doc     RECORD;
    l_user_id INTEGER;
BEGIN
    FOR v_doc IN
        SELECT kasutaja, rekvid, count(*)
        FROM ou.userid
        WHERE status <> 3
            GROUP BY kasutaja
            , rekvid
            HAVING count(*) > 1
            ORDER BY kasutaja
        LOOP
            l_user_id = (SELECT id
                         FROM ou.userid
                         WHERE rekvid = v_doc.rekvid
                           AND kasutaja = v_doc.kasutaja
                           AND status <> 3 ORDER BY id DESC LIMIT 1);
            IF l_user_id IS NOT NULL
            THEN
                UPDATE ou.userid SET status = 3 WHERE id = l_user_id;
            END IF;
        END LOOP;


    result = 1;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


/*
select ou.sp_delete_twin_useris();
DROP FUNCTION IF EXISTS ou.sp_delete_twin_useris();

*/