DROP FUNCTION IF EXISTS import_asutus( );
DROP FUNCTION IF EXISTS import_asutus(integer);

CREATE OR REPLACE FUNCTION import_asutus(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  asutus_id      INTEGER;
  log_id         INTEGER;
  v_asutus       RECORD;
  json_object    JSONB;
  hist_object    JSONB;
  v_params       RECORD;
  l_count        INTEGER = 0;
  l_tulemus      INTEGER = 0;
  is_tootaja     BOOLEAN = FALSE;
  json_asutus_aa JSONB;
BEGIN
  -- выборка из "старого меню"

  FOR v_asutus IN
  SELECT
    a.*,
    a.muud        AS kmkr,
    CASE WHEN a.rekvid > 999
      THEN a.rekvid
    ELSE NULL END AS kehtivus
  FROM asutus a
  WHERE (a.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO asutus_id, log_id
    FROM import_log
    WHERE old_id = v_asutus.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'ASUTUS';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_asutus.id, asutus_id, log_id;

    -- asutus_aa
    json_asutus_aa =   array_to_json((SELECT array_agg(row_to_json(aa.*))
                                     FROM (SELECT
                                             aa,
                                             pank
                                           FROM asutusaa
                                           WHERE parentid = v_asutus.id) AS aa
                      ))  ;

    -- проверка на работника
    IF exists(SELECT 1
              FROM tooleping
              WHERE parentid = v_asutus.id)
    THEN
      is_tootaja = TRUE;
    END IF;

    -- преобразование и получение параметров
    -- сохранение
    SELECT
      coalesce(asutus_id, 0) AS id,
      v_asutus.regkood       AS regkood,
      v_asutus.nimetus       AS nimetus,
      v_asutus.omvorm        AS omvorm,
      v_asutus.kontakt       AS kontakt,
      v_asutus.aadress       AS aadress,
      v_asutus.tel           AS tel,
      v_asutus.email         AS email,
      v_asutus.mark          AS mark,
      v_asutus.kmkr          AS kmkr,
      v_asutus.kehtivus      AS kehtivus,
      is_tootaja             AS is_tootaja,
      v_asutus.muud          AS muud,
      json_asutus_aa         AS asutus_aa
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(asutus_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT libs.sp_salvesta_asutus(json_object :: JSON, 1, 1)
    INTO asutus_id;
    RAISE NOTICE 'lib_id %, l_count %', asutus_id, l_count;
    IF empty(asutus_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (asutus_id, v_asutus.id, 'ASUTUS', json_object :: JSON, hist_object :: JSON)
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
  l_tulemus = (SELECT count(id)
               FROM libs.asutus
  );
  IF (l_tulemus + 500)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
--    RAISE EXCEPTION 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
  END IF;


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


/*
SELECT import_asutus()

*/