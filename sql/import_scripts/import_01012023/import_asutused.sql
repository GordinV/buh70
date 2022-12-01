DROP FUNCTION IF EXISTS import_asutused(INTEGER);

DROP FOREIGN TABLE IF EXISTS remote_asutus;
CREATE FOREIGN TABLE remote_asutus (

    id INTEGER NOT NULL,
    rekvid INTEGER ,
    regkood CHAR(20),
    nimetus CHAR(254),
    omvorm CHAR(20),
    aadress TEXT,
    kontakt TEXT ,
    tel CHAR(60),
    faks CHAR(60),
    email CHAR(60),
    muud TEXT,
    tp VARCHAR(20),
    staatus INTEGER DEFAULT 1,
    mark TEXT,
    timestamp TIME ,
    properties JSONB,
    ajalugu JSONB
    )
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'libs', TABLE_NAME 'asutus');

DROP FOREIGN TABLE IF EXISTS remote_vanem;
CREATE FOREIGN TABLE remote_vanem (

    id INTEGER NOT NULL,
    parentid INTEGER,
    asutusid INTEGER,
    properties JSONB,
    ajalugu JSONB,
    timestamp TIMESTAMP,
    staatus INTEGER,
    muud TEXT )
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'lapsed', TABLE_NAME 'vanemad');

DROP FOREIGN TABLE IF EXISTS remote_vanem_arveldus;
CREATE FOREIGN TABLE remote_vanem_arveldus (

    id INTEGER NOT NULL,
    parentid INTEGER,
    asutusid INTEGER,
    rekvid INTEGER,
    arveldus BOOLEAN,
    properties JSONB)
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'lapsed', TABLE_NAME 'vanem_arveldus');


CREATE OR REPLACE FUNCTION import_asutused(in_old_id INTEGER DEFAULT NULL::INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    l_asutus_id     INTEGER;
    log_id          INTEGER;
    v_asutus        RECORD;
    l_count         INTEGER = 0;
    l_lib           TEXT    = 'ASUTUS';
    v_vanem         RECORD;
    l_asutus_aa     JSONB;
    l_uus_asutus_aa JSONB;
    l_aa            JSONB;
BEGIN
    -- выборка из "старого меню"

    FOR v_asutus IN
        SELECT a.*
        FROM remote_asutus a
        WHERE (a.id = in_old_id OR in_old_id IS NULL)
          AND (a.id IN (SELECT DISTINCT asutusid FROM remote_vanem v) OR in_old_id IS NOT NULL)
          AND staatus < 3
        LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
            INTO l_asutus_id, log_id
            FROM import_log
            WHERE old_id = v_asutus.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = l_lib;

            IF l_asutus_id IS NULL
            THEN
                -- нет в логах, ищем в бд
                SELECT id
                INTO l_asutus_id
                FROM libs.asutus a
                WHERE a.regkood = v_asutus.regkood
                  AND staatus < 3
                ORDER BY id DESC
                LIMIT 1;

                IF l_asutus_id IS NOT NULL AND
                   NOT exists(SELECT id FROM import_log WHERE new_id = l_asutus_id AND lib_name = l_lib)
                THEN
                    --not found in logs, then insert
                    INSERT INTO import_log (new_id, old_id, lib_name)
                    VALUES (l_asutus_id, v_asutus.id, l_lib) RETURNING id INTO log_id;
                END IF;
            END IF;


            RAISE NOTICE 'check for lib.. v_asutus.id -> %, found -> % log_id -> %', v_asutus.id, l_asutus_id, log_id;

            -- сохранение

            -- расч. счета
            l_asutus_aa = v_asutus.properties -> 'asutus_aa';
            l_uus_asutus_aa = '[]'::JSONB;
            IF l_asutus_aa IS NOT NULL
            THEN
                FOR i IN 0..jsonb_array_length(l_asutus_aa)
                    LOOP
                        l_aa = (l_asutus_aa -> i) || jsonb_build_object('kas_oppetasu', 1);
                        l_uus_asutus_aa = coalesce(l_uus_asutus_aa, '[]'::JSONB) || coalesce(l_aa, '{}'::JSONB);
                        RAISE NOTICE 'l_aa %',l_aa;
                    END LOOP;
            END IF;

            IF l_asutus_id IS NULL
            THEN
                RAISE NOTICE 'insert';
                INSERT INTO libs.asutus (rekvid, regkood, nimetus, omvorm, aadress, kontakt, tel, faks, email, muud, tp,
                                         staatus, mark, timestamp, properties, ajalugu)
                VALUES (v_asutus.rekvid, v_asutus.regkood, v_asutus.nimetus, v_asutus.omvorm, v_asutus.aadress,
                        v_asutus.kontakt, v_asutus.tel, v_asutus.faks, v_asutus.email,
                        v_asutus.muud, v_asutus.tp, v_asutus.staatus, v_asutus.mark, v_asutus.timestamp,
                        v_asutus.properties, v_asutus.ajalugu) RETURNING id INTO l_asutus_id;

            ELSE
                RAISE NOTICE 'update';
                UPDATE libs.asutus
                SET nimetus    = v_asutus.nimetus,
                    omvorm     = v_asutus.omvorm,
--                    aadress    = v_asutus.aadress,
                    kontakt    = v_asutus.kontakt,
                    tel        = v_asutus.tel,
                    faks       = v_asutus.faks,
                    email      = v_asutus.email,
                    muud       = v_asutus.muud,
                    tp         = v_asutus.tp,
                    staatus= v_asutus.staatus,
                    mark       = v_asutus.mark,
                    properties = coalesce(properties, '{}'::JSONB) || coalesce(v_asutus.properties, '{}')::JSONB ||
                                 jsonb_build_object('asutus_aa', l_uus_asutus_aa),
                    ajalugu    = ajalugu || v_asutus.ajalugu
                WHERE id = l_asutus_id;
            END IF;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name)
                VALUES (l_asutus_id, v_asutus.id, l_lib) RETURNING id INTO log_id;
            END IF;


            -- правим asutusid в vanemad, vanem_

            UPDATE lapsed.vanemad SET asutusid = l_asutus_id WHERE asutusid = v_asutus.id;
            UPDATE lapsed.vanem_arveldus SET asutusid = l_asutus_id WHERE asutusid = v_asutus.id;

            -- добавим прощенный родителей
            FOR v_vanem IN
                SELECT v.*
                FROM remote_vanem v
                inner join lapsed.laps l on l.id = v.parentid
                WHERE v.asutusid = v_asutus.id
                  AND v.staatus < 3

                LOOP
                    IF NOT exists(
                            SELECT id
                            FROM lapsed.vanemad
                            WHERE asutusid = l_asutus_id
                              AND parentid = v_vanem.parentid
--                              AND staatus < 3
                        )
                    THEN

--                        delete from lapsed.vanemad where parentid = v_vanem.parentid and asutusid = l_asutus_id;

                        INSERT INTO lapsed.vanemad (parentid, asutusid, properties, ajalugu, staatus, muud)
                        SELECT v_vanem.parentid,
                               l_asutus_id,
                               v_vanem.properties,
                               v_vanem.ajalugu,
                               v_vanem.staatus,
                               v_vanem.muud
                        FROM remote_vanem
                        WHERE id = v_vanem.id
                          AND NOT exists(SELECT id
                                         FROM lapsed.vanemad
                                         WHERE parentid = v_vanem.parentid AND asutusid = l_asutus_id);

--                        DELETE FROM lapsed.vanem_arveldus WHERE parentid = v_vanem.parentid AND asutusid = l_asutus_id;

                        INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus, properties)
                        SELECT parentid, l_asutus_id, rekvid, arveldus, properties
                        FROM remote_vanem_arveldus
                        WHERE asutusid = v_vanem.asutusid
                          AND parentid = v_vanem.parentid
                        and not exists (select id from lapsed.vanem_arveldus where parentid = v_vanem.parentid and asutusid = l_asutus_id)
                        ;

                    END IF;

                END LOOP;


            IF empty(log_id)
            THEN
                RAISE EXCEPTION 'log save failed';
            END IF;
            RAISE NOTICE 'finnish';
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

SELECT import_asutused(id)
FROM (SELECT DISTINCT asutusid AS id
      FROM remote_vanem
      WHERE staatus < 3
        AND asutusid NOT IN (37433, 8575)
     ) qry
--WHERE id = 45450
LIMIT ALL;
-- 45450

DROP FUNCTION IF EXISTS import_asutused(INTEGER);

