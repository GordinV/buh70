DROP FUNCTION IF EXISTS import_taotlus_mvt( INTEGER );

CREATE OR REPLACE FUNCTION import_taotlus_mvt(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  mvt_id INTEGER;
  log_id       INTEGER;
  v_mvt  RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_mvt IN
  SELECT
    mvt.*,
    t.rekvid,
    il.new_id AS new_leping_id
  FROM taotlus_mvt mvt
    INNER JOIN tooleping t ON t.id = mvt.lepingid
    INNER JOIN rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
    INNER JOIN import_log il ON il.old_id = t.id AND il.lib_name = 'TOOLEPING'
  WHERE (mvt.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO mvt_id, log_id
    FROM import_log
    WHERE old_id = v_mvt.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TAOTLUS_MVT';

    RAISE NOTICE 'check for lib.. v_mvt.id -> %, found -> % log_id -> %', v_mvt.id, mvt_id, log_id;

    -- преобразование и получение параметров
    -- сохранение
    SELECT
      coalesce(mvt_id, 0)                                    AS id,
      v_mvt.new_leping_id                                    AS lepingid,
      v_mvt.kpv,
      v_mvt.alg_kpv,
      v_mvt.lopp_kpv,
      v_mvt.summa,
      v_mvt.muud                                             AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(mvt_id, 0) AS id,
            TRUE                      AS import,
            v_params                  AS data) row;

    SELECT palk.sp_salvesta_taotlus_mvt(json_object :: JSON, 1, v_mvt.rekvid)
    INTO mvt_id;
    RAISE NOTICE 'mvt_id %, l_count %', mvt_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (mvt_id, v_mvt.id, 'TAOTLUS_MVT', json_object :: JSON, hist_object :: JSON)
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
SELECT import_taotlus_mvt(3304)
SELECT import_taotlus_mvt(id) from taotlus_mvt where
lepingid in (select old_id from import_log where lib_name = 'TOOLEPING')

*/

