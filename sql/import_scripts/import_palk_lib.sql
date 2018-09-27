DROP FUNCTION IF EXISTS import_palk( );
DROP FUNCTION IF EXISTS import_palk( INTEGER );

CREATE OR REPLACE FUNCTION import_palk(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  lib_id      INTEGER;
  log_id      INTEGER;
  v_lib       RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
  l_tunnus    INTEGER;
  l_tulemus   INTEGER = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_lib IN
  SELECT
    l.*,
    p.liik,
    p.tund,
    p.maks,
    p.round,
    p.sots,
    p.elatis,
    p.tululiik,
    p.asutusest,
    p.palgafond,
    p.konto AS korrkonto,
    k.tunnusid,
    k.konto,
    k.kood1 AS tegev,
    k.kood2 AS allikas,
    k.kood3 AS rahavoog,
    k.kood5 AS artikkel,
    k.kood4 AS uritus,
    t.kood  AS tunnus,
    k.proj
  FROM library l
    INNER JOIN palk_lib p ON p.parentid = l.id
    LEFT OUTER JOIN klassiflib k ON k.libid = l.id
    LEFT OUTER JOIN library t ON t.id = k.tunnusid
    INNER JOIN rekv ON l.rekvid = rekv.id AND rekv.parentid < 999
  WHERE l.library = 'PALK'
        AND (l.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO lib_id, log_id
    FROM import_log
    WHERE old_id = v_lib.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = upper(ltrim(rtrim(v_lib.library :: TEXT)));

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_lib.id, lib_id, log_id;

    -- преобразование и получение параметров
    -- ищем tunnusid
    SELECT id
    INTO l_tunnus
    FROM import_log
    WHERE old_id = v_lib.tunnusid AND lib_name = 'TUNNUS';

    -- сохранение
    SELECT
      coalesce(lib_id, 0) AS id,
      v_lib.kood          AS kood,
      v_lib.nimetus       AS nimetus,
      v_lib.tun1          AS tun1,
      v_lib.tun2          AS tun2,
      v_lib.tun3          AS tun3,
      v_lib.tun4          AS tun4,
      v_lib.tun5          AS tun5,
      v_lib.liik          AS liik,
      v_lib.tululiik      AS tululiik,
      v_lib.tund          AS tund,
      v_lib.maks          AS maks,
      v_lib.asutusest     AS asutusest,
      v_lib.palgafond     AS palgafond,
      v_lib.sots          AS sots,
      v_lib.elatis        AS elatis,
      v_lib.round         AS round,
      v_lib.konto         AS konto,
      v_lib.korrkonto     AS korrkonto,
      l_tunnus            AS tunnusid,
      v_lib.uritus        AS uritus,
      v_lib.proj          AS proj,
      v_lib.tegev         AS tegev,
      v_lib.allikas       AS allikas,
      v_lib.artikkel      AS artikkel,
      v_lib.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(lib_id, 0) AS id,
            TRUE                AS import,
            v_params            AS data) row;

    SELECT libs.sp_salvesta_palk_lib(json_object :: JSON, 1, v_lib.rekvid)
    INTO lib_id;
    RAISE NOTICE 'lib_id %, l_count %', lib_id, l_count;
    IF empty(lib_id)
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
      VALUES (lib_id, v_lib.id, v_lib.library, json_object :: JSON, hist_object :: JSON)
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
               FROM libs.library
               WHERE LIBRARY = 'PALK');
  IF (l_tulemus + 100)
     >= l_count
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    SELECT
      l.*,
      p.liik,
      p.tund,
      p.maks,
      p.round,
      p.sots,
      p.elatis,
      p.tululiik,
      p.asutusest,
      p.palgafond,
      p.konto AS korrkonto,
      k.tunnusid,
      k.konto,
      k.kood1 AS tegev,
      k.kood2 AS allikas,
      k.kood3 AS rahavoog,
      k.kood5 AS artikkel,
      k.kood4 AS uritus,
      t.kood  AS tunnus,
      k.proj
    INTO v_lib
    FROM library l
      INNER JOIN palk_lib p ON p.parentid = l.id
      INNER JOIN klassiflib k ON k.libid = l.id
      LEFT OUTER JOIN library t ON t.id = k.tunnusid
      INNER JOIN rekv ON l.rekvid = rekv.id AND rekv.parentid < 999
    WHERE l.library = 'PALK'
          AND l.id NOT IN (SELECT old_id
                           FROM import_log
                           WHERE import_log.lib_name = 'PALK')
    LIMIT 1;
    RAISE EXCEPTION 'Import failed, new_count < old_count %, new_count %, v_lib %', l_count, l_tulemus, v_lib;
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
SELECT import_palk(625237)

*/