DROP FUNCTION IF EXISTS import_dekltasu( INTEGER );


drop FOREIGN TABLE if exists remote_dekltasu;

CREATE FOREIGN TABLE remote_dekltasu (
  id       SERIAL            NOT NULL,
  deklid   INTEGER           NOT NULL,
  tasuid   INTEGER           NOT NULL,
  tasukpv  DATE              NOT NULL,
  volgkpv  INTEGER           NOT NULL,
  summa    NUMERIC(18, 6)    NOT NULL,
  parentid INTEGER DEFAULT 0 NOT NULL)
SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'dekltasu');

SELECT rekl.sp_koosta_rekl_uhendus(64,(select row_to_json(row) from (select (select new_id from import_log where lib_name = 'TOIMING' and old_id = d.deklid) as dekl_id,
                                                                            (select new_id from import_log where lib_name = 'TOIMING' and old_id = d.tasuid) as tasu_id
                                                                    ) row)::json) as imp
from remote_dekltasu d
where deklid in (select old_id from import_log where lib_name = 'TOIMING');


/*
CREATE OR REPLACE FUNCTION import_dekltasu(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  tasu_id     INTEGER;
  log_id      INTEGER;
  v_dekltasu  RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_asutus_id INTEGER;
  l_dekl      INTEGER;
  l_tasu      INTEGER;
  v_dekl      RECORD;
  l_volg_kpv  INTEGER;
  json_params JSONB;
  l_kpv date;
BEGIN
  -- выборка из "старого меню"

  FOR v_dekltasu IN
  SELECT d.*
  FROM dekltasu d
  WHERE (d.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP
    RAISE NOTICE 'in_old_id %', in_old_id;
    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO tasu_id, log_id
    FROM import_log
    WHERE old_id = v_dekltasu.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'DEKLTASU';

    l_kpv = v_dekltasu.tasukpv;

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_dekltasu.id, tasu_id, log_id;

    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_dekltasu.parentid AND lib_name = 'ASUTUS');

    l_dekl = (SELECT new_id
              FROM import_log
              WHERE old_id = v_dekltasu.deklid AND lib_name = 'TOIMING');

    l_tasu = (SELECT new_id
              FROM import_log
              WHERE old_id = v_dekltasu.tasuid AND lib_name = 'TOIMING');


    IF l_asutus_id IS NULL OR l_dekl IS NULL
    THEN
      RAISE EXCEPTION 'asutus not found l_asutus_id %, l_dekl % ', l_asutus_id, l_dekl;
    END IF;
    -- преобразование и получение параметров

    -- salvestame tasu info

    SELECT
      id,
      parentid,
      lubaid,
      coalesce((lisa ->> 'dekltasu') :: JSONB, '[]' :: JSONB) AS dekltasu,
      tahtaeg
    INTO v_dekl
    FROM rekl.toiming
    WHERE parentid = l_dekl;

    -- kui palju paevad oli tahtajatu
    IF v_dekl.tahtaeg < l_kpv
    THEN
      l_volg_kpv = l_kpv - v_dekl.tahtaeg;
    END IF;

    -- tasu summa, dekltasu array
    SELECT row_to_json(row)
    INTO json_params
    FROM (SELECT
            l_tasu           AS tasuid,
            l_kpv            AS tasukpv,
            l_volg_kpv       AS volgkpv,
            v_dekltasu.summa AS summa) row;

    v_dekl.dekltasu = v_dekl.dekltasu || json_params;

    -- lisa
    SELECT row_to_json(row)
    INTO json_params
    FROM (SELECT v_dekl.dekltasu AS dekltasu) row;

    UPDATE rekl.toiming
    SET lisa  = coalesce(lisa, '{}' :: JSONB) || json_params,
      staatus = 'closed'
    WHERE parentid = l_dekl;


    RAISE NOTICE 'leping_id %, l_count %', tasu_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (l_dekl, v_dekltasu.id, 'DEKLTASU', json_object :: JSON, hist_object :: JSON)
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
*/

/*
SELECT import_dekltasu(10997)

select * from luba order by id desc limit 10

SELECT import_toiming(id) from toiming limit all


*/
