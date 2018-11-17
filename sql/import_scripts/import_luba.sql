drop FOREIGN TABLE if exists remote_luba;
drop FOREIGN TABLE if exists remote_luba1;

CREATE FOREIGN TABLE remote_luba (
  id       SERIAL,
  parentid INTEGER                                            NOT NULL,
  rekvid   INTEGER                                            NOT NULL,
  algkpv   DATE DEFAULT date()                                NOT NULL,
  loppkpv  DATE,
  number   VARCHAR(20)                                        NOT NULL,
  summa    NUMERIC(12, 2) DEFAULT 0                           NOT NULL,
  jaak     NUMERIC(12, 2) DEFAULT 0                           NOT NULL,
  volg     NUMERIC(12, 2) DEFAULT 0                           NOT NULL,
  alus     VARCHAR(254) DEFAULT space(1)                      NOT NULL,
  staatus  INTEGER DEFAULT 1                                  NOT NULL,
  muud     TEXT,
  kord     VARCHAR(20) DEFAULT 'KVARTAL' :: CHARACTER VARYING NOT NULL,
  intress  NUMERIC(12, 2) DEFAULT 0                           NOT NULL)
SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'luba');


CREATE FOREIGN TABLE remote_luba1 (
  id          SERIAL ,
  parentid    INTEGER                  NOT NULL,
  nomid       INTEGER                  NOT NULL,
  kogus       NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  maksumaar   NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  soodus_tyyp SMALLINT DEFAULT 0       NOT NULL,
  soodus      NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  summa       NUMERIC(12, 2) DEFAULT 0 NOT NULL,
  staatus     INTEGER DEFAULT 1        NOT NULL,
  muud        TEXT)
SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'luba1');


DROP FUNCTION IF EXISTS import_luba( INTEGER );

CREATE OR REPLACE FUNCTION import_luba(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  luba_id    INTEGER;
  log_id       INTEGER;
  v_luba     RECORD;
  json_object  JSONB;
  json_luba1   JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_asutus_id  INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_luba IN
  SELECT l.*
  FROM remote_luba l
    INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
  WHERE (l.id = in_old_id OR in_old_id IS NULL)
        and l.parentid not in (0, 30656)
  LIMIT ALL
  LOOP
  raise notice 'in_old_id %', in_old_id;
    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO luba_id, log_id
    FROM import_log
    WHERE old_id = v_luba.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'LUBA';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_luba.id, luba_id, log_id;

    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_luba.parentid AND lib_name = 'ASUTUS');

    IF l_asutus_id is null
    THEN
      RAISE EXCEPTION 'asutus v_luba.parentid %,  l_asutus_id %',  v_luba.parentid,  l_asutus_id;
    END IF;
    -- преобразование и получение параметров
    json_luba1 = array_to_json((SELECT array_agg(row_to_json(l1.*))
                                FROM (SELECT
                                        0                                                      AS id,
                                        (SELECT new_id
                                         FROM import_log
                                         WHERE old_id = l1.nomid AND lib_name = 'NOMENKLATUUR') as nomid,
                                        summa,
                                        kogus,
                                        maksumaar,
                                        soodus_tyyp,
                                        soodus,
                                        staatus,
                                        muud
                                      FROM remote_luba1 l1
                                      WHERE l1.parentid = v_luba.id) AS l1
                               ));

    -- сохранение
    SELECT
      coalesce(luba_id, 0) AS id,
      l_asutus_id as asutusid,
      v_luba.algkpv,
      v_luba.loppkpv,
      v_luba.summa,
      v_luba.jaak,
      v_luba.volg,
      v_luba.alus,
      v_luba.kord,
      v_luba.number,
      v_luba.muud,
      v_luba.staatus,
      json_luba1           AS "gridData"
    INTO v_params;



    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(luba_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT rekl.sp_salvesta_luba(json_object :: JSON, 1, v_luba.rekvid)
    INTO luba_id;
    RAISE NOTICE 'leping_id %, l_count %', luba_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (luba_id, v_luba.id, 'LUBA', json_object :: JSON, hist_object :: JSON)
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
SELECT import_luba(3044)

select * from luba order by id desc limit 10

SELECT import_luba(id) from luba limit all


*/
