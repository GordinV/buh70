DROP FUNCTION IF EXISTS lapsed.import_viitenr(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_viitenr(IN data JSONB,
                                                 IN user_id INTEGER,
                                                 IN user_rekvid INTEGER,
                                                 OUT result INTEGER,
                                                 OUT error_code INTEGER,
                                                 OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName     TEXT;
    json_object  JSON;
    count        INTEGER = 0;
    json_record  RECORD;
    l_viitenr_id INTEGER;
    l_rekv_id    INTEGER;
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
                         json_object) AS x (isikukood TEXT, viitenr TEXT, asutus TEXT, nimetus TEXT);

            -- ищем ид учреждения
            SELECT id INTO l_rekv_id
            FROM ou.rekv
            WHERE nimetus LIKE json_record.asutus || '%'
              AND parentid = 119
            ORDER BY id DESC
            LIMIT 1;

            IF l_rekv_id IS NULL
            THEN
                RAISE EXCEPTION 'asutus ei leidnud %', json_record.asutus;
            END IF;

            -- проверяем уникальность записи

            IF NOT exists(SELECT 1 FROM lapsed.viitenr WHERE viitenumber = json_record.viitenr)
            THEN
                INSERT INTO lapsed.viitenr (isikukood, rekv_id, viitenumber)
                VALUES (json_record.isikukood, l_rekv_id, json_record.viitenr) RETURNING id INTO l_viitenr_id;

                IF l_viitenr_id > 0
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

