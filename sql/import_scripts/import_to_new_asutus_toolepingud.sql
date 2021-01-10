DROP FUNCTION IF EXISTS import_to_new_asutus_tooleping();

CREATE OR REPLACE FUNCTION import_to_new_asutus_tooleping()
    RETURNS INTEGER AS
$BODY$
DECLARE
    leping_id    INTEGER;
    v_leping     RECORD;
    json_object  JSONB;
    v_params     RECORD;
    l_count      INTEGER = 0;
    l_osakond_id INTEGER;
    l_amet_id    INTEGER;
    l_asutus_id  INTEGER;
    l_user_id    INTEGER = (SELECT id
                            FROM ou.userid
                            WHERE rekvid = 132
                              AND kasutaja = 'vlad'
                                LIMIT 1);
    v_tootaja    RECORD;
BEGIN
    -- выборка из "старого меню"

    FOR v_leping IN
        SELECT t.*,
               o.kood AS osakond,
               a.kood AS amet
        FROM tooleping t
                 INNER JOIN library o ON o.id = t.osakondid
                 INNER JOIN library a ON a.id = t.ametid
        WHERE t.rekvid = 64
          AND t.osakondid NOT IN (SELECT id FROM library WHERE rekvid = 64 AND library = 'OSAKOND' AND kood = 'SAA')
          AND (t.lopp IS NULL
            OR t.lopp > current_date)
            LIMIT ALL
        LOOP

            l_osakond_id = (SELECT id
                            FROM libs.library l
                            WHERE rekvid = 132
                              AND kood = v_leping.osakond
                              AND library = 'OSAKOND'
                              AND status <> 3
                                LIMIT 1);

            l_amet_id = (SELECT id
                         FROM libs.library l
                         WHERE rekvid = 132
                           AND kood = v_leping.amet
                           AND library = 'AMET'
                           AND status <> 3
                             LIMIT 1);

            l_asutus_id = (SELECT new_id
                           FROM import_log
                           WHERE old_id = v_leping.parentid
                             AND lib_name = 'ASUTUS');

            IF l_osakond_id IS NULL OR l_amet_id IS NULL OR l_asutus_id IS NULL
            THEN
                RAISE NOTICE 'amet or osakond not found v_leping.osakondid %,l_osakond_id %, v_leping.ametid %, l_amet_id %, v_leping.parentid %,  l_asutus_id %', v_leping.osakondid, l_osakond_id, v_leping.ametid, l_amet_id, v_leping.parentid, l_asutus_id;
            ELSE
                -- преобразование и получение параметров

                SELECT id INTO leping_id
                FROM palk.tooleping
                WHERE parentid = l_asutus_id
                  AND osakondid = l_osakond_id
                  AND ametid = l_amet_id
                  AND status <> 3
                    LIMIT 1;

                IF leping_id IS NULL
                THEN

                    -- сохранение
                    SELECT 0             AS id,
                           l_asutus_id   AS parentid,
                           l_osakond_id  AS osakondid,
                           l_amet_id     AS ametid,
                           v_leping.algab,
                           v_leping.lopp,
                           v_leping.palk,
                           v_leping.palgamaar,
                           v_leping.resident,
                           v_leping.riik,
                           v_leping.toend,
                           v_leping.koormus,
                           v_leping.toopaev,
                           v_leping.ametnik,
                           v_leping.tasuliik,
                           v_leping.muud AS muud
                           INTO v_params;

                    SELECT row_to_json(row) INTO json_object
                    FROM (SELECT 0        AS id,
                                 TRUE     AS import,
                                 v_params AS data) row;

                    SELECT palk.sp_salvesta_tooleping(json_object :: JSON, l_user_id, 132) INTO leping_id;
                    RAISE NOTICE 'leping_id %, l_count %', leping_id, l_count;

                    l_count = l_count + 1;
                END IF;
            END IF;

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
SELECT import_to_new_asutus_tooleping()

select * from palk.tooleping where rekvid  = 132
select * from palk.tooleping where rekvid  = 132 and lopp is not null and lopp < current_date
select * from library where id = 60413


select * from libs.asutus where regkood = '47504222225 '

select * from palk.tooleping where parentid = 21087
*/
