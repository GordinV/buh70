DROP FUNCTION IF EXISTS lapsed.import_lapsed(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_lapsed(IN data JSONB,
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
    json_save_params JSON;
    count            INTEGER = 0;
    json_record      RECORD;
    l_laps_id        INTEGER;
BEGIN

    SELECT kasutaja INTO userName
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

            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x (isikukood TEXT, nimi TEXT);

            -- проверяем уникальность записи по pank_id

            IF NOT exists(SELECT 1 FROM lapsed.laps WHERE isikukood = json_record.isikukood)
            THEN

                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row) INTO json_save_params
                FROM (SELECT 0                                AS id,
                             (SELECT to_jsonb(json_record.*)) AS data) row;

                SELECT lapsed.sp_salvesta_laps(json_save_params :: JSONB, user_id, user_rekvid) INTO l_laps_id;

                IF l_laps_id > 0
                THEN
                    count = count + 1;
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

GRANT EXECUTE ON FUNCTION lapsed.import_lapsed (JSONB, INTEGER, INTEGER) TO arvestaja;


/*

SELECT error_code, result, error_message
                  FROM lapsed.import_lapsed( '[{"isikukood":"35901260229","nimi":"Batluk Juri","import":true},{"isikukood":"36006133727","nimi":"Eroshkin Sergey","import":true},{"isikukood":"36007033748","nimi":"Timo�kin Arno","import":true},{"isikukood":"36009233726","nimi":"Klibanov Igor","import":true},{"isikukood":"36202133713","nimi":"Gavrilov Leonid","import":true},{"isikukood":"36212133717","nimi":"Sokurov Yury","import":true},{"isikukood":"36212303719","nimi":"Jerohhin Vadim","import":true}]'::jsonb, 70::integer, 63::integer) as id
*/