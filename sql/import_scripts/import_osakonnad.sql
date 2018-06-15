DROP FUNCTION IF EXISTS import_osakonnad( INTEGER );

CREATE OR REPLACE FUNCTION import_osakonnad(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  osakond_id    INTEGER;
  log_id       INTEGER;
  v_osakond     RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_osakond IN
  SELECT l.*
  FROM library l
    INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
  WHERE (l.id = in_old_id OR in_old_id IS NULL)
    and l.library = 'OSAKOND'
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO osakond_id, log_id
    FROM import_log
    WHERE old_id = v_osakond.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'OSAKOND';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_osakond.id, osakond_id, log_id;

    -- преобразование и получение параметров
    /*
   doc_kood    TEXT = doc_data ->> 'kood';
  doc_nimetus TEXT = doc_data ->> 'nimetus';
  doc_library TEXT = doc_data ->> 'library';
  doc_tun1    INTEGER = doc_data ->> 'tun1'; --liik
  doc_tun2    INTEGER = doc_data ->> 'tun2'; -- tegev
  doc_tun3    INTEGER = doc_data ->> 'tun3'; -- allikas
  doc_tun4    INTEGER = doc_data ->> 'tun4'; -- rahavoog
  doc_tun5    INTEGER = doc_data ->> 'tun5';
  doc_muud    TEXT = doc_data ->> 'muud';
     */
    -- сохранение
    SELECT
      coalesce(osakond_id, 0) AS id,
      v_osakond.kood,
      v_osakond.nimetus,
      v_osakond.library,
      v_osakond.tun1,
      v_osakond.tun2,
      v_osakond.tun3,
      v_osakond.tun4,
      v_osakond.tun5,
      v_osakond.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(osakond_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT libs.sp_salvesta_library(json_object :: JSON, 1, v_osakond.rekvid)
    INTO osakond_id;
    RAISE NOTICE 'lib_id %, l_count %', osakond_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (osakond_id, v_osakond.id, 'OSAKOND', json_object :: JSON, hist_object :: JSON)
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
SELECT import_osakonnad(672108)
SELECT import_osakonnad(id)
from library
where library = 'OSAKOND'
INSERT INTO library (id, rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, vanaid) VALUES (287561, 108, '0922054             ', 'Narva Kreenholmi G𭮡asium 0922054                                                                                                                                                                                                                           ', 'OSAKOND             ', NULL, 0, 0, 0, 0, 0, NULL);

*/