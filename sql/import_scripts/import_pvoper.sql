DROP FUNCTION IF EXISTS import_pvoper( INTEGER );

CREATE OR REPLACE FUNCTION import_pvoper(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  pv_oper_id    INTEGER;
  log_id        INTEGER;
  v_pv_oper     RECORD;
  json_object   JSONB;
  hist_object   JSONB;
  v_params      RECORD;
  l_count       INTEGER = 0;
  l_pv_kaart_id INTEGER;
  l_nom_id      INTEGER;
  l_asutus_id   INTEGER;
  l_dokprop_id  INTEGER;
  l_journal_id  INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_pv_oper IN
  SELECT p.*, l.rekvid, coalesce(v.kuurs,1) as kuurs
  FROM remote_pv_oper p
    INNER JOIN library l ON l.id = p.parentid
    INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
    left outer join remote_dokvaluuta1 v on v.dokid = p.id and v.dokliik = 13
  WHERE (p.id = in_old_id OR in_old_id IS NULL)
  order by p.parentid, p.id
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO pv_oper_id, log_id
    FROM import_log
    WHERE old_id = v_pv_oper.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'PVOPER';

    -- поиск pv_konto


    RAISE NOTICE 'check for lib.. v_pv_oper.id -> %, found -> % log_id -> %', v_pv_oper.id, pv_oper_id, log_id;

    -- преобразование и получение параметров
    l_pv_kaart_id = (SELECT new_id
                     FROM import_log
                     WHERE old_id = v_pv_oper.parentid AND lib_name = 'POHIVARA');

    l_nom_id = (SELECT new_id
                FROM import_log
                WHERE old_id = v_pv_oper.nomid AND lib_name = 'NOMENKLATUUR');

    l_asutus_id = (SELECT new_id
                   FROM import_log
                   WHERE old_id = v_pv_oper.asutusid AND lib_name = 'ASUTUS');

    l_dokprop_id = (SELECT new_id
                    FROM import_log
                    WHERE old_id = v_pv_oper.doklausid AND lib_name = 'DOKPROP');

    l_journal_id = CASE WHEN NOT empty(v_pv_oper.journalid)
      THEN (SELECT new_id
            FROM import_log
            WHERE old_id = v_pv_oper.journalid AND lib_name = 'JOURNAL')
                   ELSE NULL END;

    IF l_pv_kaart_id IS NULL OR l_nom_id IS NULL
    THEN
      RAISE EXCEPTION 'PV kaart or nom not found v_pv_oper.parentid %, l_pv_kaart_id %, v_pv_oper.nomid %, l_nom_id %', v_pv_oper.parentid, l_pv_kaart_id, v_pv_oper.nomid, l_nom_id;
    END IF;

    /*
  doc_liik        INTEGER = doc_data ->> 'liik';
  doc_doklausid   INTEGER = doc_data ->> 'doklausid';
  doc_summa       NUMERIC(12, 2) = doc_data ->> 'summa';
  doc_konto       TEXT = doc_data ->> 'konto';
  doc_tunnus      TEXT = doc_data ->> 'tunnus';
  doc_tp          TEXT = doc_data ->> 'tp';
  doc_proj        TEXT = doc_data ->> 'proj';
  doc_kood1       TEXT = doc_data ->> 'kood1';
  doc_kood2       TEXT = doc_data ->> 'kood2';
  doc_kood3       TEXT = doc_data ->> 'kood3';
  doc_kood4       TEXT = doc_data ->> 'kood4';
  doc_kood5       TEXT = doc_data ->> 'kood5';
     */

    -- сохранение
    SELECT
      coalesce(pv_oper_id, 0) AS id,
      l_pv_kaart_id           AS pv_kaart_id,
      l_nom_id                AS nomid,
      l_asutus_id             AS asutusid,
      l_dokprop_id            AS doklausid,
      v_pv_oper.kpv,
      v_pv_oper.muud,
      v_pv_oper.liik,
      round((v_pv_oper.summa / v_pv_oper.kuurs),2) as summa,
      v_pv_oper.konto,
      v_pv_oper.tunnus,
      v_pv_oper.tp,
      v_pv_oper.proj,
      v_pv_oper.kood1,
      v_pv_oper.kood2,
      v_pv_oper.kood3,
      v_pv_oper.kood4,
      v_pv_oper.kood5

    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(pv_oper_id, 0) AS id,
            TRUE                    AS import,
            v_params                AS data) row;

    SELECT docs.sp_salvesta_pv_oper(json_object :: JSON, 1, v_pv_oper.rekvid)
    INTO pv_oper_id;
    RAISE NOTICE 'pv_oper_id %, l_count %', pv_oper_id, l_count;

    -- lausedn

    UPDATE docs.pv_oper
    SET journalid = l_journal_id
    WHERE parentid = pv_oper_id;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (pv_oper_id, v_pv_oper.id, 'PVOPER', json_object :: JSON, hist_object :: JSON)
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
  IF (SELECT count(id)
      FROM docs.pv_oper)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count %', l_count;
  END IF;
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
SELECT import_pvoper(519806)
SELECT import_pvoper(id) from pv_oper where parentid in (select id from curPohivara where mahakantud is null or year(mahakantud) >= 2017)

*/