DROP FUNCTION IF EXISTS import_palk_oper( INTEGER );

CREATE OR REPLACE FUNCTION import_palk_oper(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  palk_oper_id INTEGER;
  log_id       INTEGER;
  v_palk_oper  RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_leping_id  INTEGER;
  l_lib_id     INTEGER;
  l_asutus_id  INTEGER;
  l_dokprop_id INTEGER;
  l_journal_id INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_palk_oper IN
  SELECT
    p.*,
    t.rekvid,
    pl.tululiik
  FROM palk_oper p
    INNER JOIN tooleping t ON t.id = p.lepingid
    INNER JOIN rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
    INNER JOIN palk_lib pl ON pl.parentid = p.libid
  WHERE (p.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO palk_oper_id, log_id
    FROM import_log
    WHERE old_id = v_palk_oper.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'PALK_OPER';

    -- поиск pv_konto


    RAISE NOTICE 'check for lib.. v_palk_oper.id -> %, found -> % log_id -> %', v_palk_oper.id, palk_oper_id, log_id;

    -- преобразование и получение параметров
    l_leping_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_palk_oper.lepingid AND lib_name = 'TOOLEPING');

    l_lib_id = (SELECT new_id
                FROM import_log
                WHERE old_id = v_palk_oper.libid AND lib_name = 'PALK');

    l_dokprop_id = (SELECT new_id
                    FROM import_log
                    WHERE old_id = v_palk_oper.doklausid AND lib_name = 'DOKPROP');

    l_journal_id = CASE WHEN NOT empty(v_palk_oper.journalid)
      THEN (SELECT new_id
            FROM import_log
            WHERE old_id = v_palk_oper.journalid AND lib_name = 'JOURNAL')
                   ELSE NULL END;

    IF l_leping_id IS NULL OR l_lib_id IS NULL
    THEN
      RAISE EXCEPTION 'leping or lib not found v_palk_oper.lepingid %, l_leping_id %, v_palk_oper.libid %, l_lib_id %', v_palk_oper.lepingid, l_leping_id, v_palk_oper.libid, l_lib_id;
    END IF;

    /*
  doc_libid     INTEGER = doc_data ->> 'libid';
  doc_lepingid  INTEGER = doc_data ->> 'lepingid';
  doc_kpv       DATE = doc_data ->> 'kpv';
  doc_summa     NUMERIC = doc_data ->> 'summa';
  doc_dokpropid INTEGER = doc_data ->> 'dokpropid';
  doc_kood1     TEXT = doc_data ->> 'kood1';
  doc_kood2     TEXT = doc_data ->> 'kood2';
  doc_kood3     TEXT = doc_data ->> 'kood3';
  doc_kood4     TEXT = doc_data ->> 'kood4';
  doc_kood5     TEXT = doc_data ->> 'kood5';
  doc_konto     TEXT = doc_data ->> 'konto';
  doc_tp        TEXT = doc_data ->> 'tp';
  doc_tunnus    TEXT = doc_data ->> 'tunnus';
  doc_proj      TEXT = doc_data ->> 'proj';
  doc_tulumaks  NUMERIC = doc_data ->> 'tulumaks';
  doc_sotsmaks  NUMERIC = doc_data ->> 'sotsmaks';
  doc_tootumaks NUMERIC = doc_data ->> 'tootumaks';
  doc_pensmaks  NUMERIC = doc_data ->> 'pensmaks';
  doc_tulubaas  NUMERIC = doc_data ->> 'tulubaas';
  doc_tka       NUMERIC = doc_data ->> 'tka';
  doc_period    DATE = doc_data ->> 'period';
  doc_pohjus    TEXT = doc_data ->> 'pohjus';
  doc_tululiik  TEXT = doc_data ->> 'tululiik';
  doc_muud      TEXT = doc_data ->> 'muud';
     */

    -- сохранение
    SELECT
      coalesce(palk_oper_id, 0) AS id,
      l_leping_id               AS lepingid,
      l_lib_id                  AS libid,
      l_dokprop_id              AS doklausid,
      v_palk_oper.kpv,
      v_palk_oper.muud,
      v_palk_oper.summa,
      v_palk_oper.konto,
      v_palk_oper.tunnus,
      v_palk_oper.tp,
      v_palk_oper.proj,
      v_palk_oper.kood1,
      v_palk_oper.kood2,
      v_palk_oper.kood3,
      v_palk_oper.kood4,
      v_palk_oper.kood5,
      v_palk_oper.tulumaks,
      v_palk_oper.sotsmaks,
      v_palk_oper.tootumaks,
      v_palk_oper.pensmaks,
      v_palk_oper.tulubaas,
      v_palk_oper.tka,
      v_palk_oper.period,
      v_palk_oper.pohjus,
      v_palk_oper.tululiik,
      v_palk_oper.muud

    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(palk_oper_id, 0) AS id,
            TRUE                      AS import,
            v_params                  AS data) row;

    SELECT palk.sp_salvesta_palk_oper(json_object :: JSON, 1, v_palk_oper.rekvid)
    INTO palk_oper_id;
    RAISE NOTICE 'palk_oper_id %, l_count %', palk_oper_id, l_count;

    -- lausedn

    UPDATE palk.palk_oper
    SET journalid = l_journal_id
    WHERE parentid = palk_oper_id;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (palk_oper_id, v_palk_oper.id, 'PALK_OPER', json_object :: JSON, hist_object :: JSON)
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
SELECT import_palk_oper(4418534)
SELECT import_palk_oper(id) from palk_oper
where lepingid in (select old_id from import_log where lib_name = 'TOOLEPING')
and year(kpv) >= 2016

*/

