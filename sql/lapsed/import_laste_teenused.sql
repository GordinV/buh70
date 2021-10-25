DROP FUNCTION IF EXISTS lapsed.import_laste_teenused(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_laste_teenused(IN data JSONB,
                                                        IN user_id INTEGER,
                                                        IN user_rekvid INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName         TEXT;
    json_object      JSON;
    count            INTEGER = 0;
    json_record      RECORD;
    l_laps_id        INTEGER;
    l_nom_id         INTEGER;
    l_id             INTEGER;
    json_save_params JSONB;
    l_status         INTEGER;

BEGIN
    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF userName IS NULL
    THEN
        error_message = 'User not found';
        RETURN;
    END IF;

    FOR json_object IN
        SELECT *
        FROM jsonb_array_elements(data)
        LOOP
            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x (isikukood TEXT, yksus TEXT, all_yksus TEXT, kood TEXT, hind TEXT,
                                            kogus TEXT,
                                            tunnus TEXT, alg_kpv TEXT, lopp_kpv TEXT, kas_ettemaks TEXT,
                                            ettemaksu_period TEXT,
                                            kas_eraldi TEXT, kas_inf3 TEXT, soodus TEXT, sooduse_alg TEXT,
                                            sooduse_lopp TEXT, kas_protsent TEXT);

            -- ищем ребенка
            SELECT id, staatus
            INTO l_laps_id, l_status
            FROM lapsed.laps
            WHERE isikukood = json_record.isikukood
--              AND staatus <> 3
            ORDER BY id
            LIMIT 1;

            -- ищем услугу
            SELECT id
            INTO l_nom_id
            FROM libs.nomenklatuur n
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(json_record.kood))
              AND rekvid = user_rekvid
              AND n.status <> 3
            ORDER BY id
            LIMIT 1;

            RAISE NOTICE 'l_laps_id %, l_nom_id %, json_record.kood %, json_record.isikukood %, user_rekvid %', l_laps_id, l_nom_id, json_record.kood, json_record.isikukood,user_rekvid;
            IF l_laps_id IS NOT NULL AND l_nom_id IS NOT NULL AND NOT exists(
                    SELECT id FROM lapsed.lapse_kaart WHERE parentid = l_laps_id AND nomid = l_nom_id AND staatus <> 3)
                AND NOT exists(
                        SELECT lt.id
                        FROM lapsed.lapse_taabel lt
                        WHERE lt.parentid = l_laps_id
                          AND (make_date(lt.aasta, lt.kuu, 1) + INTERVAL '1 month' - INTERVAL '1 day')::DATE <
                              format_date(json_record.alg_kpv::TEXT)
                          AND lt.nomid = l_nom_id
                          AND lt.staatus < 3
                        LIMIT 1)
            THEN
                -- проверяем уникальность записи
                l_id = (SELECT id
                        FROM lapsed.lapse_kaart lk
                        WHERE parentid = l_laps_id
                          AND upper(coalesce(lk.properties ->> 'yksus', '')) =
                              upper(coalesce(json_record.yksus, ''))
                          AND staatus <> 3
                          AND nomid = l_nom_id
                          AND rekvid = user_rekvid);

                json_object = to_jsonb(row)
                              FROM (SELECT coalesce(l_id, 0)                                 AS id,
                                           l_laps_id                                         AS parentid,
                                           l_nom_id                                          AS nomid,
                                           json_record.tunnus                                AS tunnus,
                                           json_record.yksus                                 AS yksus,
                                           json_record.all_yksus                             AS all_yksus,
                                           CASE
                                               WHEN empty(json_record.kogus) THEN 0::NUMERIC
                                               ELSE json_record.kogus::NUMERIC END           AS kogus,
                                           CASE
                                               WHEN empty(json_record.hind) THEN 0::NUMERIC
                                               ELSE json_record.hind::NUMERIC END            AS hind,
                                           CASE
                                               WHEN empty(json_record.ettemaksu_period::TEXT) OR
                                                    json_record.ettemaksu_period IS NULL THEN NULL
                                               ELSE json_record.ettemaksu_period END         AS ettemaksu_period,
                                           CASE
                                               WHEN empty(json_record.soodus) OR json_record.soodus = '' THEN NULL
                                               ELSE json_record.soodus END                   AS soodus,
                                           json_record.kas_protsent IS NOT NULL AND
                                           (json_record.kas_protsent ILIKE
                                            '%jah%' OR
                                            json_record.kas_protsent ILIKE
                                            '%yes%'
                                               )::BOOLEAN                                    AS kas_protsent,
                                           json_record.kas_inf3 IS NOT NULL AND
                                           (json_record.kas_inf3 ILIKE '%jah%' OR
                                            json_record.kas_inf3 ILIKE '%yes%')::BOOLEAN     AS kas_inf3,
                                           CASE
                                               WHEN NOT empty(json_record.sooduse_alg)
                                                   THEN format_date(json_record.sooduse_alg::TEXT)
                                               ELSE NULL END::DATE                           AS sooduse_alg,
                                           CASE
                                               WHEN NOT empty(json_record.sooduse_lopp)
                                                   THEN format_date(json_record.sooduse_lopp::TEXT)
                                               ELSE NULL::DATE END                           AS sooduse_lopp,
                                           format_date(json_record.alg_kpv::TEXT)            AS alg_kpv,
                                           format_date(json_record.lopp_kpv::TEXT)           AS lopp_kpv,
                                           json_record.kas_eraldi IS NOT NULL AND
                                           (json_record.kas_eraldi ILIKE '%jah%' OR
                                            json_record.kas_eraldi ILIKE '%yes%')::BOOLEAN   AS kas_eraldi,
                                           json_record.kas_ettemaks IS NOT NULL AND
                                           (json_record.kas_ettemaks ILIKE '%jah%' OR
                                            json_record.kas_ettemaks ILIKE '%yes%')::BOOLEAN AS kas_ettemaks
                                   ) ROW;

                -- сохраняем
                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row)
                INTO json_save_params
                FROM (SELECT 0           AS id,
                             json_object AS data) row;

/*                    IF l_status = 3
                    THEN
                        -- карточка ребенка удалена, восстановим
                        UPDATE lapsed.laps SET staatus = 1 WHERE id = l_laps_id;
                    END IF;

*/
                SELECT lapsed.sp_salvesta_lapse_kaart(json_save_params :: JSONB, user_id, user_rekvid) INTO l_id;
                IF l_id > 0
                THEN
                    count = count + 1;
                ELSE
                    RAISE NOTICE 'salvestamine eba onnestus, %',json_save_params;
                END IF;

            END IF;


        END LOOP;

    -- расшифруем платежи
    result = count;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_message = SQLERRM;
            RETURN;


END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.import_laste_teenused(JSONB, INTEGER, INTEGER) TO arvestaja;


/*
SELECT *
FROM lapsed.import_laste_teenused('[{"isikukood":"51507010238","yksus":"LAED-002-05","all_yksus":"","kood":"322020-061","hind":"-2.42","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51507010238","yksus":"LAED-002-05","all_yksus":"","kood":"322030-066","hind":"-1.03","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51507070182","yksus":"LAED-002-10","all_yksus":"","kood":"322020-061","hind":"-11.83","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51507070182","yksus":"LAED-002-10","all_yksus":"","kood":"322030-066","hind":"-4.89","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51511180059","yksus":"LAED-002-01","all_yksus":"","kood":"322020-061","hind":"-2.42","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51511180059","yksus":"LAED-002-01","all_yksus":"","kood":"322030-066","hind":"-1.03","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51701180062","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51701180062","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51701280111","yksus":"LAED-002-10","all_yksus":"","kood":"322020-061","hind":"-8.61","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51701280111","yksus":"LAED-002-10","all_yksus":"","kood":"322030-066","hind":"-3.69","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51704120057","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-2.42","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51704120057","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.03","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51704230026","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51704230026","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51706270118","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51706270118","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51706280051","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51706280051","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51709100068","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51709100068","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51709240073","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51709240073","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51711040121","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51711040121","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51712010060","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-2.42","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51712010060","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.03","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51801230079","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-4.84","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51801230079","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.08","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51803020234","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51803020234","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51805120076","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-4.84","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51805120076","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.08","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51809280143","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51809280143","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51901030212","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-8.61","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51901030212","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-3.69","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51901060026","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-4.84","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51901060026","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.08","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51902230131","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"51902230131","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61506060116","yksus":"LAED-002-01","all_yksus":"","kood":"322020-061","hind":"-9.68","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61506060116","yksus":"LAED-002-01","all_yksus":"","kood":"322030-066","hind":"-4.15","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61607190216","yksus":"LAED-002-10","all_yksus":"","kood":"322020-061","hind":"-9.68","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61607190216","yksus":"LAED-002-10","all_yksus":"","kood":"322030-066","hind":"-4.15","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61701040160","yksus":"LAED-002-05","all_yksus":"","kood":"322020-061","hind":"-12.91","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61701040160","yksus":"LAED-002-05","all_yksus":"","kood":"322030-066","hind":"-5.53","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61702070175","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61702070175","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61703180116","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61703180116","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61704190128","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61704190128","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61705260020","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61705260020","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61706040098","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61706040098","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61706060068","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61706060068","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61708060012","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-2.42","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61708060012","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.03","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61711050062","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61711050062","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61801090089","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61801090089","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61801270076","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61801270076","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61803070139","yksus":"LAED-002-04","all_yksus":"","kood":"322020-061","hind":"-3.23","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61803070139","yksus":"LAED-002-04","all_yksus":"","kood":"322030-066","hind":"-1.38","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61803110114","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61803110114","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61806290174","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-4.84","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61806290174","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.08","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61810310104","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61810310104","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61903070077","yksus":"LAED-001-12","all_yksus":"","kood":"322020-061","hind":"-6.45","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""},{"isikukood":"61903070077","yksus":"LAED-001-12","all_yksus":"","kood":"322030-066","hind":"-2.77","kogus":"1","tunnus":"","alg_kpv":"01.02.2021","lopp_kpv":"28.02.2021","kas_ettemaks":"","ettemaksu_period":"","kas_eraldi":"","kas_inf3":"yes","soodus":"","sooduse_alg":"","sooduse_lopp":"","kas_protsent":""}]',
  4105,
  81)

select * from ou.use

SELECT id FROM lapsed.vanemad WHERE parentid = 5004 AND asutusid = 16070
delete from lapsed.vanemad where id = 43

SELECT * FROM lapsed.lapse_kaart order by id desc limit 10

delete FROM lapsed.lapse_kaart
where id > 72
*/



select * from lapsed.lapse_kaart
where timestamp::text like '2021-10-20 19:%'
  and ajalugu-> 0->>'user' = 'vlad'
and rekvid = 81
order by id desc limit 10

