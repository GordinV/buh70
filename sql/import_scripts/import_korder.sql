DROP FUNCTION IF EXISTS import_korder( );
DROP FUNCTION IF EXISTS import_korder( INTEGER );

CREATE OR REPLACE FUNCTION import_korder(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  korder_id       INTEGER;
  log_id          INTEGER;
  v_korder        RECORD;
  json_object     JSONB;
  hist_object     JSONB;
  v_params        RECORD;
  l_count         INTEGER = 0;
  l_tulemus       INTEGER = 0;
  json_korder2    JSONB;
  l_asutus        INTEGER;
  l_control_summa NUMERIC;
  l_control_count INTEGER;
  l_j_summa       NUMERIC;
  l_j_count       INTEGER;
  l_journal_id    INTEGER;
  l_nom_id        INTEGER;
  l_kassa_id      INTEGER;
  l_arv_id        INTEGER;
  l_dokprop_id    INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_korder IN
  SELECT k1.*
  FROM korder1 k1
    INNER JOIN rekv ON k1.rekvid = rekv.id AND rekv.parentid < 999
  WHERE (k1.id = in_old_id OR in_old_id IS NULL)
  ORDER BY k1.kpv
  LIMIT ALL
  LOOP

    RAISE NOTICE 'v_korder1.id %', v_korder.id;

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO korder_id, log_id
    FROM import_log
    WHERE old_id = v_korder.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'KORDER';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_korder.id, korder_id, log_id;

    -- преобразование и получение параметров

    json_korder2 = array_to_json((SELECT array_agg(row_to_json(a1.*))
                                  FROM (SELECT
                                          0                                                       AS id,
                                          (SELECT new_id
                                           FROM import_log
                                           WHERE old_id = k2.nomid AND lib_name = 'NOMENKLATUUR') AS nomid,
                                          summa,
                                          kood1,
                                          kood2,
                                          kood3,
                                          kood4,
                                          kood5,
                                          konto,
                                          tp,
                                          tunnus,
                                          proj,
                                          nimetus                                                    muud
                                        FROM korder2 k2
                                        WHERE k2.parentid = v_korder.id) AS a1
                                 ));

    --    RAISE NOTICE 'json_korder2 %', json_korder2;
    -- сохранение
    SELECT new_id
    INTO l_asutus
    FROM import_log
    WHERE lib_name = 'ASUTUS' AND old_id = v_korder.asutusid;

    SELECT id
    INTO l_kassa_id
    FROM ou.aa
    WHERE parentid = v_korder.rekvid
          AND arve = (SELECT arve
                      FROM aa
                      WHERE id = v_korder.kassaid );

    IF NOT empty(v_korder.kassaid) AND l_kassa_id IS NULL
    THEN
      RAISE EXCEPTION 'kassa not found v_korder.kassaid %, l_kassa_id %', v_korder.kassaid, l_kassa_id;
    END IF;

    IF NOT empty(v_korder.arvid)
    THEN
      l_arv_id = (SELECT new_id
                  FROM import_log
                  WHERE old_id = v_korder.arvid AND lib_name = 'ARV');
      IF l_arv_id IS NULL
      THEN
        RAISE EXCEPTION 'Arve not found v_korder.arvid %, l_arv_id %', v_korder.arvid, l_arv_id;
      END IF;
    ELSE
      l_arv_id = NULL;
    END IF;

    -- DOKPROP
    l_dokprop_id = NULL;
    IF NOT empty(v_korder.doklausid)
    THEN
      PERFORM import_dokprop(v_korder.doklausid);
      l_dokprop_id = (SELECT new_id
                      FROM import_log
                      WHERE old_id = v_korder.doklausid AND lib_name = 'DOKPROP');
      IF l_dokprop_id IS NULL
      THEN
        RAISE EXCEPTION 'Dokprop not found v_korder.doklausid %, l_arv_id %', v_korder.doklausid, l_dokprop_id;

      END IF;
    END IF;

    RAISE NOTICE 'v_korder.doklausid %,l_dokprop_id %', v_korder.doklausid, l_dokprop_id;

    SELECT
      coalesce(korder_id, 0) AS id,
      l_dokprop_id           AS doklausid,
      l_asutus               AS asutusid,
      l_kassa_id             AS kassaid,
      l_arv_id               AS arvid,
      v_korder.kpv           AS kpv,
      v_korder.tyyp          AS tyyp,
      v_korder.number        AS number,
      v_korder.summa         AS summa,
      v_korder.nimi          AS nimi,
      v_korder.aadress       AS aadress,
      v_korder.dokument      AS dokument,
      v_korder.alus          AS alus,
      v_korder.doktyyp       AS doktyyp,
      v_korder.muud          AS muud,
      json_korder2           AS "gridData"
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(korder_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT docs.sp_salvesta_korder(json_object :: JSON, 1, v_korder.rekvid)
    INTO korder_id;

    --    RAISE NOTICE 'lib_id %, l_count %, v_korder.rekvid %, json_object %', korder_id, l_count, v_korder.rekvid, json_object;
    IF empty(korder_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
    --      RAISE NOTICE 'saved %', korder_id;
    END IF;

    -- правим ссылку на проводку

    IF year(v_korder.kpv) = 2018 AND v_korder.journalid IS NOT NULL AND NOT empty(v_korder.journalid)
    THEN
      SELECT new_id
      INTO l_journal_id
      FROM import_log
      WHERE old_id = v_korder.journalid AND lib_name = 'JOURNAL';

      IF l_journal_id IS NOT NULL
      THEN
        UPDATE docs.korder1
        SET journalid = l_journal_id
        WHERE parentid = korder_id;
      END IF;
    END IF;

-- правим автора
    UPDATE docs.doc
    SET history = jsonb_set(doc.history, '{0,"user"}'::TEXT[],
                            to_jsonb((SELECT trim(ametnik)
                                      FROM userid
                                      WHERE id = v_korder.userid)))
    WHERE id = korder_id;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (korder_id, v_korder.id, 'KORDER', json_object :: JSON, hist_object :: JSON)
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
      count(k2.id),
      sum(k2.summa)
    INTO l_control_count, l_control_summa
    FROM docs.korder1 k1 INNER JOIN docs.korder2 k2 ON k1.id = k2.parentid
    WHERE k1.parentid = korder_id;

    SELECT
      count(k2.id),
      sum(k2.summa)
    INTO l_j_count, l_j_summa
    FROM korder1 k1 INNER JOIN korder2 k2 ON k1.id = k2.parentid
    WHERE k1.id = v_korder.id;
    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_korder.id % , korder_id %, l_control_summa %, l_j_summa %,, l_control_count %, l_j_count %', v_korder.id, korder_id, l_control_summa, l_j_summa, l_control_count, l_j_count;
    END IF;
    l_count = l_count + 1;
  END LOOP;

  -- control
  /*
  l_tulemus = (SELECT count(id)
               FROM docs.korder1);
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

--SELECT import_korder(73878)
/*
SELECT import_korder(73230)

SELECT import_korder(id) from korder1 where year(kpv) = 2018 order by kpv limit all



*/