DROP FUNCTION IF EXISTS import_rekv( );

CREATE OR REPLACE FUNCTION import_rekv()
  RETURNS INTEGER AS
$BODY$
DECLARE
  rekv_id     INTEGER;
  log_id      INTEGER;
  v_rekv      RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  v_aa        RECORD;
  json_aa     JSONB;
  l_aa_id     INTEGER = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_rekv IN
  SELECT *
  FROM rekv r
  WHERE r.parentid < 999 AND id > 1
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO rekv_id, log_id
    FROM import_log
    WHERE old_id = v_rekv.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'REKV';


    RAISE NOTICE 'check for lib.. v_rekv.id -> %, found -> % log_id -> %', v_rekv.id, rekv_id, log_id;

    IF rekv_id IS NULL
    THEN
      INSERT INTO ou.rekv (id, parentid, regkood, nimetus, kbmkood, aadress, haldus, tel, faks, email, juht, raama, muud)
      VALUES
        (v_rekv.id, v_rekv.parentid, v_rekv.regkood, v_rekv.nimetus, v_rekv.kbmkood, v_rekv.aadress, v_rekv.haldus,
                    v_rekv.tel, v_rekv.faks, v_rekv.email,
                    v_rekv.juht, v_rekv.raama, v_rekv.muud)
      RETURNING id
        INTO rekv_id;
    END IF;

    -- преобразование и получение параметров

    -- aa data

    FOR v_aa IN
    SELECT
      0 as id,
      parentid,
      arve,
      nimetus,
      default_,
      kassa,
      pank,
      konto,
      muud,
      tp
    FROM aa
    WHERE parentid = v_rekv.id
    LOOP

      RAISE NOTICE 'rekv -> %', v_rekv.id;

      delete from ou.aa where parentid = v_rekv.id;

      json_aa = coalesce(JSON_aa, '{}' :: JSONB) :: JSONB || row_to_json(v_aa) :: JSONB;
      RAISE NOTICE 'rekv, json_aa -> %', json_aa;
    END LOOP;

    /*
      doc_parentid INTEGER = doc_data ->> 'parentid';
  doc_regkood  TEXT = doc_data ->> 'regkood';
  doc_nimetus  TEXT = doc_data ->> 'nimetus';
  doc_kbmkood  TEXT = doc_data ->> 'kbmkood';
  doc_aadress  TEXT = doc_data ->> 'aadress';
  doc_haldus   TEXT = doc_data ->> 'haldus';
  doc_tel      TEXT = doc_data ->> 'tel';
  doc_faks     TEXT = doc_data ->> 'faks';
  doc_email    TEXT = doc_data ->> 'email';
  doc_juht     TEXT = doc_data ->> 'juht';
  doc_raama    TEXT = doc_data ->> 'raama';
  doc_muud     TEXT = doc_data ->> 'muud';
  doc_details  JSON = doc_data ->> 'gridData';

     */

    -- сохранение
    SELECT
      coalesce(rekv_id, 0) AS id,
      v_rekv.regkood       AS regkood,
      v_rekv.nimetus       AS nimetus,
      v_rekv.kbmkood       AS kbmkood,
      v_rekv.aadress       AS aadress,
      v_rekv.haldus        AS haldus,
      v_rekv.tel           AS tel,
      v_rekv.faks          AS faks,
      v_rekv.email         AS email,
      v_rekv.juht          AS juht,
      v_rekv.raama         AS raama,
      v_rekv.muud          AS muud
    INTO v_params;

    RAISE NOTICE 'salvestame, params';
    json_object = ('{"data":' || trim(TRAILING FROM (row_to_json(v_params)) :: TEXT, '}') :: TEXT ||
                   ',"gridData":[' || json_aa :: TEXT || ']}}');

    RAISE NOTICE 'salvestame, params %', json_object;


    SELECT ou.sp_salvesta_REKV(json_object :: JSON, 1, 1)
    INTO rekv_id;
    RAISE NOTICE 'lib_id %, l_count %, json_object %', rekv_id, l_count, json_object;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (rekv_id, v_rekv.id, 'REKV', json_object :: JSON, hist_object :: JSON)
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
  IF (SELECT count(id)
      FROM ou.rekv)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count %', l_count;
  END IF;


  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

SELECT import_rekv()

/*
SELECT import_rekv()

*/