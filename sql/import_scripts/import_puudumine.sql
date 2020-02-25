DROP FUNCTION IF EXISTS import_puudumine( INTEGER );


DROP FOREIGN TABLE IF EXISTS remote_puudumine;

CREATE FOREIGN TABLE remote_puudumine (
  id        INTEGER                    NOT NULL,
  kpv1     DATE           DEFAULT ('now'::TEXT)::DATE NOT NULL,
  kpv2     DATE           DEFAULT ('now'::TEXT)::DATE NOT NULL,
  paevad   INTEGER        DEFAULT 0                   NOT NULL,
  summa    NUMERIC(12, 4) DEFAULT 0                   NOT NULL,
  tunnus   INTEGER        DEFAULT 0                   NOT NULL,
  tyyp     INTEGER        DEFAULT 0                   NOT NULL,
  muud     TEXT,
  libid    INTEGER        DEFAULT 0,
  lepingid INTEGER
  )  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'puudumine');


CREATE OR REPLACE FUNCTION import_puudumine(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  puudumine_id INTEGER;
  log_id       INTEGER;
  v_puudumine  RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_lib_id     INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_puudumine IN
  SELECT
    p.*,
    t.rekvid,
    il.new_id AS new_leping_id
  FROM remote_puudumine p
    INNER JOIN remote_tooleping t ON t.id = p.lepingid
    INNER JOIN remote_rekv rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
    INNER JOIN import_log il ON il.old_id = t.id AND il.lib_name = 'TOOLEPING'
  WHERE (p.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO puudumine_id, log_id
    FROM import_log
    WHERE old_id = v_puudumine.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'PUUDUMINE';

    RAISE NOTICE 'check for lib.. v_puudumine.id -> %, found -> % log_id -> %', v_puudumine.id, puudumine_id, log_id;

    l_lib_id = (select new_id from import_log where lib_name = 'PALK' and old_id = v_puudumine.libid);
    -- преобразование и получение параметров
    -- сохранение
    SELECT
      coalesce(puudumine_id, 0)                                    AS id,
      v_puudumine.kpv1,
      v_puudumine.kpv2,
      v_puudumine.paevad,
      (enum_range(NULL :: PUUDUMISTE_LIIGID)) [v_puudumine.tunnus] AS puudumiste_liik,
      l_lib_id as libid,
      v_puudumine.tyyp,
      v_puudumine.new_leping_id                                    AS lepingid,
      v_puudumine.summa,
      v_puudumine.muud                                             AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(puudumine_id, 0) AS id,
            TRUE                      AS import,
            v_params                  AS data) row;

    SELECT palk.sp_salvesta_puudumine(json_object :: JSON, 1, v_puudumine.rekvid)
    INTO puudumine_id;
    RAISE NOTICE 'puudumine_id %, l_count %', puudumine_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (puudumine_id, v_puudumine.id, 'PUUDUMINE', json_object :: JSON, hist_object :: JSON)
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
SELECT import_puudumine(83330)
SELECT import_puudumine(id) from puudumine where
lepingid in (select old_id from import_log where lib_name = 'TOOLEPING')

*/