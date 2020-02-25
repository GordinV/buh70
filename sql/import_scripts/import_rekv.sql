DROP FUNCTION IF EXISTS import_rekv( );

DROP FOREIGN TABLE IF EXISTS remote_rekv;

CREATE FOREIGN TABLE remote_rekv (
  id      INTEGER                       NOT NULL,
  parentid INTEGER                    NOT NULL,
  regkood  CHAR(20)  DEFAULT space(1) NOT NULL,
  nimetus  CHAR(254) DEFAULT space(1) NOT NULL,
  kbmkood  CHAR(20)  DEFAULT space(1) NOT NULL,
  aadress  TEXT      DEFAULT space(1) NOT NULL,
  haldus   CHAR(254) DEFAULT space(1) NOT NULL,
  tel      CHAR(120) DEFAULT space(1) NOT NULL,
  faks     CHAR(120) DEFAULT space(1) NOT NULL,
  email    CHAR(120) DEFAULT space(1) NOT NULL,
  juht     CHAR(120) DEFAULT space(1) NOT NULL,
  raama    CHAR(120) DEFAULT space(1) NOT NULL,
  muud     TEXT,
  recalc   SMALLINT  DEFAULT 1        NOT NULL)
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'rekv');


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
  FROM remote_rekv r
  WHERE r.parentid < 999
  and id > 130
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
    DELETE FROM ou.aa
    WHERE parentid = v_rekv.id;

    json_aa = array_to_json((SELECT array_agg(row_to_json(a1.*))
                             FROM (SELECT
                                     0 AS id,
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
                                  ) AS a1
                            ));

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
    json_object = ('{"import":true, "data":' || trim(TRAILING FROM (row_to_json(v_params)) :: TEXT, '}') :: TEXT ||
                   ',"gridData":' || json_aa :: TEXT || '}}');

    RAISE NOTICE 'salvestame, params %', json_object;


    SELECT ou.sp_salvesta_REKV(json_object :: JSON, 63, 2477)
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
 --   RAISE EXCEPTION 'Import failed, new_count < old_count %', l_count;
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
SELECT import_rekv();
DROP FUNCTION IF EXISTS import_rekv( );
*/
