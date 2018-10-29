CREATE FOREIGN TABLE remote_objekt (
  id serial NOT NULL,
  libid integer NOT NULL,
  asutusid integer NOT NULL,
  parentid integer NOT NULL,
  nait01 numeric(14,4) NOT NULL DEFAULT 0,
  nait02 numeric(14,4) NOT NULL DEFAULT 0,
  nait03 numeric(14,4) NOT NULL DEFAULT 0,
  nait04 numeric(14,4) NOT NULL DEFAULT 0,
  nait05 numeric(14,4) NOT NULL DEFAULT 0,
  nait06 numeric(14,4) NOT NULL DEFAULT 0,
  nait07 numeric(14,4) NOT NULL DEFAULT 0,
  nait08 numeric(14,4) NOT NULL DEFAULT 0,
  nait09 numeric(14,4) NOT NULL DEFAULT 0,
  nait10 numeric(14,4) NOT NULL DEFAULT 0,
  nait11 numeric(14,4) NOT NULL DEFAULT 0,
  nait12 numeric(14,4) NOT NULL DEFAULT 0,
  nait13 numeric(14,4) NOT NULL DEFAULT 0,
  nait14 numeric(14,4) NOT NULL DEFAULT 0,
  nait15 numeric(14,4) NOT NULL DEFAULT 0,
  muud text
)
SERVER db_narva_ee
OPTIONS (schema_name 'public', table_name 'objekt');


DROP FUNCTION IF EXISTS import_taotlus( INTEGER );

CREATE OR REPLACE FUNCTION import_taotlus(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  taotlus_id    INTEGER;
  log_id        INTEGER;
  v_taotlus     RECORD;
  v_taotlus1     RECORD;
  json_object   JSONB;
  hist_object   JSONB;
  v_params      RECORD;
  l_count       INTEGER = 0;
  json_taotlus1 JSONB;
  l_koostaja_id INTEGER;
  l_ametnik_id  INTEGER;
  l_aktsept_id  INTEGER;
  l_eelarve_id  INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_taotlus IN
  SELECT t.*
  FROM taotlus t
    INNER JOIN rekv ON t.rekvid = rekv.id AND rekv.parentid < 999
  WHERE (t.id = in_old_id OR in_old_id IS NULL)
  ORDER BY t.kpv
  LIMIT ALL
  LOOP

    --    RAISE NOTICE 'v_taotlus.id %', v_taotlus.id;

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO taotlus_id, log_id
    FROM import_log
    WHERE old_id = v_taotlus.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TAOTLUS';

    --   RAISE NOTICE 'check for lib.. v_taotlus.id -> %, found -> % log_id -> %', v_taotlus.id, taotlus_id, log_id;

    -- преобразование и получение параметров


    IF v_taotlus.staatus = 3
    THEN
      -- проверяем правильность данных
      IF exists(SELECT id
                FROM taotlus1
                WHERE parentid = v_taotlus.id AND eelarveid = 0)
      THEN
        raise notice 'leindsin vigased kirjad, parandame';
        -- правим ссылку
        FOR v_taotlus1 IN
        SELECT
          t1.id,
          t1.eelarveid
        FROM remote_taotlus1 t1
        WHERE parentid = v_taotlus.id
        LOOP
          raise notice 'v_taotlus1.eelarveid %, v_taotlus1.id %', v_taotlus1.eelarveid, v_taotlus1.id;
          UPDATE taotlus1
          SET eelarveid = v_taotlus1.eelarveid
          WHERE id = v_taotlus1.id;
        END LOOP;
      END IF;
    END IF;
    json_taotlus1 = array_to_json((SELECT array_agg(row_to_json(t1.*))
                                   FROM (SELECT
                                           0                                                      AS id,
                                           (SELECT new_id
                                            FROM import_log
                                            WHERE old_id = t1.eelarveid AND lib_name = 'EELARVE') AS eelarveid,
                                           (SELECT new_id
                                            FROM import_log
                                            WHERE old_id = t1.eelprojid AND lib_name = 'EELPROJ') AS eelprojid,
                                           summa,
                                           kood1,
                                           kood2,
                                           kood3,
                                           kood4,
                                           kood5,
                                           selg,
                                           markused,
                                           tunnus,
                                           muud
                                         FROM taotlus1 t1
                                         WHERE t1.parentid = v_taotlus.id) AS t1
                                  ));

    --    RAISE NOTICE 'json_arv1 %', json_taotlus1;
    l_koostaja_id = (SELECT new_id
                     FROM import_log
                     WHERE old_id = v_taotlus.koostajaid AND lib_name = 'USERID');
    l_ametnik_id = (SELECT new_id
                    FROM import_log
                    WHERE old_id = v_taotlus.ametnikid AND lib_name = 'USERID');
    l_aktsept_id = (SELECT new_id
                    FROM import_log
                    WHERE old_id = v_taotlus.aktseptid AND lib_name = 'USERID');

    -- сохранение


    SELECT
      coalesce(taotlus_id, 0) AS id,
      l_koostaja_id           AS koostajaid,
      l_ametnik_id            AS ametnikid,
      l_aktsept_id            AS aktseptid,
      v_taotlus.kpv           AS kpv,
      v_taotlus.aasta         AS aasta,
      v_taotlus.kuu           AS kuu,
      v_taotlus.allkiri       AS allkiri,
      v_taotlus.tunnus        AS tunnus,
      v_taotlus.number        AS number,
      v_taotlus.muud          AS muud,
      v_taotlus.staatus       AS status,
      json_taotlus1           AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(taotlus_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT eelarve.sp_salvesta_taotlus(json_object :: JSON, 1, v_taotlus.rekvid)
    INTO taotlus_id;
    RAISE NOTICE 'taotlus_id %, l_count %, json_object %', taotlus_id, l_count, json_object;
    IF empty(taotlus_id)
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
      VALUES (taotlus_id, v_taotlus.id, 'TAOTLUS', json_object :: JSON, hist_object :: JSON)
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
    RAISE EXCEPTION 'taotlused not imported %', in_old_id;
  END IF;

  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % % taotlus.id %', SQLERRM, SQLSTATE, v_taotlus.id;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_taotlus(11305)
-- import_taotlus(id)
SELECT count(id) from taotlus where year(kpv) = 2018
and staatus = 3
and id in (select parentid from taotlus1 where eelarveid = 0)

order by kpv limit all

*/