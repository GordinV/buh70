DROP FUNCTION IF EXISTS import_userid(INTEGER);

DROP FOREIGN TABLE IF EXISTS remote_userid;
CREATE FOREIGN TABLE remote_userid (

    id INTEGER NOT NULL,
    rekvid INTEGER NOT NULL,
    kasutaja CHAR(50) NOT NULL,
    ametnik CHAR(254) NOT NULL,
    parool TEXT,
    kasutaja_ INTEGER DEFAULT 1 NOT NULL,
    peakasutaja_ INTEGER DEFAULT 0 NOT NULL,
    admin INTEGER DEFAULT 0 NOT NULL,
    properties JSONB,
    roles JSONB,
    status INT,
    muud TEXT )
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'ou', TABLE_NAME 'userid');

CREATE OR REPLACE FUNCTION import_userid(in_old_id INTEGER DEFAULT NULL::INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    user_id INTEGER;
    log_id  INTEGER;
    v_user  RECORD;
    l_count INTEGER = 0;
BEGIN
    -- выборка из "старого меню"

    FOR v_user IN
        SELECT u.*
        FROM remote_userid u
        WHERE (u.id = in_old_id OR in_old_id IS NULL)
          AND status < 3
        LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
            INTO user_id, log_id
            FROM import_log
            WHERE old_id = v_user.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'USERID';

            IF user_id IS NULL
            THEN
                -- нет в логах, ищем в бд
                SELECT id
                INTO user_id
                FROM ou.userid
                WHERE rekvid = v_user.rekvid
                  AND ltrim(rtrim(kasutaja)) = ltrim(rtrim(v_user.kasutaja))
                  AND status < 3
                ORDER BY id DESC
                LIMIT 1;

                IF user_id IS NOT NULL AND
                   NOT exists(SELECT id FROM import_log WHERE new_id = user_id AND lib_name = 'USERID')
                THEN
                    --not found in logs, then insert
                    INSERT INTO import_log (new_id, old_id, lib_name)
                    VALUES (user_id, v_user.id, 'USERID') RETURNING id INTO log_id;
                END IF;
            END IF;


            RAISE NOTICE 'check for lib.. v_user.id -> %, found -> % log_id -> %', v_user.id, user_id, log_id;

            -- сохранение

            IF user_id IS NULL
            THEN
                INSERT INTO ou.userid (rekvid, kasutaja, ametnik, parool, kasutaja_, peakasutaja_, admin, muud,
                                       properties, roles, status)
                VALUES (v_user.rekvid, v_user.kasutaja, v_user.ametnik, v_user.parool, v_user.kasutaja_,
                        v_user.peakasutaja_, v_user.admin, v_user.muud,
                        v_user.properties, v_user.roles, 1) RETURNING id INTO user_id;

            ELSE
                UPDATE ou.userid
                SET properties = properties || v_user.properties,
                    roles      = roles || v_user.roles
                WHERE id = user_id;
            END IF;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name)
                VALUES (user_id, v_user.id, 'USERID') RETURNING id INTO log_id;
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

SELECT import_userid();
DROP FUNCTION IF EXISTS import_userid(INTEGER);

