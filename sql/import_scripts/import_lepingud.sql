DROP FOREIGN TABLE IF EXISTS remote_leping1;
/*
CREATE FOREIGN TABLE remote_leping1 (
  id        SERIAL                               NOT NULL,
  asutusid  INTEGER DEFAULT 1                    NOT NULL,
  rekvid    INTEGER                              NOT NULL,
  doklausid INTEGER DEFAULT 1                    NOT NULL,
  number    CHAR(20) DEFAULT space(1)            NOT NULL,
  kpv       DATE DEFAULT ('now' :: TEXT) :: DATE NOT NULL,
  tahtaeg   DATE,
  selgitus  TEXT DEFAULT space(1)                NOT NULL,
  dok       TEXT,
  muud      TEXT,
  pakettid  INTEGER DEFAULT 0                    NOT NULL,
  objektid  INTEGER DEFAULT 0
)
SERVER db_narva_ee
OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'leping1'
);

DROP FOREIGN TABLE IF EXISTS remote_leping2;

CREATE FOREIGN TABLE remote_leping2 (
  id         SERIAL                   NOT NULL,
  parentid   INTEGER                  NOT NULL,
  nomid      INTEGER DEFAULT 0        NOT NULL,
  kogus      NUMERIC(12, 3) DEFAULT 0 NOT NULL,
  hind       NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  soodus     SMALLINT DEFAULT 0       NOT NULL,
  soodusalg  DATE,
  sooduslopp DATE,
  summa      NUMERIC(12, 4) DEFAULT 0 NOT NULL,
  status     SMALLINT DEFAULT 1       NOT NULL,
  muud       TEXT,
  formula    TEXT DEFAULT space(1)    NOT NULL,
  kbm        INTEGER
)
SERVER db_narva_ee
OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'leping2'
);
*/

DROP FUNCTION IF EXISTS import_lepingud( INTEGER );

CREATE OR REPLACE FUNCTION import_lepingud(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  leping_id    INTEGER;
  log_id       INTEGER;
  v_leping     RECORD;
  v_leping1    RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  json_leping1 JSONB;
  l_asutus_id  INTEGER;
  l_objekt_id  INTEGER;
  l_aktsept_id INTEGER;
  l_eelarve_id INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_leping IN
  SELECT l1.*
  FROM leping1 l1
  WHERE (l1.id = in_old_id OR in_old_id IS NULL)
        AND l1.tahtaeg IS NULL OR year(l1.tahtaeg) >= 2020
  LIMIT ALL
  LOOP
    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO leping_id, log_id
    FROM import_log
    WHERE old_id = v_leping.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'LEPING';

    -- преобразование и получение параметров
    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_leping.asutusid AND lib_name = 'ASUTUS');
    --objektid

    IF l_asutus_id IS NULL
    THEN
      RAISE EXCEPTION 'Asutus not found %', v_leping.asutusid;
    END IF;

    IF v_leping.objektid IS NULL OR empty(v_leping.objektid)
    THEN
      l_objekt_id = NULL;
    ELSE
      l_objekt_id = (SELECT new_id
                     FROM import_log
                     WHERE old_id = v_leping.objektid AND lib_name = 'OBJEKT');

    END IF;

    json_leping1 = array_to_json((SELECT array_agg(row_to_json(l2.*))
                                  FROM (SELECT
                                          0                                                       AS id,
                                          (SELECT new_id
                                           FROM import_log
                                           WHERE old_id = l2.nomid AND lib_name = 'NOMENKLATUUR') AS nomid,
                                          summa,
                                          kogus,
                                          hind,
                                          soodus,
                                          status,
                                          kbm,
                                          muud
                                        FROM leping2 l2
                                        WHERE l2.parentid = v_leping.id) AS l2
                                 ));

    -- сохранение
    /*
      doc_number    TEXT = doc_data ->> 'number';
      doc_asutusid  INTEGER = doc_data ->> 'asutusid';
      doc_selgitus  TEXT = doc_data ->> 'selgitus';
      doc_kpv       DATE = doc_data ->> 'kpv';
      doc_tahtaeg   DATE = doc_data ->> 'tahtaeg';
      doc_muud      TEXT = doc_data ->> 'muud';
      doc_objektid  INTEGER = doc_data ->> 'objektid';
      doc_pakettid  INTEGER = doc_data ->> 'pakettid';
      doc_doklausid INTEGER = doc_data ->> 'doklausid';

     */

    SELECT
      coalesce(leping_id, 0) AS id,
      v_leping.kpv           AS kpv,
      l_asutus_id            AS asutusid,
      v_leping.number        AS number,
      v_leping.selgitus      AS selgitus,
      v_leping.tahtaeg       AS tahtaeg,
      l_objekt_id            AS objektid,
      v_leping.muud          AS muud,
      v_leping.doklausid     AS doklausid,
      json_leping1           AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(leping_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT docs.sp_salvesta_leping(json_object :: JSON, 1, v_leping.rekvid)
    INTO leping_id;
    RAISE NOTICE 'leping_id %, l_count %, json_object %', leping_id, l_count, json_object;
    IF empty(leping_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
    --      RAISE NOTICE 'saved %', taotlus_id;
    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (leping_id, v_leping.id, 'LEPING', json_object :: JSON, hist_object :: JSON)
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
  /*
    l_tulemus = (SELECT count(id)
                 FROM eelarve.taotlus);
    IF (l_tulemus + 100)
       >= l_count
    THEN
      RAISE NOTICE 'Import ->ok';
    ELSE
      RAISE EXCEPTION 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
      --    RAISE notice 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
    END IF;
  */

  IF l_count = 0
  THEN
    RAISE EXCEPTION 'LEPINGUD not imported %', in_old_id;
  END IF;

  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % % leping.id %', SQLERRM, SQLSTATE, v_leping.id;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;



/*
SELECT import_lepingud(id) from leping1 where

*/