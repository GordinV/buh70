DROP FUNCTION IF EXISTS docs.register_email_error(INTEGER, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION docs.register_email_error(doc_id INTEGER, info TEXT,
                                                     user_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_result INTEGER;
    v_doc    RECORD;
    l_event  JSONB;
    l_user   TEXT = (SELECT kasutaja
                     FROM ou.userid
                     WHERE id = user_id);
BEGIN

    SELECT position('"email"' IN history::TEXT)         AS email,
           position('"emai_error"' IN history::TEXT)    AS email_error,
           position('"email_error_1"' IN history::TEXT) AS email_error_1,
           position('"email_error_2"' IN history::TEXT) AS email_error_2,
           position('"email_error_3"' IN history::TEXT) AS email_error_3
    INTO v_doc
    FROM docs.doc
    WHERE id = doc_id;


    IF v_doc.email_error_1 = 0
    THEN
        -- первая ошибка
        l_event = jsonb_build_object('email_error_1', now(), 'info', info, 'user', l_user);
    ELSEIF v_doc.email_error_2 = 0
    THEN
        -- первая ошибка
        l_event = jsonb_build_object('email_error_2', now(), 'info', info, 'user', l_user);
    ELSE
        -- первая ошибка
        l_event = jsonb_build_object('email_error_3', now(), 'info', info, 'user', l_user);
    END IF;

    raise notice 'l_event %, doc_id %', l_event, doc_id;

    UPDATE docs.doc
    SET history = history::jsonb || l_event::jsonb
    WHERE id = doc_id;
    RETURN 1;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION docs.register_email_error(INTEGER, TEXT, INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION docs.register_email_error(INTEGER, TEXT, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION docs.register_email_error(INTEGER, TEXT, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION docs.register_email_error(INTEGER, TEXT, INTEGER) TO dbvaatleja;

/*
select docs.register_email_error(2487228, '{}', 2477)

SELECT position('"email"' IN history::TEXT)         AS email,
           position('emai_error' IN history::TEXT)    AS email_error,
           position('"email_error_1"' IN history::TEXT) AS email_error_1,
           position('"email_error_2"' IN history::TEXT) AS email_error_2,
           position('"email_error_3"' IN history::TEXT) AS email_error_3,
history
    FROM docs.doc
    WHERE id = 2487230;

Select docs.register_email_error(2487230::INTEGER,'Error'::TEXT, 70::INTEGER)


    UPDATE docs.doc
    SET history = history::jsonb || '{"info": "{}", "user": "vlad", "email_error_3": "2024-03-17T13:56:29.658705+00:00"}'::jsonb
    WHERE id = 2487230;

email;email_error;email_error_1;email_error_2;email_error_3;history
0;0;241;0;33;[{"info": "{}", "user": "vlad", "email_error_3": "2024-03-17T13:56:29.658705+00:00"}, {"info": "{\"errno\":-4039,\"code\":\"ESOCKET\",\"syscall\":\"connect\",\"address\":\"78.41.204.31\",\"port\":465,\"command\":\"CONN\"}", "user": "temp", "email_error_1": "2024-03-17T16:00:47.086741+02:00"}]


*/
