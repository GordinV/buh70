DROP FUNCTION IF EXISTS import_to_new_asutus_osakonnad(INTEGER);
DROP FUNCTION IF EXISTS import_to_new_asutus_osakonnad();

CREATE OR REPLACE FUNCTION import_to_new_asutus_osakonnad()
    RETURNS INTEGER AS
$BODY$
DECLARE
    osakond_id  INTEGER;
    log_id      INTEGER;
    v_osakond   RECORD;
    json_object JSONB;
    hist_object JSONB;
    v_params    RECORD;
    l_count     INTEGER = 0;
    l_user_id   INTEGER = (SELECT id
                           FROM ou.userid
                           WHERE rekvid = 132
                             AND kasutaja = 'vlad'
                           LIMIT 1);
BEGIN
    -- выборка из "старого меню"

    FOR v_osakond IN
        SELECT l.*
        FROM library l
                 INNER JOIN rekv ON rekv.id = l.rekvid AND rekv.parentid < 999
        WHERE l.library = 'OSAKOND'
          AND l.rekvid = 64
          AND kood <> 'SAA'
        LIMIT ALL
        LOOP

            SELECT id INTO osakond_id
            FROM libs.library
            WHERE rekvid = 132
              AND kood = v_osakond.kood
              AND library.library = v_osakond.library
              AND status <> 3
            LIMIT 1;
            -- преобразование и получение параметров
            -- сохранение
            SELECT coalesce(osakond_id, 0) AS id,
                   v_osakond.kood,
                   v_osakond.nimetus,
                   v_osakond.library,
                   v_osakond.tun1,
                   v_osakond.tun2,
                   v_osakond.tun3,
                   v_osakond.tun4,
                   v_osakond.tun5,
                   v_osakond.muud          AS muud
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(osakond_id, 0) AS id,
                         TRUE                    AS import,
                         v_params                AS data) row;

            SELECT libs.sp_salvesta_library(json_object :: JSON, l_user_id, 132) INTO osakond_id;
            RAISE NOTICE 'lib_id %, l_count %', osakond_id, l_count;

            -- salvestame log info
            SELECT row_to_json(row) INTO hist_object
            FROM (SELECT now() AS timestamp) row;

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


/*
SELECT import_to_new_asutus_osakonnad()

select * from libs.library where rekvid = 132

select * from ou.rekv where nimetus like 'Narva Sotsiaaltöökeskus%'

update ou.rekv set status = 3 where id = 5


*/