DROP FOREIGN TABLE IF EXISTS remote_journal;
DROP FOREIGN TABLE IF EXISTS remote_journal1;
DROP FOREIGN TABLE IF EXISTS remote_journalid;


CREATE FOREIGN TABLE remote_journalid (
  id SERIAL NOT NULL,
  rekvid INTEGER NOT NULL,
  journalid INTEGER NOT NULL,
  number INTEGER DEFAULT 0 NOT NULL,
  aasta INTEGER DEFAULT year() NOT NULL
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'journalid');

CREATE FOREIGN TABLE remote_journal (
  id SERIAL NOT NULL,
  rekvid INTEGER NOT NULL,
  userid INTEGER NOT NULL,
  kpv DATE DEFAULT ('now'::TEXT)::DATE NOT NULL,
  asutusid INTEGER DEFAULT 0 NOT NULL,
  selg TEXT DEFAULT space(1) NOT NULL,
  dok CHAR(60) DEFAULT space(1) NOT NULL,
  muud TEXT,
  dokid INTEGER DEFAULT 0 NOT NULL,
  objekt VARCHAR(20) DEFAULT space(20)
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'journal');

CREATE FOREIGN TABLE remote_journal1 (
  id SERIAL NOT NULL,
  parentid INTEGER NOT NULL,
  summa NUMERIC(16,4) DEFAULT 0 NOT NULL,
  dokument CHAR(20) DEFAULT space(1),
  muud TEXT,
  kood1 VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood2 VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood3 VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood4 VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood5 VARCHAR(20) DEFAULT space(20) NOT NULL,
  deebet VARCHAR(20) DEFAULT space(20) NOT NULL,
  lisa_k VARCHAR(20) DEFAULT space(20) NOT NULL,
  kreedit VARCHAR(20) DEFAULT space(20) NOT NULL,
  lisa_d VARCHAR(20) DEFAULT space(20) NOT NULL,
  valuuta VARCHAR(20) DEFAULT space(20) NOT NULL,
  kuurs NUMERIC(12,6) DEFAULT 1 NOT NULL,
  valsumma NUMERIC(16,4) DEFAULT 0 NOT NULL,
  tunnus VARCHAR(20) DEFAULT space(20) NOT NULL,
  proj VARCHAR(20) DEFAULT space(1)
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'journal1');

DROP FUNCTION IF EXISTS import_journal();
DROP FUNCTION IF EXISTS import_journal(INTEGER);

CREATE OR REPLACE FUNCTION import_journal(in_old_id INTEGER)
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
    FROM remote_journal j
           INNER JOIN rekv ON j.rekvid = rekv.id AND rekv.parentid < 999
           INNER JOIN (SELECT
                         max(number) AS number,
                         journalid
                       FROM remote_journalid jid
                       GROUP BY journalid) jid ON jid.journalid = j.id
    WHERE exists(SELECT 1
                 FROM remote_journal1
                 WHERE parentid = j.id)
      AND (j.id = in_old_id OR in_old_id IS NULL)
      --    and rekvid = 63
    ORDER BY j.kpv
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
                                           FROM remote_journal1 journal1
                                           WHERE parentid = v_journal.id) AS j1
      ));

      -- сохранение
      SELECT new_id
             INTO l_asutus
      FROM import_log
      WHERE lib_name = 'ASUTUS'
        AND old_id = v_journal.asutusid;

      SELECT
        coalesce(journal_id, 0)                 AS id,
        l_asutus                                AS asutusid,
        v_journal.kpv                           AS kpv,
        encode(v_journal.selg::BYTEA, 'escape') AS selg,
        v_journal.dok                           AS dok,
        v_journal.muud                          AS muud,
        json_journal1                           AS "gridData"
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
        INTO l_j_count, l_j_summa
      FROM remote_journal j
             INNER JOIN remote_journal1 j1 ON j.id = j1.parentid
      WHERE j.id = v_journal.id;
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

  EXCEPTION
  WHEN OTHERS
    THEN
      RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
      RETURN 0;

END;
$BODY$
  LANGUAGE plpgsql
  VOLATILE
  COST 100;


/*
SELECT import_journal(null)

*/