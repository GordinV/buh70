drop FOREIGN TABLE if exists remote_toiming;

CREATE FOREIGN TABLE remote_toiming (
  id           SERIAL ,
  parentid     INTEGER                       NOT NULL,
  lubaid       INTEGER DEFAULT 0             NOT NULL,
  journalid    INTEGER DEFAULT 0             NOT NULL,
  kpv          DATE DEFAULT date()           NOT NULL,
  userid       INTEGER DEFAULT 0             NOT NULL,
  alus         VARCHAR(254) DEFAULT space(1) NOT NULL,
  ettekirjutus VARCHAR(254) DEFAULT space(1) NOT NULL,
  tahtaeg      DATE DEFAULT date()           NOT NULL,
  summa        NUMERIC(12, 2) DEFAULT 0      NOT NULL,
  staatus      INTEGER DEFAULT 1             NOT NULL,
  tyyp         VARCHAR(20) DEFAULT 0         NOT NULL,
  muud         TEXT,
  failid       INTEGER DEFAULT 0             NOT NULL,
  dokpropid    INTEGER DEFAULT 0             NOT NULL,
  saadetud     DATE,
  number       INTEGER DEFAULT 0,
  deklid       INTEGER)
SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'toiming');

DROP FUNCTION IF EXISTS import_toiming( INTEGER );



DROP FUNCTION IF EXISTS import_toiming( INTEGER );


CREATE OR REPLACE FUNCTION import_toiming(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  toiming_id  INTEGER;
  log_id      INTEGER;
  v_toiming   RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_asutus_id INTEGER;
  l_luba_id   INTEGER;
  l_status    DOK_STATUS;
  l_journal   INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_toiming IN
  SELECT t.*
  FROM remote_toiming t
  WHERE (t.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP
    RAISE NOTICE 'in_old_id %', in_old_id;
    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO toiming_id, log_id
    FROM import_log
    WHERE old_id = v_toiming.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TOIMING';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_toiming.id, toiming_id, log_id;

    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_toiming.parentid AND lib_name = 'ASUTUS');

    l_luba_id = (SELECT new_id
                 FROM import_log
                 WHERE old_id = v_toiming.lubaid AND lib_name = 'LUBA');

    l_journal = (SELECT new_id
                 FROM import_log
                 WHERE old_id = v_toiming.journalid AND lib_name = 'JOURNAL');



    IF l_asutus_id IS NULL OR l_luba_id IS NULL
    THEN
      RAISE EXCEPTION 'luba or asutus not found l_asutus_id %, l_luba_id %, ', l_asutus_id, l_luba_id;
    END IF;
    -- преобразование и получение параметров


    CASE WHEN v_toiming.staatus = 1
      THEN
        l_status = 'closed';
      WHEN v_toiming.staatus = 2 OR v_toiming.staatus = 3
      THEN
        l_status = 'closed';
    END CASE;

    -- сохранение
    SELECT
      coalesce(toiming_id, 0)                                       AS id,
      l_asutus_id                                                   AS asutusid,
      l_luba_id                                                     AS lubaid,
      v_toiming.number,
      v_toiming.kpv,
      v_toiming.summa,
      v_toiming.alus,
      v_toiming.ettekirjutus,
      v_toiming.tahtaeg,
      v_toiming.tyyp,
      v_toiming.saadetud,
      v_toiming.tahtaeg,
      v_toiming.tahtaeg,
      v_toiming.muud,
      l_status                                                      AS staatus,
      (SELECT new_id
       FROM import_log
       WHERE old_id = v_toiming.dokpropid AND lib_name = 'DOKPROP') AS dokpropid
    INTO v_params;


    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(toiming_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT rekl.sp_salvesta_toiming(json_object :: JSON, 1, 28)
    INTO toiming_id;
    RAISE NOTICE 'leping_id %, l_count %', toiming_id, l_count;

    -- saadetud info
    RAISE NOTICE 'status-> %', l_status;
    UPDATE rekl.toiming
    SET saadetud = v_toiming.saadetud,  journalid = l_journal
    WHERE parentid = toiming_id;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (toiming_id, v_toiming.id, 'TOIMING', json_object :: JSON, hist_object :: JSON)
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

  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_TOIMING(25079)

select * from luba order by id desc limit 10

SELECT import_toiming(id) from toiming limit all


*/
