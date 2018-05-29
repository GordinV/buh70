DROP FUNCTION IF EXISTS import_eel_config( );

CREATE OR REPLACE FUNCTION import_eel_config()
  RETURNS INTEGER AS
$BODY$
DECLARE
  lib_id           INTEGER;
  log_id           INTEGER;
  v_nom            RECORD;
  json_object      JSONB;
  hist_object      JSONB;
  json_kassakontod JSONB;
  json_kassakulud  JSONB;
  json_kulukontod  JSONB;
  json_kassatulud  JSONB;
  json_tulukontod  JSONB;
BEGIN
  -- выборка из "старого меню"
  json_kassakontod = (SELECT row_to_json(row)
                      FROM (SELECT ((SELECT array_agg(row_to_json(library.*))
                                     FROM (SELECT
                                             0 AS id,
                                             kood,
                                             library,
                                             nimetus,
                                             muud
                                           FROM library
                                           WHERE library = 'KASSAKONTOD') AS library
                      )) AS kassaKontod) row);


  json_kassakulud = (SELECT row_to_json(row)
                     FROM (SELECT ((SELECT array_agg(row_to_json(library.*))
                                    FROM (SELECT
                                            0 AS id,
                                            kood,
                                            library,
                                            nimetus,
                                            muud
                                          FROM library
                                          WHERE library = 'KASSAKULUD') AS library
                     )) AS kassaKulud) row);


  json_kulukontod = (SELECT row_to_json(row)
                     FROM (SELECT ((SELECT array_agg(row_to_json(library.*))
                                    FROM (SELECT
                                            0 AS id,
                                            kood,
                                            library,
                                            nimetus,
                                            muud
                                          FROM library
                                          WHERE library = 'KULUKONTOD') AS library
                     )) AS kuluKontod) row);

  json_kassatulud = (SELECT row_to_json(row)
                     FROM (SELECT ((SELECT array_agg(row_to_json(library.*))
                                    FROM (SELECT
                                            0 AS id,
                                            kood,
                                            library,
                                            nimetus,
                                            muud
                                          FROM library
                                          WHERE library = 'KASSATULUD') AS library
                     )) AS kassaTulud) row);

  json_tulukontod = (SELECT row_to_json(row)
                     FROM (SELECT ((SELECT array_agg(row_to_json(library.*))
                                    FROM (SELECT
                                            0 AS id,
                                            kood,
                                            library,
                                            nimetus,
                                            muud
                                          FROM library
                                          WHERE library = 'TULUKONTOD') AS library
                     )) AS tuluKontod) row);

  RAISE NOTICE 'json_kassakontod %, json_tulukontod %', json_kassakontod, json_tulukontod;

  -- преобразование и получение параметров
  json_object = (json_kassakontod || json_kulukontod || json_kassatulud || json_tulukontod || json_kassakulud) :: JSONB;
  -- сохранение

  RAISE NOTICE 'json_object %', json_object;

  DELETE FROM import_log
  WHERE lib_name = 'EEL_CONFIG';

  SELECT eelarve.sp_salvesta_eel_config(json_object :: JSON, 1, 1)
  INTO lib_id;
  RAISE NOTICE 'lib_id % ', lib_id;

  -- salvestame log info
  SELECT row_to_json(row)
  INTO hist_object
  FROM (SELECT now() AS timestamp) row;

  INSERT INTO import_log (new_id, old_id, lib_name, params, history)
  VALUES (lib_id, 1, 'EEL_CONFIG', json_object :: JSON, hist_object :: JSON)
  RETURNING id
    INTO log_id;

  IF empty(log_id)
  THEN
    RAISE EXCEPTION 'log save failed';
  END IF;
  -- control
  IF (SELECT count(id)
      FROM libs.library l
      WHERE l.library IN ('KASSAKONTOD', 'TULUKONTOD', 'KASSATULUD', 'KULUKONTOD', 'KASSAKULUD') AND status < 3)
     >= (SELECT count(id)
         FROM library
         WHERE library IN ('KASSAKONTOD', 'TULUKONTOD', 'KASSATULUD', 'KULUKONTOD', 'KASSAKULUD'))
  THEN
    RAISE NOTICE 'Import ->ok';
  ELSE
    RAISE EXCEPTION 'Import failed, new_count < old_count ';
  END IF;


  RETURN 1;

  EXCEPTION WHEN OTHERS
  THEN
    RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
    RETURN 0;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

SELECT import_eel_config()

/*
SELECT import_eel_config()

*/