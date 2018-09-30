DROP FUNCTION IF EXISTS import_holidays( INTEGER );

CREATE OR REPLACE FUNCTION import_holidays(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  holiday_id    INTEGER;
  log_id       INTEGER;
  v_holiday     RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_holiday IN
  SELECT l.*
  FROM holidays l
    INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
  WHERE (l.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO holiday_id, log_id
    FROM import_log
    WHERE old_id = v_holiday.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TAHTPAEV';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_holiday.id, holiday_id, log_id;

    -- преобразование и получение параметров

    -- сохранение
    SELECT
      coalesce(holiday_id, 0) AS id,
      left(v_holiday.nimetus,20) as kood,
      v_holiday.nimetus,
      'TAHTPAEV' as library,
      v_holiday.kuu,
      v_holiday.paev,
      v_holiday.luhipaev,
      year(date()) as aasta,
      v_holiday.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(holiday_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT libs.sp_salvesta_tahtpaev(json_object :: JSON, 1, v_holiday.rekvid)
    INTO holiday_id;
    RAISE NOTICE 'lib_id %, l_count %, v_params %', holiday_id, l_count, v_params;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (holiday_id, v_holiday.id, 'TAHTPAEV', json_object :: JSON, hist_object :: JSON)
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
select count(*) from cur_tahtapevad

SELECT import_holidays(null)
SELECT import_osakonnad(id)
from library
where library = 'OSAKOND'
INSERT INTO library (id, rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, vanaid) VALUES (287561, 108, '0922054             ', 'Narva Kreenholmi G𭮡asium 0922054                                                                                                                                                                                                                           ', 'OSAKOND             ', NULL, 0, 0, 0, 0, 0, NULL);

*/