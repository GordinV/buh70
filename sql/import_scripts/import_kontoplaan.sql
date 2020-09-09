DROP FUNCTION IF EXISTS import_kontoplaan();
DROP FUNCTION IF EXISTS import_kontoplaan(BOOLEAN);

drop SERVER if exists test2_narva_ee CASCADE ;
CREATE SERVER test2_narva_ee FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'dbarch.narva.ee', dbname 'test2', port '5436');


CREATE OR REPLACE FUNCTION import_kontoplaan(in_old_id INTEGER)
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
    v_lib_new   RECORD;
BEGIN
    -- выборка из "старого меню"
    FOR v_lib IN
        SELECT l.*,
               k.type,
               CASE
                   WHEN k.aasta > 2999
                       THEN k.aasta
                   ELSE NULL END AS valid
        FROM library l
                 LEFT OUTER JOIN remote_kontoinf k ON k.parentid = l.id AND k.rekvid = 63
        WHERE l.library = 'KONTOD'
          AND (l.id = in_old_id OR in_old_id IS NULL)
        LIMIT ALL
        LOOP
            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
                   INTO lib_id, log_id
            FROM import_log
            WHERE old_id = v_lib.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = upper(ltrim(rtrim(v_lib.library :: TEXT)));

            RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_lib.id, lib_id, log_id;

            -- преобразование и получение параметров

            -- сохранение
            SELECT coalesce(lib_id, 0) AS id,
                   v_lib.kood          AS kood,
                   v_lib.nimetus       AS nimetus,
                   v_lib.library       AS library,
                   v_lib.tun1          AS tun1,
                   v_lib.tun2          AS tun2,
                   v_lib.tun3          AS tun3,
                   v_lib.tun4          AS tun4,
                   v_lib.tun5          AS tun5,
                   v_lib.valid         AS valid,
                   v_lib.type          AS tyyp,
                   v_lib.muud          AS muud,
                   TRUE                AS import
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(lib_id, 0) AS id,
                         v_params            AS data,
                         TRUE                AS import) row;

            SELECT libs.sp_salvesta_konto(json_object :: JSON, 1, 63) INTO lib_id;
            RAISE NOTICE 'lib_id %, l_count %', lib_id, l_count;

            IF empty(lib_id)
            THEN
                RAISE EXCEPTION 'lib_id is empty';
            END IF;

            -- salvestame log info
            SELECT row_to_json(row) INTO hist_object
            FROM (SELECT now() AS timestamp) row;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name, params, history)
                VALUES (lib_id, v_lib.id, v_lib.library, json_object :: JSON, hist_object :: JSON) RETURNING id
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
            l_count = l_count + 1;
        END LOOP;
    /*
      -- control
      IF (SELECT count(id)
          FROM libs.library
          WHERE LIBRARY = 'KONTOD')
        >= l_count
      THEN
        RAISE NOTICE 'Import ->ok';
      ELSE
        RAISE EXCEPTION 'Import failed, new_count < old_count %', l_count;

      END IF;
    */

    RETURN l_count;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN 0;

END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


/*
SELECT import_kontoplaan()

SELECT ou.sp_salvesta_menupohi('{"id":4,"data":{"pad":"test","bar":"","idx":1,"name":"Test", "vene": "Тест", "eesti": "Testid", "level": 1, "users": ["vlad"], "groups": ["KASUTAJA", "PEAKASUTAJA"], "modules": ["EELARVE"]}}'
,1, 1)

select * from ou.menupohi

select * from libs.library where kood = '10300011'
select * from remote_library where kood = '10300011'

SELECT import_kontoplaan(id) from (
                                    SELECT id
                                    FROM remote_library
                                    WHERE library = 'KONTOD'
                                      EXCEPT
                                    SELECT old_id
                                    FROM import_log
                                    WHERE lib_name = 'KONTOD'
                                  ) qry


                                    SELECT count(id)
                                    FROM remote_library
                                    WHERE library = 'KONTOD'
                                      EXCEPT
                                    SELECT count(old_id)
                                    FROM import_log
                                    WHERE lib_name = 'KONTOD'

*/

