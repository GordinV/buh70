DROP FUNCTION IF EXISTS import_avans( );
DROP FUNCTION IF EXISTS import_avans( INTEGER );

CREATE OR REPLACE FUNCTION import_avans(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  avans_id        INTEGER;
  log_id          INTEGER;
  v_avans1        RECORD;
  v_avans3        RECORD;
  json_object     JSONB;
  hist_object     JSONB;
  v_params        RECORD;
  l_count         INTEGER = 0;
  l_tulemus       INTEGER = 0;
  json_avans2     JSONB;
  l_asutus        INTEGER;
  l_control_summa NUMERIC;
  l_control_count INTEGER;
  l_j_summa       NUMERIC;
  l_j_count       INTEGER;
  l_journal_id    INTEGER;
  l_dokprop_id    INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_avans1 IN
  SELECT a1.*
  FROM avans1 a1
    INNER JOIN rekv ON a1.rekvid = rekv.id AND rekv.parentid < 999
  WHERE (a1.id = in_old_id OR in_old_id IS NULL)
  ORDER BY a1.kpv
  LIMIT ALL
  LOOP

    RAISE NOTICE 'v_avans1.id %', v_avans1.id;

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO avans_id, log_id
    FROM import_log
    WHERE old_id = v_avans1.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'AVANS';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_avans1.id, avans_id, log_id;

    -- преобразование и получение параметров

    json_avans2 = array_to_json((SELECT array_agg(row_to_json(a2.*))
                                 FROM (SELECT
                                         0                                                       AS id,
                                         (SELECT new_id
                                          FROM import_log
                                          WHERE old_id = a2.nomid AND lib_name = 'NOMENKLATUUR') AS nomid,
                                         summa,
                                         kood1,
                                         kood2,
                                         kood3,
                                         kood4,
                                         kood5,
                                         konto,
                                         tunnus,
                                         kbm,
                                         kokku,
                                         proj
                                       FROM avans2 a2
                                       WHERE a2.parentid = v_avans1.id) AS a2
                                ));

    --    RAISE NOTICE 'json_korder2 %', json_korder2;
    -- сохранение
    SELECT new_id
    INTO l_asutus
    FROM import_log
    WHERE lib_name = 'ASUTUS' AND old_id = v_avans1.asutusid;

    -- DOKPROP

    l_dokprop_id = NULL;
    IF NOT empty(v_avans1.dokpropid)
    THEN
--      PERFORM import_dokprop(v_avans1.dokpropid, 'AVANS');
      l_dokprop_id = (SELECT new_id
                      FROM import_log
                      WHERE old_id = v_avans1.dokpropid AND lib_name = 'DOKPROP');

      IF l_dokprop_id IS NULL
      THEN
        RAISE NOTICE 'Dokprop not found v_korder.doklausid %, l_arv_id %', v_avans1.dokpropid, l_dokprop_id;

      END IF;
    END IF;

    SELECT
      coalesce(avans_id, 0) AS id,
      l_dokprop_id          AS dokpropid,
      l_asutus              AS asutusid,
      v_avans1.kpv          AS kpv,
      v_avans1.number       AS number,
      v_avans1.jaak         AS jaak,
      v_avans1.selg         AS selg,
      v_avans1.muud         AS muud,
      json_avans2           AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(avans_id, 0) AS id,
            TRUE                  AS import,
            v_params              AS data) row;

    SELECT docs.sp_salvesta_avans(json_object :: JSON, 1, v_avans1.rekvid)
    INTO avans_id;

    --    RAISE NOTICE 'lib_id %, l_count %, v_korder.rekvid %, json_object %', korder_id, l_count, v_korder.rekvid, json_object;
    IF empty(avans_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
    --      RAISE NOTICE 'saved %', korder_id;
    END IF;

    -- правим ссылку на проводку

--    IF year(v_avans1.kpv) = 2018 AND NOT empty(v_avans1.journalid)
 --   THEN
      SELECT new_id
      INTO l_journal_id
      FROM import_log
      WHERE old_id = v_avans1.journalid AND lib_name = 'JOURNAL';

      IF l_journal_id IS NOT NULL
      THEN
        UPDATE docs.avans1
        SET journalid = l_journal_id
        WHERE parentid = avans_id;
      END IF;
 --   END IF;

    -- правим автора
    UPDATE docs.doc
    SET history = jsonb_set(doc.history, '{0,"user"}'::TEXT[],
      to_jsonb((SELECT trim(ametnik)
      FROM userid
      WHERE id = v_avans1.userid)))
      WHERE id = avans_id;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (avans_id, v_avans1.id, 'AVANS', json_object :: JSON, hist_object :: JSON)
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
/*
    SELECT
      count(a2.id),
      sum(a2.summa)
    INTO l_control_count, l_control_summa
    FROM docs.avans1 a1 INNER JOIN docs.avans2 a2 ON a1.id = a2.parentid
    WHERE a1.parentid = avans_id;

    SELECT
      count(a2.id),
      sum(a2.summa)
    INTO l_j_count, l_j_summa
    FROM avans1 a1 INNER JOIN avans2 a2 ON a1.id = a2.parentid
    WHERE a1.id = v_avans1.id;
    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_avans.id % , korder_id %, l_control_summa %, l_j_summa %,, l_control_count %, l_j_count %', v_avans1.id, avans_id, l_control_summa, l_j_summa, l_control_count, l_j_count;
    END IF;
*/
    -- tasu
    DELETE FROM docs.avans3
    WHERE parentid = avans_id;

    FOR v_avans3 IN
    SELECT
      a3.*,
      (SELECT i.new_id
       FROM import_log i
       WHERE old_id = a3.dokid AND i.lib_name = a3.muud
       LIMIT 1) AS new_dokid
    FROM avans3 a3
    WHERE a3.parentid = v_avans1.id
    LOOP
      INSERT INTO docs.avans3 (parentid, dokid, muud, liik, summa)
      VALUES (avans_id, v_avans3.new_dokid, v_avans3.muud, v_avans3.liik, v_avans3.summa);
    END LOOP;

    l_count = l_count + 1;
  END LOOP;

  -- control
  /*
  l_tulemus = (SELECT count(id)
               FROM docs.avans1);
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
    RAISE EXCEPTION 'korder not imported %', in_old_id;
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
SELECT import_avans(26292)

SELECT import_avans(id) from avans1 where year(kpv) = 2018 order by kpv limit all



*/