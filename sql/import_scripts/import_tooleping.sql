DROP FUNCTION IF EXISTS import_tooleping( INTEGER );

CREATE OR REPLACE FUNCTION import_tooleping(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  leping_id    INTEGER;
  log_id       INTEGER;
  v_leping     RECORD;
  json_object  JSONB;
  hist_object  JSONB;
  v_params     RECORD;
  l_count      INTEGER = 0;
  l_osakond_id INTEGER;
  l_amet_id    INTEGER;
  l_asutus_id  INTEGER;
BEGIN
  -- выборка из "старого меню"

  FOR v_leping IN
  SELECT t.*
  FROM tooleping t
    INNER JOIN rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
  WHERE (t.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO leping_id, log_id
    FROM import_log
    WHERE old_id = v_leping.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TOOLEPING';

    RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_leping.id, leping_id, log_id;

    l_osakond_id = (SELECT new_id
                    FROM import_log
                    WHERE old_id = v_leping.osakondid AND lib_name = 'OSAKOND');
    l_amet_id = (SELECT new_id
                 FROM import_log
                 WHERE old_id = v_leping.ametid AND lib_name = 'AMET');

    l_asutus_id = (SELECT new_id
                        FROM import_log
                        WHERE old_id = v_leping.parentid AND lib_name = 'ASUTUS');

    IF l_osakond_id IS NULL OR l_amet_id IS NULL or l_asutus_id is null
    THEN
      RAISE EXCEPTION 'amet or osakond not found v_leping.osakondid %,l_osakond_id %, v_leping.ametid %, l_amet_id %, v_leping.parentid %,  l_asutus_id %', v_leping.osakondid, l_osakond_id, v_leping.ametid, l_amet_id, v_leping.parentid,  l_asutus_id;
    END IF;
    -- преобразование и получение параметров
    /*
      doc_algab      DATE = coalesce((doc_data ->> 'algab') :: DATE, now() :: DATE);
      doc_lopp       DATE = CASE WHEN ltrim(rtrim((doc_data ->> 'lopp') :: TEXT)) = ''
        THEN NULL :: DATE
                            ELSE (doc_data ->> 'lopp') :: DATE END;
      doc_palk       NUMERIC(14, 2) = doc_data ->> 'palk';
      doc_palgamaar  INTEGER = coalesce((doc_data ->> 'palgamaar') :: INTEGER,
                                        array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK'));
      doc_muud       TEXT = doc_data ->> 'muud';
      doc_resident   INTEGER = doc_data ->> 'resident';
      doc_riik       TEXT = doc_data ->> 'riik';
      doc_toend      DATE = doc_data ->> 'toend';
      doc_koormus    NUMERIC(14, 4) = coalesce((doc_data ->> 'koormus') :: NUMERIC, 100);
      doc_toopaev    NUMERIC(14, 4) = coalesce((doc_data ->> 'toopaev') :: NUMERIC, 8);
      doc_pohikoht   INTEGER = coalesce((doc_data ->> 'pohikoht') :: INTEGER, 1);
      doc_ametnik    INTEGER = coalesce((doc_data ->> 'ametnik') :: INTEGER, 0);
      doc_tasuliik   INTEGER = coalesce((doc_data ->> 'tasuliik') :: INTEGER,
                                        array_position((enum_range(NULL :: PALK_TASU_LIIK)), 'ASTMEPALK'));

     */
    -- сохранение
    SELECT
      coalesce(leping_id, 0) AS id,
      l_asutus_id as parentid,
      l_osakond_id as osakondid,
      l_amet_id as ametid,
      v_leping.algab,
      v_leping.lopp,
      v_leping.palk,
      v_leping.palgamaar,
      v_leping.resident,
      v_leping.riik,
      v_leping.toend,
      v_leping.koormus,
      v_leping.toopaev,
      v_leping.ametnik,
      v_leping.tasuliik,
      v_leping.muud          AS muud
    INTO v_params;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(leping_id, 0) AS id,
            TRUE                   AS import,
            v_params               AS data) row;

    SELECT palk.sp_salvesta_tooleping(json_object :: JSON, 1, 1)
    INTO leping_id;
    RAISE NOTICE 'leping_id %, l_count %', leping_id, l_count;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (leping_id, v_leping.id, 'TOOLEPING', json_object :: JSON, hist_object :: JSON)
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
SELECT import_tooleping(136489)
SELECT import_tooleping(id) from tooleping where
lopp is null or year(lopp) >= 2017
INSERT INTO library (id, rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, vanaid) VALUES (287565, 112, '0922013             ', 'Narva Soldino G𭮡asium 0922013                                                                                                                                                                                                                              ', 'OSAKOND             ', NULL, 0, 0, 0, 0, 0, NULL);

*/

--INSERT INTO library (id, rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5, vanaid) VALUES (611504, 112, 'pedagoog-P          ', 'pedagoog-P                                                                                                                                                                                                                                                    ', 'AMET                ', '', 0, 0, 0, 0, 0, NULL);