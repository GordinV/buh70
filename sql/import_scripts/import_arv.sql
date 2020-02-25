DROP FUNCTION IF EXISTS import_arv();
DROP FUNCTION IF EXISTS import_arv(INTEGER);

DROP FOREIGN TABLE IF EXISTS remote_arv;
DROP FOREIGN TABLE IF EXISTS remote_arv1;

CREATE FOREIGN TABLE remote_arv (
  id        SERIAL                                    NOT NULL,
  rekvid    INTEGER                                   NOT NULL,
  userid    INTEGER                                   NOT NULL,
  journalid INTEGER       DEFAULT 0                   NOT NULL,
  doklausid INTEGER       DEFAULT 0                   NOT NULL,
  liik      SMALLINT      DEFAULT 0                   NOT NULL,
  operid    INTEGER       DEFAULT 0                   NOT NULL,
  number    CHAR(20)      DEFAULT space(1)            NOT NULL,
  kpv       DATE          DEFAULT ('now'::TEXT)::DATE NOT NULL,
  asutusid  INTEGER       DEFAULT 0                   NOT NULL,
  arvid     INTEGER       DEFAULT 0                   NOT NULL,
  lisa      CHAR(120)     DEFAULT space(1),
  tahtaeg   DATE,
  kbmta     NUMERIC(12,4) DEFAULT 0                   NOT NULL,
  kbm       NUMERIC(12,4) DEFAULT 0                   NOT NULL,
  summa     NUMERIC(12,4) DEFAULT 0                   NOT NULL,
  tasud     DATE,
  tasudok   CHAR(254),
  muud      TEXT,
  jaak      NUMERIC(12,4) DEFAULT 0                   NOT NULL,
  objektid  INTEGER       DEFAULT 0                   NOT NULL,
  objekt    VARCHAR(20),
  vanaid    INTEGER
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'arv');

CREATE FOREIGN TABLE remote_arv1 (
  id       SERIAL                          NOT NULL,
  parentid INTEGER                         NOT NULL,
  nomid    INTEGER                         NOT NULL,
  kogus    NUMERIC(18,3) DEFAULT 0         NOT NULL,
  hind     NUMERIC(12,4) DEFAULT 0         NOT NULL,
  soodus   SMALLINT      DEFAULT 0         NOT NULL,
  kbm      NUMERIC(12,4) DEFAULT 0         NOT NULL,
  maha     SMALLINT      DEFAULT 0         NOT NULL,
  summa    NUMERIC(12,4) DEFAULT 0         NOT NULL,
  muud     TEXT,
  kood1    VARCHAR(20)   DEFAULT space(20) NOT NULL,
  kood2    VARCHAR(20)   DEFAULT space(20) NOT NULL,
  kood3    VARCHAR(20)   DEFAULT space(20) NOT NULL,
  kood4    VARCHAR(20)   DEFAULT space(20) NOT NULL,
  kood5    VARCHAR(20)   DEFAULT space(20) NOT NULL,
  konto    VARCHAR(20)   DEFAULT space(20) NOT NULL,
  tp       VARCHAR(20)   DEFAULT space(20) NOT NULL,
  kbmta    NUMERIC(12,4) DEFAULT 0         NOT NULL,
  isikid   INTEGER       DEFAULT 0         NOT NULL,
  tunnus   VARCHAR(20)   DEFAULT space(20) NOT NULL,
  proj     VARCHAR(20)   DEFAULT space(20),
  tahtaeg  DATE,
  vanaid   INTEGER
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'arv1');


CREATE OR REPLACE FUNCTION import_arv(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  arv_id      INTEGER;
  log_id      INTEGER;
  v_arv       RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_tulemus   INTEGER = 0;
  json_arv1   JSONB;
  l_asutus    INTEGER;
  l_control_summa NUMERIC;
  l_control_count INTEGER;
  l_j_summa       NUMERIC;
  l_j_count       INTEGER;
  l_journal_id    INTEGER;
  l_nom_id        INTEGER;
  l_dokpropid     INTEGER;
  l_arve_id       INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_arv IN
  SELECT a.*
  FROM arv a
         INNER JOIN remote_rekv rekv ON a.rekvid = rekv.id AND rekv.parentid < 999
  WHERE (a.id = in_old_id OR in_old_id IS NULL)
  ORDER BY a.kpv
  LIMIT ALL
  LOOP

    RAISE NOTICE 'v_arv.id %', v_arv.id;

    -- поиск и проверка на ранее сделанный импорт
    SELECT new_id, id
        INTO arv_id, log_id
    FROM import_log
    WHERE old_id = v_arv.id
      AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'ARV';

    l_dokpropid = (SELECT new_id FROM import_log WHERE lib_name = 'DOKPROP'
                                                   AND old_id = v_arv.doklausid);

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_arv.id, arv_id, log_id;

    -- преобразование и получение параметров
    json_arv1 = array_to_json((SELECT array_agg(row_to_json(a1.*))
                               FROM (SELECT 0 AS id,
                                            (SELECT new_id FROM import_log WHERE old_id = a1.nomid
                                                                             AND lib_name = 'NOMENKLATUUR') AS nomid,
                                            kogus,
                                            hind,
                                            kbm,
                                            summa,
                                            kood1,
                                            kood2,
                                            kood3,
                                            kood4,
                                            kood5,
                                            konto,
                                            tunnus,
                                            tp,
                                            muud,
                                            (SELECT new_id
                                             FROM import_log
                                             WHERE lib_name = 'ARV'
                                               AND old_id IN
                                                   (SELECT id
                                                    FROM remote_arv arv
                                                    WHERE ltrim(rtrim(arv.number)) :: TEXT = ltrim(rtrim(substr(a1.muud, 10, 20)))
                                                      AND arv.rekvid = v_arv.rekvid)
                                             LIMIT 1) AS arve_id
                                     FROM arv1 a1
                                     WHERE a1.parentid = v_arv.id) AS a1));

    RAISE NOTICE 'json_arv1 %', json_arv1;
    -- сохранение
    SELECT new_id
        INTO l_asutus FROM import_log WHERE lib_name = 'ASUTUS'
                                        AND old_id = v_arv.asutusid;

    SELECT coalesce(arv_id, 0) AS id,
           l_asutus            AS asutusid,
           v_arv.kpv           AS kpv,
           v_arv.liik          AS liik,
           v_arv.number        AS number,
           v_arv.lisa          AS lisa,
           v_arv.tahtaeg       AS tahtaeg,
           v_arv.kbmta         AS kbmta,
           v_arv.kbm           AS kbm,
           v_arv.summa         AS summa,
           v_arv.objekt        AS objekt,
           v_arv.objektid      AS objektid,
           v_arv.muud          AS muud,
           l_dokpropid         AS doklausid,
           json_arv1           AS "gridData"
        INTO v_params;

    SELECT row_to_json(row)
        INTO json_object
    FROM (SELECT coalesce(arv_id, 0) AS id, TRUE AS import, v_params AS data) row;

    SELECT docs.sp_salvesta_arv(json_object :: JSON, 1, v_arv.rekvid)
        INTO arv_id;
    RAISE NOTICE 'lib_id %, l_count %, json_object %', arv_id, l_count, json_object;
    IF empty(arv_id)
    THEN
      RAISE EXCEPTION 'saving not success';
    ELSE
      RAISE NOTICE 'saved %', arv_id;
    END IF;

    -- правим ссылку на проводку

    IF year(v_arv.kpv) = 2018 AND NOT empty(v_arv.journalid)
    THEN
      SELECT new_id
          INTO l_journal_id FROM import_log WHERE old_id = v_arv.journalid
                                              AND lib_name = 'JOURNAL';

      IF l_journal_id IS NOT NULL
      THEN
        UPDATE docs.arv SET journalid = l_journal_id WHERE parentid = arv_id;

        UPDATE docs.doc SET docs_ids = array_append(docs_ids, l_journal_id) WHERE id = arv_id;
      END IF;


    END IF;

    -- правим автора

    UPDATE docs.doc
    SET history = jsonb_set(doc.history, '{0,"user"}'::TEXT[],
                            to_jsonb((SELECT trim(ametnik)
                                      FROM userid
                                      WHERE id = v_arv.userid)))
    WHERE id = arv_id;

    -- salvestame log info
    SELECT row_to_json(row)
        INTO hist_object FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (arv_id, v_arv.id, 'ARV', json_object :: JSON, hist_object :: JSON)
          RETURNING id
            INTO log_id;

    ELSE
      UPDATE import_log
      SET params  = json_object :: JSON,
          history = (history :: JSONB || hist_object :: JSONB) :: JSON
      WHERE id = log_id;
    END IF;

    IF empty(log_id)
    THEN
      RAISE EXCEPTION 'log save failed';
    END IF;

    -- проверка на сумму проводки и кол-во записей

    SELECT count(id), sum(summa)
        INTO l_control_count, l_control_summa FROM cur_journal WHERE id = arv_id;

    SELECT count(j1.id), sum(j1.summa)
        INTO l_j_count, l_j_summa
    FROM journal j
           INNER JOIN journal1 j1 ON j.id = j1.parentid
    WHERE j.id = v_arv.id;
    IF (l_j_count) <> l_control_count OR
       (l_j_summa) <> l_control_summa
    THEN
      RAISE EXCEPTION 'kontrol failed v_journal.id % , journal_id %, l_control_summa %, l_j_summa %,, l_control_count %, l_j_count %', v_arv.id, arv_id, l_control_summa, l_j_summa, l_control_count, l_j_count;
    END IF;
    l_count = l_count + 1;
  END LOOP;

  -- control
    /*
  l_tulemus = (SELECT count(id) FROM docs.arv);
  IF (l_tulemus + 100)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
  --    RAISE notice 'Import failed, new_count < old_count %, new_count %', l_count, l_tulemus;
  END IF;
*/
    
  IF l_count = 0
  THEN
    RAISE EXCEPTION 'arve not imported %', in_old_id;
  END IF;

  RETURN l_count;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql
VOLATILE
COST 100;


/*
SELECT import_arv(id) from arv where rekvid = 130 and year(kpv) >=2017 and arv.objektid  is not null and objektid > 0
and id = 436030
 and arv.id in (select parentid from arv1 where muud is not null and not empty(muud))

SELECT import_arv(id) from arv where year(kpv) = 2018 order by kpv limit all

*/