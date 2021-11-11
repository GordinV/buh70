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
FROM lapsed.import_laste_taabelid('[{"isikukood":"51408020062","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51408020062","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51408060068","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51408060068","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51412110057","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51412110057","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51412180171","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51412180171","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51503280040","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51503280040","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51505250039","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51505250039","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51506200133","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51506200133","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51509030153","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51509030153","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51509280077","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51509280077","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51510260178","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51510260178","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51512010152","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51512010152","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51512080200","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51512080200","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51602270150","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51602270150","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51603250130","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51603250130","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51605130055","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51605130055","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51608290052","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51608290052","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51704120100","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51704120100","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51708240064","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51708240064","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51710240115","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51710240115","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51801210011","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51801210011","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51805030077","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51805030077","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51805100138","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51805100138","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51809240202","yksus":"LAED-001-02","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51809240202","yksus":"LAED-001-02","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51901280128","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51901280128","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51906110099","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51906110099","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51906110109","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51906110109","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51908010135","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51908010135","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"51908150038","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"51908150038","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"51910040111","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"51910040111","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61401300054","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61401300054","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61406120070","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61406120070","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61411170149","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61411170149","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61412020157","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61412020157","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61512090110","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61512090110","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61603130177","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61603130177","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61606110101","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61606110101","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61606240117","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61606240117","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61607050030","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"61607050030","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"61607050041","yksus":"LAED-002-04","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"61607050041","yksus":"LAED-002-04","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"61609090024","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61609090024","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61609180056","yksus":"LAED-002-04","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61609180056","yksus":"LAED-002-04","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61703080045","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"61703080045","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"61704110160","yksus":"LAED-002-03","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"61704110160","yksus":"LAED-002-03","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"61705070037","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61705070037","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61705100114","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61705100114","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61705160101","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61705160101","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61706230059","yksus":"LAED-002-03","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61706230059","yksus":"LAED-002-03","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61801220150","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61801220150","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61804050174","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61804050174","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61805130116","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61805130116","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61805160104","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61805160104","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61806210026","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61806210026","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61807310157","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61807310157","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61810210077","yksus":"LAED-001-02","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61810210077","yksus":"LAED-001-02","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61901300091","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61901300091","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61901310108","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61901310108","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61902180019","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"61902180019","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1"},{"isikukood":"61905070206","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61905070206","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61908290018","yksus":"LAED-001-01","kood":"322020-061","hind":"-20.44","kogus":"1"},{"isikukood":"61908290018","yksus":"LAED-001-01","kood":"322030-066","hind":"-8.76","kogus":"1"},{"isikukood":"61909030144","yksus":"LAED-001-01","kood":"322020-061","hind":"-15.33","kogus":"1"},{"isikukood":"61909030144","yksus":"LAED-001-01","kood":"322030-066","hind":"-6.57","kogus":"1"}]',
  4948,
  85)




select * from libs.nomenklatuur where kood in ('322030-066','322030-061')
and rekvid = 80


*/
/*SELECT *
FROM lapsed.lapse_taabel
WHERE id = 56
*/