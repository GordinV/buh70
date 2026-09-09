DROP FUNCTION IF EXISTS ou.execute_task(JSONB);

CREATE OR REPLACE FUNCTION ou.execute_task(params JSONB)
    RETURNS INTEGER AS
$BODY$

DECLARE
    l_count        integer = 0;
    v_task         record;
    l_task_id      integer; -- task id fro result
    l_only_task_id integer = params ->> 'doc_id';
    l_start        timestamp;
    l_finish       timestamp;
    l_exec_time    interval;
BEGIN
    for v_task in (
                      select *
                      from
                          ou.task t
                      where
                           status = 0
                               and l_only_task_id is null
                        or (t.id = l_only_task_id::integer)
                  )
        loop
            l_task_id = v_task.id;
            l_start = clock_timestamp();
            raise notice 'v_task.sql %',v_task.sql;
            EXECUTE v_task.sql;
            l_finish = clock_timestamp();
            l_exec_time = l_finish - l_start;
            update ou.task
            set
                status     = 1,
                finished   = l_finish,
                properties = coalesce(properties, '{}'::jsonb) || jsonb_build_object('execute_time', l_exec_time)
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

