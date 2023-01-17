DROP FUNCTION IF EXISTS paranda_asutused(INTEGER);

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
    SERVER db_raama
    OPTIONS (SCHEMA_NAME 'libs', TABLE_NAME 'asutus');


CREATE OR REPLACE FUNCTION paranda_asutused(in_old_id INTEGER DEFAULT NULL::INTEGER)
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
                 INNER JOIN palk.tooleping t ON t.parentid = a.id
        WHERE (a.id = in_old_id OR in_old_id IS NULL)
          AND coalesce(t.lopp, '2022-12-31') > '2022-01-01'::DATE
          AND a.staatus < 3
        LIMIT ALL
        LOOP
            RAISE NOTICE 'check for lib.. v_asutus.id -> %', v_asutus.id;
            -- сохранение

            -- расч. счета
            l_asutus_aa = v_asutus.properties -> 'asutus_aa';
            l_uus_asutus_aa = '[]'::JSONB;
            IF l_asutus_aa IS NOT NULL
            THEN
                FOR i IN 0..jsonb_array_length(l_asutus_aa)
                    LOOP
                        l_aa = (l_asutus_aa -> i);
                        IF l_aa IS NOT NULL
                        THEN
                            l_uus_asutus_aa = coalesce(l_uus_asutus_aa, '[]'::JSONB) || coalesce(l_aa, '{}'::JSONB);
                        END IF;
                        RAISE NOTICE 'l_aa %',l_aa;
                    END LOOP;
            END IF;

            RAISE NOTICE 'update';
            UPDATE libs.asutus
            SET nimetus    = v_asutus.nimetus,
                properties = coalesce(properties, '{}'::JSONB) || coalesce(v_asutus.properties, '{}')::JSONB ||
                             jsonb_build_object('asutus_aa', l_uus_asutus_aa)
            WHERE id = v_asutus.id;

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

SELECT paranda_asutused();

--DROP FUNCTION IF EXISTS paranda_asutused(INTEGER);

