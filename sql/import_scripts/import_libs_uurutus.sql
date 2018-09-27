DROP FUNCTION IF EXISTS ou.import_libs_uuritus( );

CREATE OR REPLACE FUNCTION ou.import_libs_uuritus()
  RETURNS INTEGER AS
$BODY$
DECLARE
  lib_id      INTEGER;
  log_id      INTEGER;
  v_lib       RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
BEGIN
  -- выборка из "старого меню"
  FOR v_lib IN
  SELECT l.*
  FROM library l
--  WHERE library IN ('OSAKOND')
  WHERE library IN ('URITUS','TUNNUS','MAKSUKOOD','TP','RAHA','ALLIKAD','TEGEV','OBJEKT','PROJ','LINNAD','KBM','KASUMKAHJU','KAIBEMAKS','TULUDEALLIKAD','PASSIVA','OSAKOND')
  limit all
  LOOP
    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO lib_id, log_id
    FROM import_log
    WHERE old_id = v_lib.id
          AND upper(ltrim(rtrim(lib_name::text))) = upper(ltrim(rtrim(v_lib.library::text)));

--    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_lib.id, lib_id, log_id;

    -- преобразование и получение параметров

    -- сохранение
    SELECT
      coalesce(lib_id, 0) AS id,
      v_lib.kood          AS kood,
      v_lib.nimetus       AS nimetus,
      v_lib.library       AS library,
      v_lib.tun1          AS tun1,
      v_lib.tun2          AS tun2,
      v_lib.tun3          AS tun3,
      v_lib.tun4          AS tun4,
      v_lib.tun5          AS tun5,
      v_lib.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(lib_id, 0) AS id,
            true as import,
            v_params            AS data) row;

    SELECT libs.sp_salvesta_library(json_object :: JSON, 1, v_lib.rekvid)
    INTO lib_id;
--    RAISE NOTICE 'lib_id %, l_count %', lib_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (lib_id, v_lib.id, v_lib.library, json_object :: JSON, hist_object :: JSON)
      returning id into log_id;

    ELSE
      UPDATE import_log
      SET
        params  = json_object :: JSON,
        history = (history :: JSONB || hist_object :: JSONB) :: JSON
      WHERE id = log_id;
    END IF;

    if empty(log_id) THEN
      raise exception 'log save failed';
    END IF;
    l_count = l_count + 1;
  END LOOP;

  /*
  -- control
  IF (SELECT count(id)
      FROM libs.library
      WHERE LIBRARY IN ('URITUS','TUNNUS','MAKSUKOOD','TP','RAHA','ALLIKAD','TEGEV','OBJEKT','PROJ','LINNAD','KBM','KASUMKAHJU','KAIBEMAKS','TULUDEALLIKAD','PASSIVA','OSAKOND')) >= l_count
 --     WHERE LIBRARY IN ('OSAKOND')) >= l_count
  THEN
    raise notice 'Import ->ok';
  ELSE
    raise exception 'Import failed, new_count < old_count %', l_count;


END if;
    */

RETURN l_count;

EXCEPTION WHEN OTHERS
THEN
RAISE NOTICE 'error % %, v_lib %', SQLERRM, SQLSTATE, v_lib;
RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT ou.import_libs_uuritus()

SELECT ou.sp_salvesta_menupohi('{"id":4,"data":{"pad":"test","bar":"","idx":1,"name":"Test", "vene": "Тест", "eesti": "Testid", "level": 1, "users": ["vlad"], "groups": ["KASUTAJA", "PEAKASUTAJA"], "modules": ["EELARVE"]}}'
,1, 1)

select * from ou.menupohi
*/