DROP FUNCTION IF EXISTS import_amet( );

CREATE OR REPLACE FUNCTION import_amet()
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
  l_osakondid INTEGER;
  l_tunnusid  INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_lib IN
  SELECT
    l.id,
    l.kood,
    l.nimetus,
    l.library,
    l.muud,
    pa.rekvid,
    pa.osakondid,
    pa.ametid,
    pa.kogus,
    (CASE WHEN empty(pa.palgamaar)
      THEN NULL
     ELSE pa.palgamaar END) :: INTEGER AS palgamaar,
    (CASE WHEN empty(pa.tunnusid)
      THEN NULL
     ELSE pa.tunnusid END) :: INTEGER  AS tunnusid
  FROM library l
    INNER JOIN palk_asutus pa ON pa.ametid = l.id
    INNER JOIN rekv ON rekv.id = pa.rekvid AND rekv.parentid < 999
    INNER JOIN library o ON o.id = pa.osakondid
  WHERE l.library = 'AMET'
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO lib_id, log_id
    FROM import_log
    WHERE old_id = v_lib.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = upper(ltrim(rtrim(v_lib.library :: TEXT)));

    -- поиск osakond_id
    IF v_lib.osakondid IS NOT NULL
    THEN
      SELECT new_id
      INTO l_osakondid
      FROM import_log
      WHERE lib_name = 'OSAKOND'
            AND old_id = v_lib.osakondid;

      IF NOT found
      THEN
        RAISE EXCEPTION 'Osakond not found osakondid-> %', v_lib.osakondid;
      END IF;
    ELSE
      l_osakondid = NULL;

    END IF;

    -- поиск tunnusid

    IF v_lib.tunnusid IS NOT NULL
    THEN
      SELECT new_id
      INTO l_tunnusid
      FROM import_log
      WHERE lib_name = 'TUNNUS'
            AND old_id = v_lib.tunnusid;

    ELSE
      l_tunnusid = NULL;

    END IF;

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %, l_osakondid -> %,  l_tunnusid -> %', v_lib.id, lib_id, log_id, l_osakondid, l_tunnusid;

    -- преобразование и получение параметров

    -- сохранение
    SELECT
      coalesce(lib_id, 0) AS id,
      v_lib.kood          AS kood,
      v_lib.nimetus       AS nimetus,
      l_osakondid         AS osakondid,
      l_tunnusid          AS tunnusid,
      v_lib.kogus         AS kogus,
      v_lib.palgamaar     AS palgamaar,
      v_lib.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(lib_id, 0) AS id,
            v_params            AS data) row;

    SELECT libs.sp_salvesta_amet(json_object :: JSON, 1, 1)
    INTO lib_id;
    RAISE NOTICE 'lib_id %, l_count %', lib_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (lib_id, v_lib.id, v_lib.library, json_object :: JSON, hist_object :: JSON)
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

  -- control
  IF (SELECT count(id)
      FROM libs.library
      WHERE LIBRARY = 'AMET')
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count %', l_count;
  END IF;


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_amet()

*/