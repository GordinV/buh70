DROP FUNCTION IF EXISTS import_userid( INTEGER );

CREATE FOREIGN TABLE remote_userid (

  id       INTEGER                                        NOT NULL,
  rekvid       INTEGER                 NOT NULL,
  kasutaja     CHAR(50)                NOT NULL,
  ametnik      CHAR(254)               NOT NULL,
  parool       TEXT,
  kasutaja_    INTEGER   DEFAULT 1     NOT NULL,
  peakasutaja_ INTEGER   DEFAULT 0     NOT NULL,
  admin        INTEGER   DEFAULT 0     NOT NULL,
  muud         TEXT  )

  SERVER db_narva_ee
  OPTIONS (schema_name 'public', table_name 'userid');

CREATE OR REPLACE FUNCTION import_userid(in_old_id INTEGER)
  RETURNS INTEGER AS
$BODY$
DECLARE
  user_id     INTEGER;
  log_id      INTEGER;
  v_user      RECORD;
  json_object JSONB;
  hist_object JSONB;
  v_params    RECORD;
  l_count     INTEGER = 0;
BEGIN
  -- выборка из "старого меню"

  FOR v_user IN
  SELECT u.*
  FROM userid u
  WHERE (u.id = in_old_id OR in_old_id IS NULL)
  LIMIT ALL
  LOOP

    -- поиск и проверка на ранее сделанный импорт
    SELECT
      new_id,
      id
    INTO user_id, log_id
    FROM import_log
    WHERE old_id = v_user.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'USERID';


    RAISE NOTICE 'check for lib.. v_user.id -> %, found -> % log_id -> %', v_user.id, user_id, log_id;

    -- преобразование и получение параметров

    -- сохранение
    SELECT
      coalesce(user_id, 0)           AS id,
      v_user.kasutaja                AS kasutaja,
      v_user.ametnik                 AS ametnik,
      v_user.kasutaja_               AS kasutaja_,
      v_user.peakasutaja_            AS peakasutaja_,
      v_user.admin                   AS admin,
      v_user.muud                    AS muud,
      NOT empty(v_user.kasutaja_)    AS is_kasutaja,
      NOT empty(v_user.peakasutaja_) AS is_peakasutaja,
      NOT empty(v_user.admin)        AS is_admin,
      position(upper('EelKoostaja') in upper(v_user.muud)) > 0 as is_eel_koostaja,
      position(upper('EelAllkirjastaja') in upper(v_user.muud)) > 0 as is_eel_allkirjastaja,
      position(upper('Eelesitaja') in upper(v_user.muud)) > 0 as is_eel_esitaja,
      position(upper('EelAktsepterja') in upper(v_user.muud)) > 0 as is_eel_aktsepterja

    INTO v_params;

    raise notice 'v_params %',v_params.is_kasutaja;

    SELECT row_to_json(row)
    INTO json_object
    FROM (SELECT
            coalesce(user_id, 0) AS id,
            TRUE                 AS import,
            v_params             AS data) row;

    SELECT ou.sp_salvesta_userid(json_object :: JSON, 1, v_user.rekvid)
    INTO user_id;
    RAISE NOTICE 'import dokprop lib_id %, l_count %', user_id, l_count;

    IF empty(user_id)
    THEN
      RAISE EXCEPTION 'Dokprop not saved json_object %', json_object;
    END IF;

    -- salvestame log info
    SELECT row_to_json(row)
    INTO hist_object
    FROM (SELECT now() AS timestamp) row;

    IF log_id IS NULL OR empty(log_id)
    THEN
      INSERT INTO import_log (new_id, old_id, lib_name, params, history)
      VALUES (user_id, v_user.id, 'USERID', json_object :: JSON, hist_object :: JSON)
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

    -- check user account
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
SELECT import_userid(id) from userid

*/