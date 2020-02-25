DROP FUNCTION IF EXISTS import_nomenklatuur( );
DROP FUNCTION IF EXISTS import_nomenklatuur( integer);
DROP FOREIGN TABLE IF EXISTS remote_nomenklatuur;
DROP FOREIGN TABLE IF EXISTS remote_klassiflib;

CREATE FOREIGN TABLE remote_nomenklatuur (
  id        SERIAL                         NOT NULL,
  rekvid    INTEGER                        NOT NULL,
  doklausid INTEGER       DEFAULT 0        NOT NULL,
  dok       CHAR(20)      DEFAULT space(1) NOT NULL,
  kood      CHAR(20)      DEFAULT space(1) NOT NULL,
  nimetus   CHAR(254)     DEFAULT space(1) NOT NULL,
  uhik      CHAR(20)      DEFAULT space(1) NOT NULL,
  hind      NUMERIC(12,4) DEFAULT 0        NOT NULL,
  muud      TEXT,
  ulehind   NUMERIC(12,4) DEFAULT 0        NOT NULL,
  kogus     NUMERIC(12,3) DEFAULT 0        NOT NULL,
  formula   TEXT          DEFAULT space(1) NOT NULL,
  vanaid    INTEGER
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'nomenklatuur');

CREATE FOREIGN TABLE remote_klassiflib (
  id        SERIAL                        NOT NULL,
  nomid     INTEGER     DEFAULT 0         NOT NULL,
  palklibid INTEGER     DEFAULT 0         NOT NULL,
  libid     INTEGER     DEFAULT 0         NOT NULL,
  tyyp      INTEGER     DEFAULT 1         NOT NULL,
  tunnusid  INTEGER     DEFAULT 0         NOT NULL,
  kood1     VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood2     VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood3     VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood4     VARCHAR(20) DEFAULT space(20) NOT NULL,
  kood5     VARCHAR(20) DEFAULT space(20) NOT NULL,
  konto     VARCHAR(20) DEFAULT space(20) NOT NULL,
  vanaid    INTEGER,
  proj      VARCHAR(20) DEFAULT space(20) NOT NULL
  )
  SERVER db_narva_ee
  OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'klassiflib');

CREATE OR REPLACE FUNCTION import_nomenklatuur(in_old_id integer)
  RETURNS INTEGER AS
$BODY$
DECLARE
  nom_id      INTEGER;
  log_id      INTEGER;
  v_nom       RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_konto     TEXT;
  v_libs      RECORD;
  l_vat       NUMERIC = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_nom IN
  SELECT *
  FROM nomenklatuur n
    INNER JOIN rekv ON rekv.id = n.rekvid AND rekv.parentid < 999
  WHERE (n.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO nom_id, log_id
    FROM import_log
    WHERE old_id = v_nom.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'NOMENKLATUUR';

    -- поиск pv_konto
    SELECT
      k.*,
      l.kood AS tunnus
    INTO v_libs
    FROM remote_klassiflib k
      LEFT OUTER JOIN library l ON l.id = k.tunnusid
    WHERE nomid = v_nom.id
    ORDER BY konto DESC, tyyp
    LIMIT 1;

    l_vat = (SELECT CASE WHEN v_nom.doklausid = 0 OR v_nom.doklausid = 5
      THEN 20
                    WHEN v_nom.doklausid = 2
                      THEN 5
                    WHEN v_nom.doklausid = 3
                      THEN NULL
                    WHEN v_nom.doklausid = 4
                      THEN 9
                    ELSE 20
                    END);

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_nom.id, nom_id, log_id;

    -- преобразование и получение параметров
    -- сохранение
    SELECT
      coalesce(nom_id, 0) AS id,
      v_nom.kood          AS kood,
      v_nom.nimetus       AS nimetus,
      v_nom.muud          AS muud,
      v_nom.dok           AS dok,
      v_nom.uhik          AS uhik,
      v_nom.hind          AS hind,
      v_nom.ulehind       AS ulehind,
      v_nom.kogus         AS kogus,
      l_vat               AS vat,
      v_libs.konto        AS konto,
      v_libs.proj         AS proj,
      v_libs.tunnus       AS tunnus,
      v_libs.kood1        AS tegev,
      v_libs.kood2        AS allikas,
      v_libs.kood5        AS artikkel,
      v_libs.kood3        AS rahavoog
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(nom_id, 0) AS id,
            TRUE                AS import,
            v_params            AS data) row;

    SELECT libs.sp_salvesta_nomenclature(json_object :: JSON, 1, v_nom.rekvid)
    INTO nom_id;
    RAISE NOTICE 'lib_id %, l_count %', nom_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (nom_id, v_nom.id, 'NOMENKLATUUR', json_object :: JSON, hist_object :: JSON)
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
      FROM libs.nomenklatuur)
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


/*
SELECT import_nomenklatuur()

select * from remote_library limit 10

*/