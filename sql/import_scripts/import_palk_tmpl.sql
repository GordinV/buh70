DROP FUNCTION IF EXISTS import_palk_tmpl( INTEGER );

CREATE OR REPLACE FUNCTION import_palk_tmpl(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  pt_id       INTEGER;
  log_id      INTEGER;
  v_pt        RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_asutus_id INTEGER;
  l_lib_id    INTEGER;
  l_tunnus    TEXT;
BEGIN
  -- выборка из "старого меню"

  FOR v_pt IN
  SELECT
    pt.*,
    l.rekvid,
    il.new_id AS new_amet_id,
    il_lib.NEW_id as new_lib_id
  FROM palk_tmpl pt
    INNER JOIN library l ON l.id = pt.parentid
    INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
    INNER JOIN import_log il ON il.old_id = l.id AND il.lib_name = 'AMET'
    INNER JOIN import_log il_lib ON il_lib.old_id = pt.libid AND il_lib.lib_name = 'PALK'
  WHERE (pt.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO pt_id, log_id
    FROM import_log
    WHERE old_id = v_pt.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'PALK_TMPL';

    RAISE NOTICE 'check for lib.. v_pk.id -> %, found -> % log_id -> %', v_pt.id, pt_id, log_id;

    l_tunnus = (SELECT kood
                FROM library
                WHERE id = v_pt.tunnusid);

    -- преобразование и получение параметров
    /*
  doc_parentid INTEGER = doc_data ->> 'parentid';
  doc_libid    INTEGER = doc_data ->> 'libid';
  doc_summa    NUMERIC(14, 4) = doc_data ->> 'summa';
  doc_percent_ INTEGER = doc_data ->> 'percent_';
  doc_tulumaks INTEGER = doc_data ->> 'tulumaks';
  doc_tulumaar INTEGER = doc_data ->> 'tulumaar';
  doc_tunnus   TEXT = doc_data ->> 'tunnus';
  doc_muud     TEXT = doc_data ->> 'muud';
     */
    -- сохранение
    SELECT
      coalesce(pt_id, 0) AS id,
      v_pt.new_amet_id        AS parentid,
      v_pt.new_lib_id           AS libid,
      v_pt.summa,
      v_pt.percent_,
      v_pt.tulumaks,
      v_pt.tulumaar,
      l_tunnus           AS tunnus
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(pt_id, 0) AS id,
            TRUE               AS import,
            v_params           AS data) row;

    SELECT palk.sp_salvesta_palk_tmpl(json_object :: JSON, 1,v_pt.rekvid)
    INTO pt_id;
    RAISE NOTICE 'pk_id %, l_count %', pt_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (pt_id, v_pt.id, 'PALK_TMPL', json_object :: JSON, hist_object :: JSON)
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

raise notice 'tulemus l_count %, in_old_id %', l_count, in_old_id;
  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_palk_tmpl(33535)
SELECT import_palk_tmpl(id) from palk_tmpl where
parentid in (select old_id from import_log where lib_name = 'AMET')

*/