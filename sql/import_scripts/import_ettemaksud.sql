drop FOREIGN TABLE if exists remote_ettemaksud;

CREATE FOREIGN TABLE remote_ettemaksud (
  id        SERIAL                   NOT NULL,
  rekvid    INTEGER                  NOT NULL,
  kpv       DATE                     NOT NULL,
  summa     NUMERIC(18, 6) DEFAULT 0 NOT NULL,
  number    INTEGER DEFAULT 0        NOT NULL,
  asutusid  INTEGER                  NOT NULL,
  dokid     INTEGER                  NOT NULL,
  doktyyp   INTEGER DEFAULT 1        NOT NULL,
  selg      TEXT,
  muud      TEXT,
  staatus   INTEGER DEFAULT 1        NOT NULL,
  journalid INTEGER DEFAULT 0        NOT NULL)
  SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'ettemaksud');


DROP FUNCTION IF EXISTS import_ettemaksud( INTEGER );

CREATE OR REPLACE FUNCTION import_ettemaksud(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  ettemaks_id  INTEGER;
  log_id       INTEGER;
  v_ettemaksud RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_asutus_id  INTEGER;
  l_luba_id    INTEGER;
  l_status     DOK_STATUS;
  l_journal    INTEGER;
  l_dekl       INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_ettemaksud IN
  SELECT e.*
  FROM remote_ettemaksud e
  WHERE (e.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP
    RAISE NOTICE 'in_old_id %', in_old_id;
    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO ettemaks_id, log_id
    FROM import_log
    WHERE old_id = v_ettemaksud.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'ETTEMAKSUD';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_ettemaksud.id, ettemaks_id, log_id;

    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_ettemaksud.asutusid AND lib_name = 'ASUTUS');

    l_journal = (SELECT new_id
                 FROM import_log
                 WHERE old_id = v_ettemaksud.journalid AND lib_name = 'JOURNAL');

    IF v_ettemaksud.doktyyp = 1
    THEN
      l_dekl = (SELECT new_id
                FROM import_log
                WHERE old_id = v_ettemaksud.dokid AND lib_name = 'TOIMING');
    ELSE
      l_dekl = (SELECT new_id
                FROM import_log
                WHERE old_id = v_ettemaksud.dokid AND lib_name = 'JOURNAL');

    END IF;

    IF l_asutus_id IS NULL
    THEN
      RAISE EXCEPTION 'asutus not found l_asutus_id % ', l_asutus_id;
    END IF;
    -- преобразование и получение параметров


    -- сохранение
    SELECT
      coalesce(ettemaks_id, 0) AS id,
      l_asutus_id              AS asutusid,
      v_ettemaksud.kpv,
      v_ettemaksud.summa,
      v_ettemaksud.selg,
      v_ettemaksud.number,
      v_ettemaksud.rekvid,
      (CASE WHEN v_ettemaksud.doktyyp = 1
        THEN 'DEEBET'
       ELSE 'KREEDIT' END)     AS doktyyp,
      v_ettemaksud.muud,
      (CASE WHEN v_ettemaksud.staatus = 0
        THEN 'active'
       ELSE 'closed' END)      AS staatus
    INTO v_params;


    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(ettemaks_id, 0) AS id,
            TRUE                     AS import,
            v_params                 AS data) row;

    SELECT rekl.sp_salvesta_ettemaksud(json_object :: JSON, 64, v_ettemaksud.rekvid)
    INTO ettemaks_id;

    RAISE NOTICE 'leping_id %, l_count %', ettemaks_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (ettemaks_id, v_ettemaksud.id, 'ETTEMAKSUD', json_object :: JSON, hist_object :: JSON)
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

  -- проверка на сумму проводки и кол-во записей
  /*
    SELECT
      count(id),
      sum(summa)
    INTO l_control_count, l_control_summa
    FROM cur_luba;

    SELECT
      count(j1.id),
      sum(j1.summa)
    INTO l_j_count, l_j_summa
    FROM journal j INNER JOIN journal1 j1 ON j.id = j1.parentid
    WHERE j.id = v_arv.id;
    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_journal.id % , journal_id %, l_control_summa %, l_j_summa %,, l_control_count %, l_j_count %', v_arv.id, arv_id, l_control_summa, l_j_summa, l_control_count, l_j_count;
    END IF;
    l_count = l_count + 1;
  */

  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_ettemaksud(2429)

select * from luba order by id desc limit 10

SELECT import_ettemaksud(id) from ettemaksud limit all


*/
