DROP FUNCTION IF EXISTS ou.tuhista_task_staatus(INTEGER, JSONB);

CREATE OR REPLACE FUNCTION ou.tuhista_task_staatus(user_id INTEGER, data JSONB)
    RETURNS INTEGER AS
$BODY$

DECLARE
    doc_id   INTEGER = data ->> 'doc_id';
    l_result INTEGER = 1;

BEGIN
    if not exists
    (
        select id
        from ou.userid
        where id = user_id
    ) then
        raise exception 'Viga: kasutaja puudub';
    end if;

    if not exists
    (
        select id
        from ou.task
        where id = doc_id and status = 2
    ) then
        raise exception 'Viga: ülesanne  puudub või vale staatus';
    end if;

    update ou.task set status = 0, tulemused = null where id = doc_id;

    RETURN l_result;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.tuhista_task_staatus(INTEGER, JSONB) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.tuhista_task_staatus(INTEGER, JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.tuhista_task_staatus(INTEGER, JSONB) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION ou.tuhista_task_staatus(INTEGER, JSONB) TO dbvaatleja;

/*
select ou.register_events('{"dokument":"PALK_LEHT","event":"print","status":"Ok","content":"Trükkitatud"}', 2477)

select * from ou.logs
*/
