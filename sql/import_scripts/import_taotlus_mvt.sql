DROP FUNCTION IF EXISTS import_taotlus_mvt(INTEGER);

CREATE OR REPLACE FUNCTION import_taotlus_mvt(in_old_id INTEGER)
    RETURNS INTEGER AS
$BODY$
DECLARE
    mvt_id      INTEGER;
    log_id      INTEGER;
    v_mvt       RECORD;
    json_object JSONB;
    hist_object JSONB;
    v_params    RECORD;
    l_count     INTEGER = 0;
    l_user_id   INTEGER;
BEGIN
    -- выборка из "старого меню"

    FOR v_mvt IN
        SELECT mvt.kpv, mvt.alg_kpv, mvt.lopp_kpv, mvt.summa, mvt.muud,
               t.rekvid,
               il.new_id AS new_leping_id
        FROM taotlus_mvt mvt
                 INNER JOIN tooleping t ON t.id = mvt.lepingid
                 INNER JOIN rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
                 INNER JOIN import_log il ON il.old_id = t.id AND il.lib_name = 'TOOLEPING'
        WHERE (mvt.id = in_old_id OR in_old_id IS NULL)
          AND (t.lopp IS NULL OR t.lopp >= '2021-01-01')
--          AND t.rekvid IN (SELECT id FROM rekv WHERE parentid < 999 AND id NOT IN (3, 63, 131))
          AND (mvt.lopp_kpv) = '2020-12-31'
            LIMIT ALL
        LOOP

            -- поиск и проверка на ранее сделанный импорт
            /*
        SELECT new_id,
               id
               INTO mvt_id, log_id
        FROM import_log
        WHERE old_id = v_mvt.id
          AND upper(ltrim(rtrim(lib_name :: TEXT))) = 'TAOTLUS_MVT';

        RAISE NOTICE 'check for lib.. v_mvt.id -> %, found -> % log_id -> %', v_mvt.id, mvt_id, log_id;
*/
            -- преобразование и получение параметров
            l_user_id = (SELECT id FROM ou.userid WHERE rekvid = v_mvt.rekvid AND kasutaja = 'vlad' LIMIT 1);

            -- удаляем старые
            PERFORM palk.sp_delete_taotlus_mvt(
                            l_user_id, id)
            FROM palk.taotlus_mvt
            WHERE lepingid = v_mvt.new_leping_id
              AND kpv = '2021-01-01';

            -- сохранение
            SELECT 0                   AS id,
                   v_mvt.new_leping_id AS lepingid,
                   '2021-01-01'::DATE  AS kpv,
                   '2021-01-01'::DATE  AS alg_kpv,
                   '2021-12-31'::DATE  AS lopp_kpv,
                   v_mvt.summa,
                   v_mvt.muud          AS muud
                   INTO v_params;

            SELECT row_to_json(row) INTO json_object
            FROM (SELECT coalesce(mvt_id, 0) AS id,
                         TRUE                AS import,
                         v_params            AS data) row;

            SELECT palk.sp_salvesta_taotlus_mvt(json_object :: JSON, l_user_id, v_mvt.rekvid) INTO mvt_id;
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
            RAISE NOTICE 'mvt_id %, l_count %', mvt_id, l_count;
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
SELECT import_taotlus_mvt(9861)
     SELECT import_taotlus_mvt(mvt.id)
        FROM taotlus_mvt mvt
                 INNER JOIN tooleping t ON t.id = mvt.lepingid
                 INNER JOIN rekv ON rekv.id = t.rekvid AND rekv.parentid < 999
        WHERE (t.lopp IS NULL OR t.lopp >= '2021-01-01')
          AND t.rekvid IN (SELECT id FROM rekv WHERE parentid < 999 AND id not IN (3, 63, 131))
          AND (mvt.lopp_kpv) = '2020-12-31'
--          and t.id in (138745, 144777)
and rekv.id in (select id from rekv where parentid = 119 or id = 119)
            LIMIT ALL

*/

select * from asutus where regkood = '38707173719'

select * from tooleping where parentid = 37607

select * from taotlus_mvt where lepingid in (138745, 144777)