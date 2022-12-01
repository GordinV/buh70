DROP FUNCTION IF EXISTS import_libs(INTEGER);

DROP FOREIGN TABLE IF EXISTS remote_library;
CREATE FOREIGN TABLE remote_library (

    id INTEGER NOT NULL,
    rekvid INTEGER ,
    kood CHAR(20),
    nimetus CHAR(254),
    library CHAR(20),
    muud TEXT,
    tun1 INTEGER,
    tun2 INTEGER,
    tun3 INTEGER,
    tun4 INTEGER,
    tun5 INTEGER,
    properties TEXT,
    status INTEGER
    )
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'libs', TABLE_NAME 'library');

DROP FOREIGN TABLE IF EXISTS remote_day_taabel;
CREATE FOREIGN TABLE remote_day_taabel (

    id INTEGER NOT NULL,
    kpv DATE,
    rekv_id INTEGER,
    grupp_id INTEGER,
    ajalugu JSONB,
    timestamp TIMESTAMP,
    staatus INTEGER ,
    muud TEXT,
    properties JSONB)
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'lapsed', TABLE_NAME 'day_taabel');


CREATE OR REPLACE FUNCTION import_libs(in_old_id INTEGER DEFAULT NULL::INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    l_lib_id INTEGER;
    log_id   INTEGER;
    v_lib    RECORD;
    l_count  INTEGER = 0;
    l_lib    TEXT    = 'LIBRARY';
BEGIN
    -- выборка из "старого меню"

    FOR v_lib IN
        SELECT l.*
        FROM remote_library l
        WHERE (l.id = in_old_id OR in_old_id IS NULL)
          AND l.library IN ('ASUTUSE_LIIK', 'KOOLITUSE_LIIK', 'KOOLITUSE_TYYP', 'LAPSE_GRUPP')
          AND status < 3
        LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
            INTO l_lib_id, log_id
            FROM import_log
            WHERE old_id = v_lib.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = l_lib;

            IF l_lib_id IS NULL
            THEN
                -- нет в логах, ищем в бд
                SELECT id
                INTO l_lib_id
                FROM libs.library l
                WHERE rekvid = v_lib.rekvid
                  AND ltrim(rtrim(l.kood)) = ltrim(rtrim(v_lib.kood))
                  AND ltrim(rtrim(l.library)) = ltrim(rtrim(v_lib.library))
                  AND status < 3
                ORDER BY id DESC
                LIMIT 1;

                IF l_lib_id IS NOT NULL AND
                   NOT exists(SELECT id FROM import_log WHERE new_id = l_lib_id AND lib_name = l_lib)
                THEN
                    --not found in logs, then insert
                    INSERT INTO import_log (new_id, old_id, lib_name)
                    VALUES (l_lib_id, v_lib.id, l_lib) RETURNING id INTO log_id;
                END IF;
            END IF;


            RAISE NOTICE 'check for lib.. v_lib.id -> %, found -> % log_id -> %', v_lib.id, l_lib_id, log_id;

            -- сохранение

            IF l_lib_id IS NULL
            THEN
                INSERT INTO libs.library (rekvid, kood, nimetus, library, muud, tun1, tun2, tun3, tun4, tun5,
                                          properties, status)
                VALUES (v_lib.rekvid, v_lib.kood, v_lib.nimetus, v_lib.library, v_lib.muud, v_lib.tun1, v_lib.tun2,
                        v_lib.tun3, v_lib.tun4,
                        v_lib.tun5, v_lib.properties, v_lib.status) RETURNING id INTO l_lib_id;

            ELSE
                UPDATE libs.library
                SET nimetus    = v_lib.nimetus,
                    kood       = v_lib.kood,
                    tun1       = v_lib.tun1,
                    tun2       = v_lib.tun2,
                    tun3       = v_lib.tun3,
                    tun4       = v_lib.tun4,
                    tun5       = v_lib.tun5,
                    muud       = v_lib.muud,
                    status     = v_lib.status,
                    properties = v_lib.properties
                WHERE id = l_lib_id;
            END IF;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name)
                VALUES (l_lib_id, v_lib.id, l_lib) RETURNING id INTO log_id;
            END IF;

            -- правим nomid в картах, табелях
            IF v_lib.library = 'LAPSE_GRUPP'
            THEN
                UPDATE lapsed.day_taabel
                SET grupp_id = l_lib_id
                WHERE id IN (
                    SELECT id
                    FROM remote_day_taabel
                    WHERE grupp_id = v_lib.id
                )
                  AND staatus < 3;
            END IF;

            IF empty(log_id)
            THEN
                RAISE EXCEPTION 'log save failed';
            END IF;

            -- check user account
            l_count = l_count + 1;
        END LOOP;

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

SELECT import_libs();
DROP FUNCTION IF EXISTS import_libs(INTEGER);

