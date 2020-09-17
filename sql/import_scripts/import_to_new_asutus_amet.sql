DROP FUNCTION IF EXISTS import_to_new_asutus_amet();

DROP FOREIGN TABLE IF EXISTS remote_palk_asutus;

CREATE FOREIGN TABLE remote_palk_asutus (
    id INTEGER NOT NULL,
    rekvid INTEGER NOT NULL,
    osakondid INTEGER DEFAULT 0 NOT NULL,
    ametid INTEGER DEFAULT 0 NOT NULL,
    kogus NUMERIC(18, 2) DEFAULT 0 NOT NULL,
    vaba NUMERIC(18, 2) DEFAULT 0 NOT NULL,
    palgamaar INTEGER DEFAULT 0 NOT NULL,
    muud TEXT,
    tunnusid BIGINT DEFAULT 0 NOT NULL,
    vanaid INTEGER
    ) SERVER db_narva_ee
    OPTIONS (SCHEMA_NAME 'public', TABLE_NAME 'palk_asutus');


CREATE OR REPLACE FUNCTION import_to_new_asutus_amet()
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
    l_osakondid INTEGER;
    l_tunnusid  INTEGER;
    l_user_id   INTEGER = (SELECT id
                           FROM ou.userid
                           WHERE rekvid = 132
                             AND kasutaja = 'vlad'
                           LIMIT 1);

BEGIN
    -- выборка из "старого меню"

    FOR v_lib IN
        SELECT l.id,
               l.kood,
               l.nimetus,
               l.library,
               l.muud,
               pa.rekvid,
               pa.osakondid,
               pa.ametid,
               pa.kogus,
               (CASE
                    WHEN empty(pa.palgamaar)
                        THEN NULL
                    ELSE pa.palgamaar END) :: INTEGER AS palgamaar,
               (CASE
                    WHEN empty(pa.tunnusid)
                        THEN NULL
                    ELSE pa.tunnusid END) :: INTEGER  AS tunnusid,
               o.kood                                 AS osakond
        FROM library l
                 INNER JOIN remote_palk_asutus pa ON pa.ametid = l.id
                 INNER JOIN library o ON o.id = pa.osakondid
        WHERE l.library = 'AMET'
          AND l.rekvid = 64
          AND o.kood <> 'SAA'
        LIMIT ALL
        LOOP

            -- поиск osakond_id
            SELECT id INTO l_osakondid
            FROM libs.library l
            WHERE library = 'OSAKOND'
              AND rekvid = 132
              AND kood = v_lib.osakond
            LIMIT 1;

            IF l_osakondid IS NULL
            THEN
                RAISE EXCEPTION 'Osakond not found osakondid-> %', v_lib.osakondid;
            END IF;

            -- amet_id
            SELECT id INTO lib_id
            FROM libs.library
            WHERE library.library = 'AMET'
              AND rekvid = 132
              AND kood = v_lib.kood
              AND status <> 3
            LIMIT 1;

            -- преобразование и получение параметров

            -- сохранение
            SELECT coalesce(lib_id, 0) AS id,
                   v_lib.kood          AS kood,
                   v_lib.nimetus       AS nimetus,
                   l_osakondid         AS osakondid,
                   NULL                AS tunnusid,
                   v_lib.kogus         AS kogus,
                   v_lib.palgamaar     AS palgamaar,
                   v_lib.muud          AS muud
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(lib_id, 0) AS id,
                         TRUE                AS import,
                         v_params            AS data) row;

            SELECT libs.sp_salvesta_amet(json_object :: JSON, l_user_id, 132) INTO lib_id;
            IF lib_id IS NOT NULL AND NOT empty(lib_id)
            THEN

                l_count = l_count + 1;
            END IF;

            RAISE NOTICE 'lib_id %, l_count %', lib_id, l_count;

        END LOOP;

    RAISE NOTICE 'Import ->ok';

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
SELECT import_to_new_asutus_amet()
*/