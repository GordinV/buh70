DROP FUNCTION IF EXISTS import_ametid( INTEGER );

CREATE OR REPLACE FUNCTION import_ametid(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  amet_id      INTEGER;
  log_id       INTEGER;
  v_amet       RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_osakond_id INTEGER;
  l_tunnus_id  INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_amet IN
  SELECT
    l.*,
    pa.ametid,
    pa.osakondid,
    pa.tunnusid,
    pa.palgamaar,
    pa.kogus
  FROM library l
    INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
    INNER JOIN palk_asutus pa ON l.id = pa.ametid
  WHERE (l.id = in_old_id OR in_old_id IS NULL)
        AND l.library = 'AMET'
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO amet_id, log_id
    FROM import_log
    WHERE old_id = v_amet.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'AMET';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_amet.id, amet_id, log_id;

    l_osakond_id = (SELECT new_id
                    FROM import_log
                    WHERE lib_name = 'OSAKOND' AND old_id = v_amet.osakondid);

    l_tunnus_id = (select new_id from import_log where lib_name = 'TUNNUS' and old_id = v_amet.tunnusid);
    -- преобразование и получение параметров
    /*
  doc_kood      TEXT = doc_data ->> 'kood';
  doc_nimetus   TEXT = doc_data ->> 'nimetus';
  doc_library   TEXT = 'AMET';
  doc_osakondId INTEGER = doc_data ->> 'osakondid';
  doc_kogus     NUMERIC(18, 2) = doc_data ->> 'kogus';
  doc_palgamaar INTEGER = doc_data ->> 'palgamaar';
  doc_tunnusId  INTEGER = doc_data ->> 'tunnusid';
  doc_muud      TEXT = doc_data ->> 'muud';
     */
    -- сохранение
    SELECT
      coalesce(amet_id, 0) AS id,
      l_osakond_id         AS osakondid,
      l_tunnus_id as tunnusid,
      v_amet.kogus,
      v_amet.palgamaar,
      v_amet.kood,
      v_amet.nimetus,
      v_amet.library,
      v_amet.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(amet_id, 0) AS id,
            TRUE                 AS import,
            v_params             AS data) row;

    SELECT libs.sp_salvesta_amet(json_object :: JSON, 1, v_amet.rekvid)
    INTO amet_id;
    RAISE NOTICE 'lib_id %, l_count %', amet_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (amet_id, v_amet.id, 'AMET', json_object :: JSON, hist_object :: JSON)
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
SELECT import_ametid(611504)

SELECT import_ametid(library.id)
from library
inner join rekv on rekv.id = library.rekvid and rekv.parentid < 999
where library = 'AMET'

*/