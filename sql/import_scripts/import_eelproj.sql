DROP FUNCTION IF EXISTS import_eelproj(INTEGER);
/*

DROP FOREIGN TABLE IF EXISTS remote_eelproj;

CREATE FOREIGN TABLE remote_eelproj (
  id SERIAL NOT NULL,
  rekvid    INTEGER              NOT NULL,
  aasta     INTEGER DEFAULT 2008 NOT NULL,
  kuu       INTEGER DEFAULT 0    NOT NULL,
  staatus   INTEGER DEFAULT 0    NOT NULL,
  kinnitaja INTEGER DEFAULT 0    NOT NULL,
  muud      TEXT
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'eelproj');
*/
CREATE OR REPLACE FUNCTION import_eelproj(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  proj_id      INTEGER;
  log_id      INTEGER;
  v_proj       RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_user_id INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_proj IN
  SELECT
    e.*
  FROM eelproj e
  WHERE (e.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO proj_id, log_id
    FROM import_log
    WHERE old_id = v_proj.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'EELPROJ';


    RAISE NOTICE 'check for lib.. v_proj.id -> %, found -> % log_id -> %', v_proj.id, proj_id, log_id;

    -- преобразование и получение параметров

    -- userid
    l_user_id = (select new_id from import_log where old_id = v_proj.kinnitaja and lib_name = 'USERID');
    if l_user_id is null THEN
      raise NOTICE 'User not found v_proj.kinnitaja %, l_user_id %', v_proj.kinnitaja, l_user_id;
    END IF;

    -- сохранение
    SELECT
      coalesce(proj_id, 0) AS id,
      v_proj.rekvid        AS rekvid,
      v_proj.aasta as aasta,
      l_user_id as kinnitaja,
      v_proj.kuu as kuu,
      v_proj.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(proj_id, 0) AS id,
            TRUE                AS import,
            v_params            AS data) row;

    SELECT eelarve.sp_salvesta_eelproj(json_object :: JSON, 1, v_proj.rekvid)
    INTO proj_id;
    RAISE NOTICE 'import eelproj proj_id %, l_count %', proj_id, l_count;

    if empty(proj_id) THEN
      raise EXCEPTION 'eelproj not saved json_object %', json_object;
    END IF;

    -- status
    update eelarve.eelproj set status = v_proj.staatus where id = proj_id;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL or empty(log_id)
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (proj_id, v_proj.id, 'EELPROJ', json_object :: JSON, hist_object :: JSON)
      RETURNING id
        INTO log_id;

    ELSE
      UPDATE import_log
      SET
        params  = json_object :: JSON,
        history = (history :: JSONB || hist_object :: JSONB) :: JSON
      WHERE id = log_id;
    END IF;

    IF empty(log_id)
    THEN
      RAISE EXCEPTION 'log save failed';
    END IF;
    l_count = l_count + 1;
  END LOOP;


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_eelproj(e.id) from remote_eelproj e inner join rekv r on e.rekvid = r.id and r.parentid < 999

*/