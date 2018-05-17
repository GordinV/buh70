-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS sp_execute_task( INTEGER, JSON, TEXT );

CREATE OR REPLACE FUNCTION sp_execute_task(
  IN  user_id       INTEGER,
  IN  params        JSON,
  IN  task          TEXT,
  OUT error_code    INTEGER,
  OUT result        INTEGER,
  OUT error_message TEXT,
  OUT data          JSONB
)
  RETURNS RECORD AS
$BODY$

DECLARE
  tulemus RECORD;
BEGIN

  -- проверка на пользователя и его соответствие учреждению

  IF NOT exists(SELECT id
                FROM ou.userid u
                WHERE id = user_id
  )
  THEN

    error_code = 5;
    error_message = 'Kasutaja ei leitud, userId:' ||
                    coalesce(userid, 0) :: TEXT;
    result = 0;
    RETURN;

  END IF;

  -- check if task exists

  IF task IS NULL OR NOT exists(
      SELECT 1
      FROM pg_proc pp
        INNER JOIN pg_namespace pn ON pp.pronamespace = pn.oid
      WHERE upper(nspname) || '.' || upper(proname) = upper(task)
  )
  THEN
    error_code = 7;
    error_message = 'Task ei leitud:' ||
                    coalesce(task, '') :: TEXT;
    result = 0;
    RETURN;

  END IF;

  --call the task

  EXECUTE 'select * from ' || task || '($1, $2)'
  INTO STRICT tulemus
  USING user_id, params;

  error_code = tulemus.error_code;
  result = tulemus.result;
  error_message = tulemus.error_message;


  IF tulemus.result IS NULL
  THEN
    result = 1;
  END IF;

  -- отправим результат в json
  data = row_to_json(tulemus);

  RETURN;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    error_message = SQLERRM;
    result = 0;
    RETURN;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

