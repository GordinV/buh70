DROP FUNCTION IF EXISTS import_eelarve( INTEGER );

CREATE OR REPLACE FUNCTION import_eelarve(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  eelarve_id  INTEGER;
  log_id      INTEGER;
  v_eelarve   RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_proj_id   INTEGER;
  l_tunnus    TEXT;
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
    INTO eelarve_id, log_id
    FROM import_log
    WHERE old_id = v_eelarve.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'EELARVE';


    RAISE NOTICE 'check for lib.. v_EELARVE.id -> %, found -> % log_id -> %', v_eelarve.id, eelarve_id, log_id;

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

    IF NOT empty(v_eelarve.tunnusid)
    THEN
      l_tunnus = (SELECT kood
                  FROM library
                  WHERE id = v_eelarve.tunnusid);
    END IF;
    /*
      doc_aasta       INTEGER = doc_data ->> 'aasta';
      doc_summa       NUMERIC(12, 2) = doc_data ->> 'summa';
      doc_tunnus      TEXT = doc_data ->> 'tunnus';
      doc_kood1       TEXT = doc_data ->> 'kood1';
      doc_kood2       TEXT = doc_data ->> 'kood2';
      doc_kood3       TEXT = doc_data ->> 'kood3';
      doc_kood4       TEXT = doc_data ->> 'kood4';
      doc_kood5       TEXT = doc_data ->> 'kood5';
      doc_is_kulud    INTEGER = doc_data ->> 'is_kulud';
      doc_is_parandus INTEGER = coalesce((doc_data ->> 'is_parandus')::integer,0);
      doc_variantid   INTEGER = doc_data ->> 'variantid';
      doc_kpv         DATE = doc_data ->> 'kpv';
      doc_muud        TEXT = doc_data ->> 'muud';

     */
    -- сохранение
    SELECT
      coalesce(eelarve_id, 0) AS id,
      v_eelarve.rekvid        AS rekvid,
      v_eelarve.aasta         AS aasta,
      v_eelarve.summa         AS summa,
      v_eelarve.tunnus        AS is_kulud,
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

    IF empty(eelarve_id)
    THEN
      RAISE EXCEPTION 'eelarve not saved json_object %', json_object;
    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL OR empty(log_id)
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (eelarve_id, v_eelarve.id, 'EELARVE', json_object :: JSON, hist_object :: JSON)
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


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_eelarve(61105)
SELECT import_eelarve(e.id)
from eelarve e inner join rekv r on e.rekvid = r.id and r.parentid < 999
and e.variantid > 0
*/