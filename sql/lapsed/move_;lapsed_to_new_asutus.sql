DROP FUNCTION IF EXISTS lapsed.move_laspsed_to_new_asutus(IN vana_asutus INTEGER,
    IN vana_grupp INTEGER,
    IN uus_asutus INTEGER,
    IN uus_grupp INTEGER);

CREATE OR REPLACE FUNCTION lapsed.move_laspsed_to_new_asutus(IN vana_asutus INTEGER,
                                                             IN vana_grupp INTEGER,
                                                             IN uus_asutus INTEGER,
                                                             IN uus_grupp INTEGER)
    RETURNS INTEGER
AS
$BODY$

DECLARE
    json_object      JSON;
    count            INTEGER = 0;
    l_id             INTEGER;
    json_save_params JSONB;
    v_lapsed         RECORD;
    v_teenused       RECORD;
    v_yksus          RECORD;
    user_id          INTEGER;
    l_lopp_kpv       DATE;

BEGIN
    /*    vana_asutus = 94;
        vana_grupp = 269154;
        uus_grupp = 273115;
        uus_asutus = 84;
    */
    SELECT * INTO v_yksus FROM libs.library WHERE id = uus_grupp;
    user_id = (SELECT id FROM ou.userid WHERE kasutaja = 'vlad' AND rekvid = uus_asutus AND status < 3 LIMIT 1);

   -- 1. выбираем детей из группы
    FOR v_lapsed IN (
        SELECT lk.parentid, max((lk.properties ->> 'lopp_kpv')::DATE) AS lopp_kpv
        FROM lapsed.laps l
                 INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
        WHERE lk.rekvid = vana_asutus
--  limit 10
          AND (lk.properties ->> 'yksus')::TEXT IN (SELECT kood FROM libs.library WHERE id = vana_grupp)
          AND (lk.properties ->> 'lopp_kpv')::DATE > '2023-06-30'
        GROUP BY lk.parentid)
        LOOP
            -- копируем услуги ребенку
            FOR v_teenused IN (
                SELECT *
                FROM jsonb_array_elements((SELECT properties::JSONB -> 'teenused'
                                           FROM libs.library
                                           WHERE rekvid = uus_asutus
                                             AND id = uus_grupp))
            )
                LOOP
                    raise notice 'v_lapsed.lopp_kpv %, v_lapsed.parentid %',v_lapsed.lopp_kpv, v_lapsed.parentid;

                    -- параметры
                    json_object = to_jsonb(row)
                                  FROM (SELECT 0            AS id,
                                               v_lapsed.parentid            AS parentid,
                                               v_teenused.value ->> 'nomid' AS nomid,
                                               ltrim(rtrim(v_yksus.kood))   AS yksus,
                                               NULL                         AS all_yksus,
                                               v_teenused.value ->> 'kogus' AS kogus,
                                               v_teenused.value ->> 'hind'  AS hind,
                                               '2023-07-01'                 AS alg_kpv,
                                               v_lapsed.lopp_kpv
                                       ) ROW;

                    -- сохраняем
                    -- подготавливаем параметры для сохранения
                    SELECT row_to_json(row)
                    INTO json_save_params
                    FROM (SELECT 0           AS id,
                                 json_object AS data) row;

                    SELECT lapsed.sp_salvesta_lapse_kaart(json_save_params :: JSONB, user_id, uus_asutus) INTO l_id;
                    RAISE NOTICE 'l_id %', l_id;
                    IF l_id > 0
                    THEN
                        count = count + 1;
                    ELSE
                        RAISE EXCEPTION 'salvestamine eba onnestus, %',json_save_params;
                    END IF;
                END LOOP;
        END LOOP;

    FOR v_lapsed IN (
        SELECT lk.*
        FROM lapsed.laps l
                 INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
        WHERE lk.rekvid = vana_asutus
--  limit 10
          AND lk.properties ->> 'yksus' IN (SELECT kood FROM libs.library WHERE id = vana_grupp)
          AND (lk.properties ->> 'lopp_kpv') >= '2023-06-30')
        LOOP
            UPDATE lapsed.lapse_kaart
            SET properties = properties || jsonb_build_object('lopp_kpv', '2023-06-30')
            WHERE id = v_lapsed.id;
        END LOOP;
    RETURN count;

/*
    FOR v_teenused IN (
        SELECT lk.*
        FROM lapsed.lapse_kaart lk
        WHERE lk.rekvid = 94
          AND lk.properties ->> 'lopp_kpv' = '2023-06-30'
          AND exists(
                SELECT id
                FROM ou.logs
                WHERE doc_id = lk.id
                  AND propertis ->> 'table' = 'lapse_kaart'
                  AND propertis ->> 'updated'::TEXT LIKE '2023-07-02%'
            ))
        LOOP
            l_lopp_kpv = (SELECT changes -> 'properties' ->> 'lopp_kpv'
                          FROM ou.logs
                          WHERE doc_id = v_teenused.id
                            AND propertis ->> 'table' = 'lapse_kaart'
                            AND propertis ->> 'updated'::TEXT LIKE '2023-07-02%'
                          ORDER BY id ASC
                          LIMIT 1);

            RAISE NOTICE 'v_teenused.id %, l_lopp_kpv %', v_teenused.id, l_lopp_kpv;
            UPDATE lapsed.lapse_kaart
            SET properties = properties ||
                             jsonb_build_object('lopp_kpv', l_lopp_kpv)
            WHERE id = v_teenused.id
              AND l_lopp_kpv IS NOT NULL;

            /*parentid = v_teenused.parentid
              AND rekvid = uus_asutus
              AND properties ->> 'alg_kpv' = '2023-06-30'
              AND properties ->> 'lopp_kpv' = '2023-06-30';*/

        END LOOP;
    RETURN 1;
*/
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

/*
select * from ou.rekv where nimetus ilike '%tareke%'
-- 94
select * from libs.library where rekvid = 94 and nimetus like '06%'
-- 269154

select * from ou.rekv where nimetus ilike '%potsa%'
-- 84
select * from libs.library where rekvid = 84 and nimetus like '37 %'
--273115



SELECT *
FROM lapsed.move_laspsed_to_new_asutus(94,269103,84,273116 )


*/

