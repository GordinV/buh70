DROP FUNCTION IF EXISTS ou.execute_task(JSONB);

CREATE OR REPLACE FUNCTION ou.execute_task(params JSONB)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_count   integer = 0;
    v_task    record;
    l_task_id integer; -- task id fro result
BEGIN
    for v_task in (
                      select *
                      from
                          ou.task t
                      where
                          status = 0
                  )
        loop
            l_task_id = v_task.id;
            EXECUTE v_task.sql;
            update ou.task
            set
                status   = 1,
                finished = now()
            where
                id = l_task_id;
            l_count = l_count + 1;
        end loop;

    return l_count;
EXCEPTION
    WHEN OTHERS
        THEN
--            RAISE 'error % %', SQLERRM, SQLSTATE;
            update ou.task
            set
                status    = 2,
                tulemused = coalesce(SQLERRM, '') || ',' || coalesce(SQLSTATE, '')
            where
                id = l_task_id;

            RETURN 0;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


GRANT EXECUTE ON FUNCTION ou.execute_task(JSONB) TO dbadmin;
GRANT EXECUTE ON FUNCTION ou.execute_task(JSONB) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION ou.execute_task(JSONB) TO dbpeakasutaja;

--select ou.execute_task(null::JSONB);

