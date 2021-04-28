DROP FUNCTION IF EXISTS ou.register_events(JSON, INTEGER);

CREATE OR REPLACE FUNCTION ou.register_events(data JSON,
                                              user_id INTEGER)
    RETURNS INTEGER AS
$BODY$

DECLARE
    doc_dokument  TEXT    = data ->> 'dokument';
    doc_event     TEXT    = data ->> 'event';
    doc_status    TEXT    = data ->> 'status';
    doc_content   TEXT    = data ->> 'content';
    doc_isik_id   INTEGER = data ->> 'isik_id';
    doc_mail_info TEXT    = data ->> 'mail_info';
    l_rekvid      INTEGER;
    l_doc_id      INTEGER;

    log_data      JSONB   = jsonb_build_object('event', doc_event, 'status', doc_status, 'content', doc_content,
                                               'isik_id', doc_isik_id, 'mail_info', doc_mail_info);
    l_result      INTEGER;

BEGIN
    l_rekvid = (SELECT rekvid FROM ou.userid WHERE id = user_id LIMIT 1);
    l_doc_id =
            (SELECT id FROM libs.library WHERE library.library = 'DOK' AND kood = doc_dokument AND status <> 3 LIMIT 1);


    INSERT INTO ou.logs (rekvid, user_id, doc_id, propertis)
    VALUES (l_rekvid, user_id, l_doc_id, log_data) RETURNING id INTO l_result;

    RETURN l_result;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.register_events(JSON, INTEGER) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.register_events(JSON, INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.register_events(JSON, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.register_events(JSON, INTEGER) TO dbvaatleja;

/*
select ou.register_events('{"dokument":"PALK_LEHT","event":"print","status":"Ok","content":"Trükkitatud"}', 2477)

select * from ou.logs
*/
