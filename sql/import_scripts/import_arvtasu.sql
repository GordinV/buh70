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
    INTO l_asutus
    FROM import_log
    WHERE lib_name = 'ASUTUS' AND old_id = v_arvtasu.asutusid;

    SELECT
      coalesce(arvtasu_id, 0) AS id,
      l_asutus                AS asutusid,
      v_arvtasu.kpv           AS kpv,
      v_arvtasu.liik          AS liik,
      v_arvtasu.number        AS number,
      v_arvtasu.lisa          AS lisa,
      v_arvtasu.tahtaeg       AS tahtaeg,
      v_arvtasu.kbmta         AS kbmta,
      v_arvtasu.kbm           AS kbm,
      v_arvtasu.summa         AS summa,
      v_arvtasu.objekt        AS objekt,
      v_arvtasu.muud          AS muud,
      json_arv1               AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(arvtasu_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT docs.sp_salvesta_arv(json_object :: JSON, 1, v_arvtasu.rekvid)
    INTO arvtasu_id;
    RAISE NOTICE 'lib_id %, l_count %, json_object %', arvtasu_id, l_count, json_object;
    IF empty(arvtasu_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
      RAISE NOTICE 'saved %', arvtasu_id;
    END IF;

    -- правим ссылку на проводку

    IF year(v_arvtasu.kpv) = 2018 AND NOT empty(v_arvtasu.journalid)
    THEN
      SELECT new_id
      INTO l_journal_id
      FROM import_log
      WHERE old_id = v_arvtasu.journalid AND lib_name = 'JOURNAL';

      IF l_journal_id IS NOT NULL
      THEN
        UPDATE docs.arv
        SET journalid = l_journal_id
        WHERE id = arvtasu_id;
      END IF;
    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (arvtasu_id, v_arvtasu.id, 'ARV', json_object :: JSON, hist_object :: JSON)
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

    -- проверка на сумму проводки и кол-во записей

    SELECT
      count(id),
      sum(summa)
    INTO l_control_count, l_control_summa
    FROM cur_journal
    WHERE id = arvtasu_id;

    SELECT
      count(j1.id),
      sum(j1.summa)
    INTO l_j_count, l_j_summa
    FROM journal j INNER JOIN journal1 j1 ON j.id = j1.parentid
    WHERE j.id = v_arvtasu.id;
    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_journal.id % , journal_id %, l_control_summa %, l_j_summa %,, l_control_count %, l_j_count %', v_arvtasu.id, arvtasu_id, l_control_summa, l_j_summa, l_control_count, l_j_count;
    END IF;
    l_count = l_count + 1;
  END LOOP;

  -- control
  l_tulemus = (SELECT count(id)
               FROM docs.journal);
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
    RAISE EXCEPTION 'arve not imported %', in_old_id;
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
SELECT import_arv(420644)

SELECT import_arv(id) from arv where year(kpv) = 2018 order by kpv limit all

*/