DROP FUNCTION IF EXISTS import_journal( );
DROP FUNCTION IF EXISTS import_journal( integer);

CREATE OR REPLACE FUNCTION import_journal(in_old_id integer)
  RETURNS INTEGER AS
$BODY$
DECLARE
  journal_id      INTEGER;
  log_id          INTEGER;
  v_journal       RECORD;
  json_object     JSONB;
  hist_object     JSONB;
  v_params        RECORD;
  l_count         INTEGER = 0;
  l_tulemus       INTEGER = 0;
  json_journal1   JSONB;
  l_asutus        INTEGER;
  l_control_summa NUMERIC;
  l_control_count INTEGER;
  l_j_summa       NUMERIC;
  l_j_count       INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_journal IN
  SELECT
    j.*,
    jid.number
  FROM journal j
    INNER JOIN rekv ON j.rekvid = rekv.id AND rekv.parentid < 999
    INNER JOIN (SELECT
                  max(number) AS number,
                  journalid
                FROM journalid jid
                GROUP BY journalid) jid ON jid.journalid = j.id
  WHERE exists(SELECT 1
               FROM journal1
               WHERE parentid = j.id)
        AND (j.id = in_old_id or in_old_id is null)
--    and rekvid = 63
    order by j.kpv
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO journal_id, log_id
    FROM import_log
    WHERE old_id = v_journal.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'JOURNAL';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_journal.id, journal_id, log_id;

    -- преобразование и получение параметров
    -- journal1

    json_journal1 = array_to_json((SELECT array_agg(row_to_json(j1.*))
                                   FROM (SELECT
                                           journal1.deebet,
                                           kreedit,
                                           summa,
                                           tunnus,
                                           proj,
                                           kood1,
                                           kood2,
                                           kood3,
                                           kood4,
                                           kood5,
                                           lisa_d,
                                           lisa_k
                                         FROM journal1
                                         WHERE parentid = v_journal.id) AS j1
                                  ));

    -- сохранение
    SELECT new_id
    INTO l_asutus
    FROM import_log
    WHERE lib_name = 'ASUTUS' AND old_id = v_journal.asutusid;

    SELECT
      coalesce(journal_id, 0) AS id,
      l_asutus                AS asutusid,
      v_journal.kpv           AS kpv,
      v_journal.selg          AS selg,
      v_journal.dok           AS dok,
      v_journal.muud          AS muud,
      json_journal1           AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(journal_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT docs.sp_salvesta_journal(json_object :: JSON, 1, v_journal.rekvid)
    INTO journal_id;
    RAISE NOTICE 'lib_id %, l_count %, json_object %', journal_id, l_count, json_object;
    IF empty(journal_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    END IF;

    -- правим номер проводки

    UPDATE docs.journalid
    SET number = v_journal.number
    WHERE journalid IN (SELECT id
                        FROM docs.journal
                        WHERE parentid = journal_id);

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (journal_id, v_journal.id, 'JOURNAL', json_object :: JSON, hist_object :: JSON)
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
    WHERE id = journal_id;

    SELECT
      count(j1.id),
      sum(j1.summa)
    INTO l_j_count, l_j_summa FROM journal j INNER JOIN journal1 j1 ON j.id = j1.parentid WHERE j.id = v_journal.id;
    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_journal.id % , journal_id %, l_control_summa %, l_j_summa %,, l_control_count %, l_j_count %', v_journal.id,journal_id, l_control_summa,l_j_summa,l_control_count, l_j_count;
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


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_journal(null)

*/