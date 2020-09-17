DROP FUNCTION IF EXISTS import_to_new_asutus_palk_kaart();

CREATE OR REPLACE FUNCTION import_to_new_asutus_palk_kaart()
    RETURNS INTEGER AS
$BODY$
DECLARE
    pk_id       INTEGER;
    log_id      INTEGER;
    v_pk        RECORD;
    json_object JSONB;
    hist_object JSONB;
    v_params    RECORD;
    l_count     INTEGER = 0;
    l_asutus_id INTEGER;
    l_lib_id    INTEGER;
    l_tunnus    TEXT;
    l_leping_id INTEGER;
    l_user_id   INTEGER = (SELECT id
                           FROM ou.userid
                           WHERE rekvid = 132
                             AND kasutaja = 'vlad'
                           LIMIT 1);

BEGIN
    -- выборка из "старого меню"

    FOR v_pk IN
        SELECT pk.*,
               t.rekvid,
               l.kood AS palk_kood,
               o.kood AS osakond,
               a.kood AS amet,
               t.algab,
               t.lopp
        FROM remote_palk_kaart pk
                 INNER JOIN remote_tooleping t ON t.id = pk.lepingid
                 INNER JOIN library l ON pk.libid = l.id
                 INNER JOIN library o ON o.id = t.osakondid
                 INNER JOIN library a ON a.id = t.ametid
        WHERE t.rekvid = 64
          AND t.osakondid NOT IN (SELECT id FROM library WHERE rekvid = 64 AND library = 'OSAKOND' AND kood = 'SAA')
          AND (t.lopp IS NULL
            OR t.lopp > current_date)

        LIMIT ALL
        LOOP

            l_asutus_id = (SELECT new_id
                           FROM import_log
                           WHERE lib_name = 'ASUTUS'
                             AND old_id = v_pk.parentid);

            l_lib_id = (SELECT id
                        FROM libs.library l
                        WHERE l.rekvid = 132
                          AND library = 'PALK'
                          AND kood = v_pk.palk_kood
                          AND l.status <> 3
                        LIMIT 1);

            l_leping_id = (SELECT t.id
                           FROM palk.tooleping t
                                    INNER JOIN libs.library o ON o.id = t.osakondid
                                    INNER JOIN libs.library a ON a.id = t.ametid
                           WHERE t.rekvid = 132
                             AND t.parentid = l_asutus_id
                             AND o.kood = v_pk.osakond
                             AND a.kood = v_pk.amet
                             AND t.algab = v_pk.algab
                           LIMIT 1
            );

            IF
                l_asutus_id IS NULL OR l_lib_id IS NULL OR l_leping_id IS NULL
            THEN
                RAISE NOTICE 'data not found l_leping_id %, v_pk.parentid %, l_asutus_id %, v_pk.libid %, l_lib_id %', l_leping_id, v_pk.parentid, l_asutus_id, v_pk.libid, l_lib_id;

            ELSE
                -- преобразование и получение параметров

                -- сохранение
                SELECT 0                                           AS id,
                       l_asutus_id                                 AS parentid,
                       l_lib_id                                    AS libid,
                       l_leping_id                                 AS lepingid,
                       v_pk.summa,
                       v_pk.percent_,
                       v_pk.tulumaks,
                       v_pk.tulumaar,
                       v_pk.alimentid,
                       l_tunnus                                    AS tunnus,
                       v_pk.minsots,
                       v_pk.muud                                   AS muud,
                       CASE WHEN v_pk.status = 0 THEN 2 ELSE 1 END AS status
                       INTO v_params;

                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0        AS id,
                             TRUE     AS import,
                             v_params AS data) row;

                SELECT palk.sp_salvesta_palk_kaart(json_object :: JSON, l_user_id, 132) INTO pk_id;
                RAISE NOTICE 'pk_id %, l_count %', pk_id, l_count;

                l_count = l_count + 1;
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
SELECT  import_to_new_asutus_palk_kaart()
*/