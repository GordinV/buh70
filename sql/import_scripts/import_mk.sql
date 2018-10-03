DROP FUNCTION IF EXISTS import_mk( INTEGER );

CREATE OR REPLACE FUNCTION import_mk(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  mk_id           INTEGER;
  log_id          INTEGER;
  v_mk            RECORD;
  v_mk1           RECORD;
  json_object     JSONB;
  hist_object     JSONB;
  v_params        RECORD;
  l_count         INTEGER = 0;
  l_tulemus       INTEGER = 0;
  json_mk1        JSONB;
  l_asutus        INTEGER;
  l_control_summa NUMERIC;
  l_control_count INTEGER;
  l_j_summa       NUMERIC;
  l_j_count       INTEGER;
  l_journal_id    INTEGER;
  l_nom_id        INTEGER;
  l_pank_id       INTEGER;
  l_arv_id        INTEGER;
  l_dokprop_id    INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_mk IN
  SELECT m.*
  FROM mk m
    INNER JOIN rekv ON m.rekvid = rekv.id AND rekv.parentid < 999
  WHERE (m.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    RAISE NOTICE 'v_mk.id %', v_mk.id;

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO mk_id, log_id
    FROM import_log
    WHERE old_id = v_mk.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'MK';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_mk.id, mk_id, log_id;

    -- преобразование и получение параметров

    json_mk1 = array_to_json((SELECT array_agg(row_to_json(m1.*))
                              FROM (SELECT
                                      0                                                       AS id,
                                      (SELECT new_id
                                       FROM import_log
                                       WHERE old_id = m1.nomid AND lib_name = 'NOMENKLATUUR') AS nomid,
                                      (SELECT new_id
                                       FROM import_log
                                       WHERE old_id = m1.asutusid AND lib_name = 'ASUTUS')    AS asutusid,
                                      (SELECT new_id
                                       FROM import_log
                                       WHERE old_id = m1.journalid AND lib_name = 'JOURNAL')  AS journalid,
                                      summa,
                                      aa,
                                      pank,
                                      kood1,
                                      kood2,
                                      kood3,
                                      kood4,
                                      kood5,
                                      konto,
                                      tp,
                                      tunnus,
                                      proj
                                    FROM mk1 m1
                                    WHERE m1.parentid = v_mk.id) AS m1
                             ));

    --    RAISE NOTICE 'json_korder2 %', json_korder2;
    -- сохранение

    SELECT id
    INTO l_pank_id
    FROM ou.aa
    WHERE parentid = v_mk.rekvid
          AND arve = (SELECT arve
                      FROM aa
                      WHERE id = v_mk.aaid);

    IF NOT empty(v_mk.aaid) AND l_pank_id IS NULL
    THEN
      RAISE EXCEPTION 'kassa not found v_korder.kassaid %, l_pank_id %', v_mk.kassaid, l_pank_id;
    END IF;

    IF NOT empty(v_mk.arvid)
    THEN
      l_arv_id = (SELECT new_id
                  FROM import_log
                  WHERE old_id = v_mk.arvid AND lib_name = 'ARV');
      IF l_arv_id IS NULL
      THEN
        RAISE EXCEPTION 'Arve not found v_korder.arvid %, l_arv_id %', v_mk.arvid, l_arv_id;
      END IF;
    ELSE
      l_arv_id = NULL;
    END IF;

    -- DOKPROP
    l_dokprop_id = NULL;
    IF NOT empty(v_mk.doklausid)
    THEN
      PERFORM import_dokprop(v_mk.doklausid, CASE WHEN v_mk.opt = 1
        THEN 'SMK'
                                             ELSE 'VMK' END);
      l_dokprop_id = (SELECT new_id
                      FROM import_log
                      WHERE old_id = v_mk.doklausid AND lib_name = 'DOKPROP');
      IF l_dokprop_id IS NULL
      THEN
        RAISE EXCEPTION 'Dokprop not found v_korder.doklausid %, l_arv_id %', v_mk.doklausid, l_dokprop_id;

      END IF;
    END IF;

    RAISE NOTICE 'v_korder.doklausid %,l_dokprop_id %', v_mk.doklausid, l_dokprop_id;

    SELECT
      coalesce(mk_id, 0) AS id,
      l_dokprop_id       AS doklausid,
      l_pank_id          AS aaid,
      l_arv_id           AS arvid,
      CASE WHEN empty(v_mk.opt)
        THEN 2
      ELSE 1 END         AS opt,
      v_mk.maksepaev     AS maksepaev,
      v_mk.viitenr       AS viitenr,
      v_mk.kpv           AS kpv,
      v_mk.number        AS number,
      v_mk.selg          AS selg,
      v_mk.muud          AS muud,
      json_mk1           AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(mk_id, 0) AS id,
            TRUE               AS import,
            v_params           AS data) row;

    SELECT docs.sp_salvesta_mk(json_object :: JSON, 1, v_mk.rekvid)
    INTO mk_id;

    RAISE NOTICE 'lib_id %, l_count %, v_korder.rekvid %, json_object %', mk_id, l_count, v_mk.rekvid, json_object;
    IF empty(mk_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
      RAISE NOTICE 'saved %', mk_id;
    END IF;

    -- правим ссылку на проводку


    IF year(v_mk.kpv) = 2018
    THEN
      FOR v_mk1 IN
      SELECT
        mk1.id,
        mk1.journalid
      FROM mk1
      WHERE mk1.parentid = v_mk.id
            AND NOT empty(mk1.journalid)
      LOOP
        SELECT new_id
        INTO l_journal_id
        FROM import_log
        WHERE old_id = v_mk1.journalid AND lib_name = 'JOURNAL';

        IF l_journal_id IS NOT NULL
        THEN
          UPDATE docs.mk1
          SET journalid = l_journal_id
          WHERE id = mk_id;
        END IF;


      END LOOP;


    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (mk_id, v_mk.id, 'MK', json_object :: JSON, hist_object :: JSON)
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

    -- проверка на сумму проводки и кол-во записей

    SELECT
      count(m1.id),
      sum(m1.summa)
    INTO l_control_count, l_control_summa
    FROM docs.mk m INNER JOIN docs.mk1 m1 ON m.id = m1.parentid
    WHERE m.parentid = mk_id;

    SELECT
      count(m1.id),
      sum(m1.summa)
    INTO l_j_count, l_j_summa
    FROM mk m INNER JOIN mk1 m1 ON m.id = m1.parentid
    WHERE m.id = v_mk.id;

    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_mk.id % , mk_id %, l_control_summa %, l_j_summa %, l_control_count %, l_j_count %', v_mk.id, mk_id, l_control_summa, l_j_summa, l_control_count, l_j_count;
    END IF;
    l_count = l_count + 1;
  END LOOP;

  -- control
  l_tulemus = (SELECT count(id)
               FROM docs.mk);
  IF (l_tulemus + 100)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
    --    RAISE notice 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
  END IF;

  IF l_count = 0
  THEN
    RAISE EXCEPTION 'mk not imported %', in_old_id;
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
SELECT import_mk(267722)

SELECT import_mk(id) from mk where year(kpv) = 2018 order by kpv limit all



*/