DROP FUNCTION IF EXISTS import_arvtasu( INTEGER );

CREATE OR REPLACE FUNCTION import_arvtasu(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  arvtasu_id      INTEGER;
  log_id          INTEGER;
  v_arvtasu       RECORD;
  json_object     JSONB;
  hist_object     JSONB;
  v_params        RECORD;
  l_count         INTEGER = 0;
  l_tulemus       INTEGER = 0;
  l_control_summa NUMERIC;
  l_control_count INTEGER;
  l_j_summa       NUMERIC;
  l_j_count       INTEGER;
  l_journal_id    INTEGER;
  l_arv_id        INTEGER;
  l_tasu_id       INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_arvtasu IN
  SELECT a.*
  FROM arvtasu a
  WHERE (a.id = in_old_id OR in_old_id IS NULL)
  ORDER BY a.kpv
  LIMIT ALL
  LOOP

    RAISE NOTICE 'v_arvtasu.id %', v_arvtasu.id;

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO arvtasu_id, log_id
    FROM import_log
    WHERE old_id = v_arvtasu.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'ARVTASU';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_arvtasu.id, arvtasu_id, log_id;

    -- преобразование и получение параметров
    /*
      doc_rekvid      INTEGER = doc_data ->> 'rekvid';
      doc_doc_arv_id  INTEGER = doc_data ->> 'doc_arv_id';
      doc_doc_tasu_id INTEGER = doc_data ->> 'doc_tasu_id';
      doc_kpv         DATE = doc_data ->> 'kpv';
      doc_summa       NUMERIC(14, 2) = doc_data ->> 'summa';
      doc_dok         TEXT = doc_data ->> 'dok';
      doc_pankkassa   INTEGER = doc_data ->> 'pankkassa';
      doc_muud        TEXT = doc_data ->> 'muud';

     */

    -- сохранение
    SELECT new_id
    INTO l_arv_id
    FROM import_log
    WHERE lib_name = 'ARV' AND old_id = v_arvtasu.arvid;

    IF l_arv_id IS NULL
    THEN
      RAISE EXCEPTION 'arve not found v_arvtasu.arvid %, l_arv_id %', v_arvtasu.arvid, l_arv_id;
    END IF;

    SELECT new_id
    INTO l_tasu_id
    FROM import_log
    WHERE lib_name = (CASE WHEN v_arvtasu.pankkassa = 1
      THEN 'MK'
                      WHEN v_arvtasu.pankkassa = 2
                        THEN 'KORDER'
                      ELSE 'JOURNAL' END) AND old_id = v_arvtasu.sorderid;


    IF l_tasu_id IS NULL
    THEN
      RAISE NOTICE 'tasu not found v_arvtasu.sorderid %, l_tasu_id %', v_arvtasu.sorderid, l_tasu_id;
    END IF;


    SELECT
      coalesce(arvtasu_id, 0) AS id,
      v_arvtasu.rekvid        AS rekvid,
      l_arv_id                AS doc_arv_id,
      v_arvtasu.kpv           AS kpv,
      v_arvtasu.pankkassa     AS pankkassa,
      l_tasu_id               AS doc_tasu_id,
      v_arvtasu.summa         AS summa
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(arvtasu_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT docs.sp_salvesta_arvtasu(json_object :: JSON, 1, v_arvtasu.rekvid)
    INTO arvtasu_id;
    RAISE NOTICE 'lib_id %, l_count %, json_object %', arvtasu_id, l_count, json_object;
    IF empty(arvtasu_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
      RAISE NOTICE 'saved %', arvtasu_id;
    END IF;

    -- правим ссылку на проводку

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (arvtasu_id, v_arvtasu.id, 'ARVTASU', json_object :: JSON, hist_object :: JSON)
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
  l_tulemus = (SELECT count(id)
               FROM docs.arvtasu);
  IF (l_tulemus + 100)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
    --    RAISE notice 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
  END IF;

  IF l_count = 0
  THEN
    RAISE EXCEPTION 'arvtasu not imported %', in_old_id;
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
SELECT import_arvtasu(651187)

SELECT import_arvtasu(id) from arvtasu where year(kpv) >= 2018 order by kpv limit all

*/