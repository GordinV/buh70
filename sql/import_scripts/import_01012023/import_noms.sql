DROP FUNCTION IF EXISTS import_nomenklatuur(INTEGER);

DROP FOREIGN TABLE IF EXISTS remote_nomenklatuur;
CREATE FOREIGN TABLE remote_nomenklatuur (

    id INTEGER NOT NULL,
    rekvid INTEGER ,
    dok CHAR(20),
    kood CHAR(20),
    nimetus CHAR(254),
    uhik CHAR(20),
    hind NUMERIC(12, 4),
    muud TEXT,
    ulehind NUMERIC(12, 4),
    kogus NUMERIC(12, 3),
    formula TEXT,
    vanaid INTEGER,
    status INTEGER,
    properties JSONB)
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'libs', TABLE_NAME 'nomenklatuur');

DROP FOREIGN TABLE IF EXISTS remote_lapse_kaart;
CREATE FOREIGN TABLE remote_lapse_kaart (

    id INTEGER NOT NULL,
    parentid INTEGER,
    rekvid INTEGER,
    nomid INTEGER,
    hind NUMERIC(14, 4),
    tunnus VARCHAR(20),
    properties JSONB,
    ajalugu JSONB,
    staatus INTEGER,
    muud TEXT
    )
    SERVER db_lapsed
    OPTIONS (SCHEMA_NAME 'lapsed', TABLE_NAME 'lapse_kaart');

ALTER TABLE ou.logs
    ADD COLUMN IF NOT EXISTS changes JSONB NULL;



CREATE OR REPLACE FUNCTION import_nomenklatuur(in_old_id INTEGER DEFAULT NULL::INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    l_nom_id INTEGER;
    log_id   INTEGER;
    v_noms   RECORD;
    l_count  INTEGER = 0;
    l_lib    TEXT    = 'NOMENKLATUUR';
BEGIN
    -- выборка из "старого меню"

    FOR v_noms IN
        SELECT n.*
        FROM remote_nomenklatuur n
        WHERE (n.id = in_old_id OR in_old_id IS NULL)
          AND (n.id IN (SELECT DISTINCT nomid FROM remote_lapse_kaart lk) OR in_old_id IS NOT NULL)
          AND status < 3
        LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            SELECT new_id,
                   id
            INTO l_nom_id, log_id
            FROM import_log
            WHERE old_id = v_noms.id
              AND upper(ltrim(rtrim(lib_name :: TEXT))) = l_lib;

            IF l_nom_id IS NULL
            THEN
                -- нет в логах, ищем в бд
                SELECT id
                INTO l_nom_id
                FROM libs.nomenklatuur n
                WHERE rekvid = v_noms.rekvid
                  AND ltrim(rtrim(n.kood)) = ltrim(rtrim(v_noms.kood))
                  AND ltrim(rtrim(n.dok)) = ltrim(rtrim(v_noms.dok))
                  AND status < 3
                ORDER BY id DESC
                LIMIT 1;

                IF l_nom_id IS NOT NULL AND
                   NOT exists(SELECT id FROM import_log WHERE new_id = l_nom_id AND lib_name = l_lib)
                THEN
                    --not found in logs, then insert
                    INSERT INTO import_log (new_id, old_id, lib_name)
                    VALUES (l_nom_id, v_noms.id, l_lib) RETURNING id INTO log_id;
                END IF;
            END IF;


            RAISE NOTICE 'check for lib.. v_user.id -> %, found -> % log_id -> %', v_noms.id, l_nom_id, log_id;

            -- сохранение

            IF l_nom_id IS NULL
            THEN
                INSERT INTO libs.nomenklatuur (rekvid, dok, kood, nimetus, uhik, hind, muud, ulehind, kogus, formula,
                                               status, properties)
                VALUES (v_noms.rekvid, v_noms.dok, v_noms.kood, v_noms.nimetus, v_noms.uhik, v_noms.hind, v_noms.muud,
                        v_noms.ulehind,
                        v_noms.kogus, v_noms.formula, v_noms.status, v_noms.properties) RETURNING id INTO l_nom_id;

            ELSE
                UPDATE libs.nomenklatuur
                SET nimetus    = v_noms.nimetus,
                    uhik       = v_noms.uhik,
                    hind       = v_noms.hind,
                    muud       = v_noms.muud,
                    kogus      = v_noms.kogus,
                    status     = v_noms.status,
                    properties = v_noms.properties
                WHERE id = l_nom_id;
            END IF;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name)
                VALUES (l_nom_id, v_noms.id, l_lib) RETURNING id INTO log_id;
            END IF;

            -- правим nomid в картах, табелях

            UPDATE lapsed.lapse_kaart SET nomid = l_nom_id WHERE nomid = v_noms.id;
            UPDATE lapsed.lapse_taabel SET nomid = l_nom_id WHERE nomid = v_noms.id;
            UPDATE lapsed.day_taabel1 SET nom_id = l_nom_id WHERE nom_id = v_noms.id;


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

--SELECT import_nomenklatuur();
--DROP FUNCTION IF EXISTS import_nomenklatuur(INTEGER);

