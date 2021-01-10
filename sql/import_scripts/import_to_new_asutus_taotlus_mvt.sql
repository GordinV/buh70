DROP FUNCTION IF EXISTS import_to_new_asutus_taotlus_mvt();

CREATE OR REPLACE FUNCTION import_to_new_asutus_taotlus_mvt()
    RETURNS INTEGER AS
$BODY$
DECLARE
    leping_id       INTEGER;
    v_leping        RECORD;
    json_object     JSONB;
    v_params        RECORD;
    l_count         INTEGER = 0;
    l_osakond_id    INTEGER;
    l_amet_id       INTEGER;
    l_asutus_id     INTEGER;
    l_user_id       INTEGER = (SELECT id
                               FROM ou.userid
                               WHERE rekvid = 132
                                 AND kasutaja = 'vlad'
                                   LIMIT 1);
    l_uus_leping_id INTEGER;
    v_tootaja       RECORD;
    kas_vana        BOOLEAN;
    kas_uus         BOOLEAN;
    l_mvt_summa     NUMERIC;
    mvt_id          INTEGER;
BEGIN
    -- выборка из "старого меню"

    RAISE NOTICE 'start';

    FOR v_leping IN
        SELECT t.*,
               o.kood AS osakond,
               a.kood AS amet
        FROM palk.tooleping t
                 INNER JOIN libs.library o ON o.id = t.osakondid
                 INNER JOIN libs.library a ON a.id = t.ametid
        WHERE t.rekvid = 64
          AND t.osakondid NOT IN (SELECT id FROM library WHERE rekvid = 64 AND library = 'OSAKOND' AND kood <> 'SAA')
--          AND t.id = 18654
--          AND (t.lopp IS NULL
--            OR t.lopp > current_date)
            LIMIT ALL
        LOOP

            RAISE NOTICE 'lepid %, osakond %', v_leping.id, v_leping.osakond;

            l_osakond_id = (SELECT id
                            FROM libs.library l
                            WHERE rekvid = 132
                              AND ltrim(rtrim(kood)) = ltrim(rtrim(v_leping.osakond))
                              AND library = 'OSAKOND'
                              AND status <> 3
                                LIMIT 1);

            l_amet_id = (SELECT id
                         FROM libs.library l
                         WHERE rekvid = 132
                           AND ltrim(rtrim(kood)) = ltrim(rtrim(v_leping.amet))
                           AND library = 'AMET'
                           AND status <> 3
                             LIMIT 1);


            -- ищем аналог в центре
            l_uus_leping_id = (SELECT id
                               FROM palk.tooleping
                               WHERE parentid = v_leping.parentid
                                 AND rekvid = 132
                                 AND ametid = l_amet_id
                                 AND osakondid = l_osakond_id);


            -- проверяем наличие заявления
            IF l_uus_leping_id IS NOT NULL
            THEN
                RAISE NOTICE 'l_uus_leping_id %, l_asutus_id %, l_amet_id %, l_osakond_id %', l_uus_leping_id, l_asutus_id, l_amet_id, l_osakond_id;
            END IF;

            kas_uus = exists(SELECT id FROM palk.taotlus_mvt WHERE lepingid = l_uus_leping_id AND year(kpv) = 2021);
            kas_vana = exists(SELECT id FROM palk.taotlus_mvt WHERE lepingid = v_leping.id AND year(kpv) = 2021);
            RAISE NOTICE 'taotlus mvt found, import kas_vana %, kas_uus %', kas_vana, kas_uus;

            IF NOT (kas_uus) AND kas_vana
            THEN
                l_mvt_summa =
                        (SELECT summa FROM palk.taotlus_mvt WHERE lepingid = v_leping.id AND year(kpv) = 2021 LIMIT 1);

                -- сохранение
                SELECT 0                  AS id,
                       l_uus_leping_id    AS lepingid,
                       '2021-01-01'::DATE AS kpv,
                       '2021-01-01'::DATE AS alg_kpv,
                       '2021-12-31'::DATE AS lopp_kpv,
                       l_mvt_summa        AS summa,
                       'import'           AS muud
                       INTO v_params;

                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0        AS id,
                             TRUE     AS import,
                             v_params AS data) row;

                RAISE NOTICE 'salvestan json_object %', json_object;
               SELECT palk.sp_salvesta_taotlus_mvt(json_object :: JSON, l_user_id, 132) INTO mvt_id;
                RAISE NOTICE 'saved, id %', mvt_id;
            END IF;

/*

            -- salvestame log info
            SELECT row_to_json(row) INTO hist_object
            FROM (SELECT now() AS timestamp) row;

            IF log_id IS NULL
            THEN
                INSERT INTO import_log (new_id, old_id, lib_name, params, history)
                VALUES (mvt_id, v_mvt.id, 'TAOTLUS_MVT', json_object :: JSON, hist_object :: JSON) RETURNING id
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

 */
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

SELECT import_to_new_asutus_taotlus_mvt()

/*
SELECT import_to_new_asutus_taotlus_mvt()
*/
