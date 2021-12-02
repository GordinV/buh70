/*
DROP FUNCTION IF EXISTS import_eelarve( INTEGER );

CREATE FOREIGN TABLE if not EXISTS  remote_eelarve (
  id SERIAL NOT NULL,
  rekvid    INTEGER                          NOT NULL,
  allikasid INTEGER        DEFAULT 0         NOT NULL,
  aasta     INTEGER        DEFAULT year()    NOT NULL,
  summa     NUMERIC(14, 2) DEFAULT 0         NOT NULL,
  muud      TEXT,
  tunnus    INTEGER        DEFAULT 0         NOT NULL,
  tunnusid  INTEGER        DEFAULT 0         NOT NULL,
  kood1     VARCHAR(20)    DEFAULT space(20) NOT NULL,
  kood2     VARCHAR(20)    DEFAULT space(20) NOT NULL,
  kood3     VARCHAR(20)    DEFAULT space(20) NOT NULL,
  kood4     VARCHAR(20)    DEFAULT space(20) NOT NULL,
  kood5     VARCHAR(20)    DEFAULT space(20) NOT NULL,
  kpv       DATE           DEFAULT date(2005, 1, 1),
  kuu       SMALLINT       DEFAULT 0,
  variantid INTEGER        DEFAULT 0
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'eelarve');


 */

CREATE OR REPLACE FUNCTION import_eelarve(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  eelarve_id        INTEGER;
  l_log_id          INTEGER;
  v_eelarve         RECORD;
  json_object       JSONB;
  hist_object       JSONB;
  v_params          RECORD;
  l_count           INTEGER = 0;
  l_proj_id         INTEGER;
  l_tunnus          TEXT;
  is_kulud          INTEGER = 1;
  vigane_eelarve_id INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_eelarve IN
  SELECT e.*
  FROM eelarve e
  WHERE (e.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO eelarve_id, l_log_id
    FROM import_log
    WHERE old_id = v_eelarve.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'EELARVE';


    RAISE NOTICE 'check for lib.. v_EELARVE.id -> %, found -> % log_id -> %', v_eelarve.id, eelarve_id, l_log_id;

    -- преобразование и получение параметров

    -- variant
    IF NOT empty(v_eelarve.variantid)
    THEN
      l_proj_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_eelarve.variantid AND lib_name = 'EELPROJ');
      IF l_proj_id IS NULL
      THEN
        RAISE EXCEPTION 'Eel. Projekt not found v_eelarve.variantid %, l_proj_id %', v_eelarve.variantid, l_proj_id;
      END IF;
    ELSE
      l_proj_id = NULL;
    END IF;

    RAISE NOTICE 'v_eelarve.variantid %, l_proj_id %', v_eelarve.variantid, l_proj_id;

    IF v_eelarve.tunnusid IS NOT NULL AND NOT empty(v_eelarve.tunnusid)
    THEN
      l_tunnus = (SELECT kood
                  FROM library
                  WHERE id = v_eelarve.tunnusid AND library = 'TUNNUS');
    ELSE
      l_tunnus = '';
    END IF;

    is_kulud = (SELECT CASE WHEN tun5 = 1
      THEN 0
                       ELSE 1 END
                FROM libs.library
                WHERE library = 'TULUDEALLIKAD' AND kood = v_eelarve.kood5);

    -- проверка на соответствие признака дохода и расхода
    IF is_kulud <> (SELECT e.is_kulud
                    FROM eelarve.eelarve e
                    WHERE e.id = eelarve_id)
    THEN
      -- удаление бюджетной записи
      DELETE FROM eelarve.eelarve
      WHERE id = eelarve_id;
      -- создание новой
      vigane_eelarve_id = eelarve_id;
      eelarve_id = 0;
      -- правка истории импорта
    END IF;

    -- сохранение
    SELECT
      coalesce(eelarve_id, 0) AS id,
      v_eelarve.rekvid        AS rekvid,
      v_eelarve.aasta         AS aasta,
      v_eelarve.summa         AS summa,
      v_eelarve.summa         AS summa_kassa,
      is_kulud                AS is_kulud,
      CASE WHEN empty(v_eelarve.kpv)
        THEN 0
      ELSE 1 END              AS is_parandus,
      l_tunnus                AS tunnus,
      v_eelarve.kood1,
      v_eelarve.kood2,
      v_eelarve.kood3,
      v_eelarve.kood4,
      v_eelarve.kood5,
      v_eelarve.kpv,
      l_proj_id               AS variantid,
      v_eelarve.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(eelarve_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT eelarve.sp_salvesta_eelarve(json_object :: JSON, 1, v_eelarve.rekvid)
    INTO eelarve_id;

    RAISE NOTICE 'import eelarve eelarve_id %, l_count %', eelarve_id, l_count;

    -- проверим на правку бюджета
    IF vigane_eelarve_id IS NOT NULL
    THEN
      -- правка
      RAISE NOTICE 'parandus vigane_eelarve_id %', vigane_eelarve_id;
      -- меняем запись в логе
      UPDATE import_log
      SET new_id = eelarve_id
      WHERE id = l_log_id AND new_id = vigane_eelarve_id;
      --меняем ссылки
      UPDATE eelarve.taotlus1
      SET eelarveid = eelarve_id
      WHERE eelarveid = vigane_eelarve_id;
    END IF;


    IF empty(eelarve_id)
    THEN
      RAISE EXCEPTION 'eelarve not saved json_object %', json_object;
    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF l_log_id IS NULL OR empty(l_log_id)
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (eelarve_id, v_eelarve.id, 'EELARVE', json_object :: JSON, hist_object :: JSON)
      RETURNING id
        INTO l_log_id;

    ELSE
      UPDATE import_log
      SET
        params  = json_object :: JSON,
        history = (history :: JSONB || hist_object :: JSONB) :: JSON
      WHERE id = l_log_id;
    END IF;

    IF empty(l_log_id)
    THEN
      RAISE EXCEPTION 'log save failed';
    END IF;
    l_count = l_count + 1;
  END LOOP;


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*

--SELECT import_eelarve(113637)

delete from eelarve.eelarve where id =

SELECT import_eelarve(e.id)
from remote_eelarve e
where rekvid in (28)
and aasta >= 2019

SELECT count(e.id)
from remote_eelarve e
where rekvid in (130, 64)
and aasta = 2019

*/