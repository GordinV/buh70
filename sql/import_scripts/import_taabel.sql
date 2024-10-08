DROP FUNCTION IF EXISTS import_taabel( INTEGER );


DROP FOREIGN TABLE IF EXISTS remote_palk_taabel1;

CREATE FOREIGN TABLE remote_palk_taabel1 (
  id        INTEGER                    NOT NULL,
  toolepingid INTEGER        DEFAULT 0                          NOT NULL,
  kuu         SMALLINT       DEFAULT month(('now'::TEXT)::DATE) NOT NULL,
  aasta       SMALLINT       DEFAULT year(('now'::TEXT)::DATE)  NOT NULL,
  muud        TEXT,
  kokku       NUMERIC(12, 4) DEFAULT 0,
  too         NUMERIC(12, 4) DEFAULT 0,
  paev        NUMERIC(12, 4) DEFAULT 0,
  ohtu        NUMERIC(12, 4) DEFAULT 0,
  oo          NUMERIC(12, 4) DEFAULT 0,
  tahtpaev    NUMERIC(12, 4) DEFAULT 0,
  puhapaev    NUMERIC(12, 4) DEFAULT 0,
  uleajatoo   NUMERIC(12, 4) DEFAULT 0
  )  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'palk_taabel1');



CREATE OR REPLACE FUNCTION import_taabel(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  taabel_id INTEGER;
  log_id       INTEGER;
  v_taabel  RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_lib_id     INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_taabel IN
  SELECT
    pt.*,
    t.rekvid,
    il.new_id AS new_leping_id
  FROM remote_palk_taabel1 pt
    INNER JOIN remote_tooleping t ON t.id = pt.toolepingid
    INNER JOIN remote_rekv rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
    INNER JOIN import_log il ON il.old_id = t.id AND il.lib_name = 'TOOLEPING'
  WHERE (pt.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO taabel_id, log_id
    FROM import_log
    WHERE old_id = v_taabel.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TAABEL';

    RAISE NOTICE 'check for lib.. v_taabel.id -> %, found -> % log_id -> %', v_taabel.id, taabel_id, log_id;

    -- преобразование и получение параметров
    -- сохранение
    SELECT
      coalesce(taabel_id, 0)                                    AS id,
      v_taabel.new_leping_id                                    AS lepingid,
      v_taabel.kuu,
      v_taabel.aasta,
      v_taabel.kokku,
      v_taabel.too,
      v_taabel.paev,
      v_taabel.ohtu,
      v_taabel.oo,
      v_taabel.tahtpaev,
      v_taabel.puhapaev,
      v_taabel.uleajatoo,
      v_taabel.muud                                             AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(taabel_id, 0) AS id,
            TRUE                      AS import,
            v_params                  AS data) row;

    SELECT palk.sp_salvesta_palk_taabel(json_object :: JSON, 1, v_taabel.rekvid)
    INTO taabel_id;
    RAISE NOTICE 'puudumine_id %, l_count %', taabel_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (taabel_id, v_taabel.id, 'TAABEL', json_object :: JSON, hist_object :: JSON)
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
SELECT import_taabel(508428)
SELECT import_taabel(id) from palk_taabel1 where
toolepingid in (select old_id from import_log where lib_name = 'TOOLEPING')

*/

