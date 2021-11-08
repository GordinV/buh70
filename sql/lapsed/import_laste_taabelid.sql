DROP FUNCTION IF EXISTS lapsed.import_laste_taabelid(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_laste_taabelid(IN data JSONB,
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
    l_lapse_kaart_id INTEGER;
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
                         json_object) AS x (isikukood TEXT, yksus TEXT, kood TEXT, hind TEXT,
                                            kogus TEXT, kuu TEXT, aasta TEXT);

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

            -- ищем запись в карте
            SELECT id
            INTO l_lapse_kaart_id
            FROM lapsed.lapse_kaart lk
            WHERE parentid = l_laps_id
              AND nomid = l_nom_id
              AND rekvid = user_rekvid
              AND staatus <> 3
              AND ltrim(rtrim((properties ->> 'yksus'))) = ltrim(rtrim(json_record.yksus));

            IF l_laps_id IS NOT NULL AND l_lapse_kaart_id IS NOT NULL
            THEN

                json_object = to_jsonb(row)
                              FROM (SELECT 0                                       AS id,
                                           l_laps_id                               AS parentid,
                                           l_lapse_kaart_id                        AS lapse_kaart_id,
                                           CASE
                                               WHEN empty(json_record.kogus) THEN 0::NUMERIC
                                               ELSE json_record.kogus::NUMERIC END AS kogus,
                                           CASE
                                               WHEN empty(json_record.hind) THEN 0::NUMERIC
                                               ELSE json_record.hind::NUMERIC END  AS hind,
                                           json_record.kuu::INTEGER                AS kuu,
                                           json_record.aasta::INTEGER              AS aasta,
                                           TRUE                                    AS umberarvestus
                                   ) ROW;

                -- сохраняем
                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row)
                INTO json_save_params
                FROM (SELECT 0           AS id,
                             json_object AS data) row;

                SELECT lapsed.sp_salvesta_lapse_taabel(json_save_params :: JSONB, user_id, user_rekvid) INTO l_id;
                IF l_id > 0
                THEN
                    count = count + 1;
                    RAISE NOTICE 'saved , l_id %, json_save_params %', l_id, json_save_params;
                ELSE
                    RAISE NOTICE 'salvestamine eba onnestus, %',json_save_params;
                END IF;
            ELSE
                RAISE NOTICE 'not found l_laps_id % , l_lapse_kaart_id %, json_record.kood %', l_laps_id, l_lapse_kaart_id, json_record.kood;

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

GRANT EXECUTE ON FUNCTION lapsed.import_laste_taabelid(JSONB, INTEGER, INTEGER) TO arvestaja;


/*
SELECT *
FROM lapsed.import_laste_taabelid('[{"isikukood":"51403100160","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51403100160","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51404040099","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51404040099","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51405260108","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51405260108","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51407030293","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51407030293","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51407150271","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51407150271","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51408020084","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51408020084","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51409290018","yksus":"LAED-002-04","kood":"322020-061","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51409290018","yksus":"LAED-002-04","kood":"322030-066","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51410130083","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51410130083","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51503180033","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51503180033","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51504020097","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51504020097","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51505110049","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51505110049","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51505110051","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51505110051","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51506010063","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51506010063","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51507210043","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51507210043","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51510240131","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51510240131","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51602100139","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51602100139","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51603100220","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51603100220","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51603210190","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51603210190","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51606170022","yksus":"LAED-002-05","kood":"322020-061","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51606170022","yksus":"LAED-002-05","kood":"322030-066","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51606240039","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51606240039","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51608150258","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51608150258","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51608190242","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51608190242","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51608260129","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51608260129","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51704030101","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51704030101","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51707250114","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51707250114","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51711110165","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51711110165","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51803130203","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51803130203","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51804270166","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51804270166","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51806150036","yksus":"LAED-002-03","kood":"322020-061","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51806150036","yksus":"LAED-002-03","kood":"322030-066","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51811050031","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51811050031","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51811140096","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51811140096","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51812070115","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51812070115","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51812170121","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51812170121","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51812210249","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51812210249","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51901210112","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51901210112","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51905140147","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51905140147","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51907160105","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51907160105","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51907230101","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51907230101","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51910300252","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"51910300252","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"52002180070","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"52002180070","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61402100134","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61402100134","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61406040176","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61406040176","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61406110226","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61406110226","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61407050086","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61407050086","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61407310112","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61407310112","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61409020068","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61409020068","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61411270057","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61411270057","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61501090072","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61501090072","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61501290064","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61501290064","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61503060014","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61503060014","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61503290156","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61503290156","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61504060030","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61504060030","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61509160333","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61509160333","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61510120210","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61510120210","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61510190030","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61510190030","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61511130081","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61511130081","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61602030079","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61602030079","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61603090060","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61603090060","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61603310111","yksus":"LAED-002-05","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61603310111","yksus":"LAED-002-05","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61609060208","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61609060208","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61709250120","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61709250120","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61801010033","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61801010033","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61801140174","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61801140174","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61806040080","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61806040080","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61806150081","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61806150081","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61806270231","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61806270231","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61808060168","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61808060168","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61808170268","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61808170268","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61810250159","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61810250159","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61811200227","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61811200227","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61812300118","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61812300118","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61902080100","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61902080100","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61902280167","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61902280167","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61903060222","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61903060222","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61903290190","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61903290190","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61904080121","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61904080121","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61905060134","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61905060134","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61908010180","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61908010180","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61908020198","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61908020198","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61908060157","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61908060157","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61909240217","yksus":"LAED-001-01","kood":"322020-061","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61909240217","yksus":"LAED-001-01","kood":"322030-066","hind":"0","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61910140171","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"61910140171","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"62004160034","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1","kuu":"4","aasta":"2021"},{"isikukood":"62004160034","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1","kuu":"4","aasta":"2021"}]',
  4959,
  80)




select * from libs.nomenklatuur where kood in ('322030-066','322030-061')
and rekvid = 80


*/
/*SELECT *
FROM lapsed.lapse_taabel
WHERE id = 56
*/