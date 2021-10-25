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
                              FROM (SELECT coalesce(l_id, 0)                       AS id,
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

GRANT EXECUTE ON FUNCTION lapsed.import_laste_taabelid(JSONB, INTEGER, INTEGER) TO arvestaja;


/*
SELECT *
FROM lapsed.import_laste_taabelid('[{"isikukood":"51001163716","yksus":"Sekretar ","kood":"322020-061 ","hind":"-25","kogus":"1","kuu":"11","aasta":"2021"}]',
  2477,
  63)

*/

