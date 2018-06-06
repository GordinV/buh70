DROP FUNCTION IF EXISTS import_dokprop( );

CREATE OR REPLACE FUNCTION import_dokprop(in_old_id INTEGER, in_dok text = 'VMK')
  RETURNS INTEGER AS
$BODY$
DECLARE
  lib_id      INTEGER;
  log_id      INTEGER;
  v_lib       RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_asutus_id INTEGER;
  l_lib_id    INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_lib IN
  SELECT
    d.*,
    l.kood AS dok,
    l.rekvid
  FROM dokprop d
    INNER JOIN library l ON l.id = d.parentid
  WHERE (d.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO lib_id, log_id
    FROM import_log
    WHERE old_id = v_lib.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'DOKPROP';


    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_lib.id, lib_id, log_id;

    -- преобразование и получение параметров
    /*
      doc_kood1     TEXT = doc_data ->> 'kood1';
      doc_kood2     TEXT = doc_data ->> 'kood2';
      doc_kood3     TEXT = doc_data ->> 'kood3';
      doc_kood5     TEXT = doc_data ->> 'kood5';
      doc_proc_     TEXT = doc_data ->> 'proc_';
      doc_type      INTEGER = doc_data ->> 'type';
      doc_parentid  INTEGER = doc_data ->> 'parentid';

     */
    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_lib.asutusid AND lib_name = 'ASUTUS');
    IF NOT empty(v_lib.asutusid) AND l_asutus_id IS NULL
    THEN
      RAISE EXCEPTION 'asutus not found v_lib.asutusid %, l_asutus_id %', v_lib.asutusid, l_asutus_id;
    END IF;

    l_lib_id = (SELECT ID
                FROM libs.library
                WHERE kood = ltrim(rtrim(v_lib.dok)) AND library = 'DOK');

    IF l_lib_id IS NULL
    THEN
      RAISE EXCEPTION 'dok. type not found v_lib.dok %, l_lib_id %', v_lib.dok, l_lib_id;
    END IF;

    -- сохранение
    SELECT
      coalesce(lib_id, 0) AS id,
      v_lib.dok           AS dok,
      v_lib.selg          AS selg,
      v_lib.registr       AS registr,
      v_lib.vaatalaus     AS vaatalaus,
      v_lib.konto         AS konto,
      v_lib.kbmkonto      AS kbmkonto,
      l_asutus_id         AS asutusid,
      v_lib.kood1         AS kood1,
      v_lib.kood2         AS kood2,
      v_lib.kood3         AS kood3,
      v_lib.kood4         AS kood4,
      v_lib.kood5         AS kood5,
      v_lib.proc_         AS propc_,
      v_lib.tyyp          AS type,
      v_lib.rekvid        AS rekvid,
      l_lib_id            AS parentid,
      v_lib.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(lib_id, 0) AS id,
            TRUE                AS import,
            v_params            AS data) row;

    SELECT libs.sp_salvesta_dokprop(json_object :: JSON, 1, v_lib.rekvid)
    INTO lib_id;
    RAISE NOTICE 'import dokprop lib_id %, l_count %', lib_id, l_count;

    if empty(lib_id) THEN
      raise EXCEPTION 'Dokprop not saved json_object %', json_object;
    END IF;


    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL or empty(log_id)
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (lib_id, v_lib.id, 'DOKPROP', json_object :: JSON, hist_object :: JSON)
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
SELECT import_dokprop(1876)

*/