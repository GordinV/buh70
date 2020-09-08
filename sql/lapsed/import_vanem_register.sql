DROP FUNCTION IF EXISTS lapsed.import_vanem_register(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_vanem_register(IN data JSONB,
                                                        IN user_id INTEGER,
                                                        IN user_rekvid INTEGER,
                                                        OUT result INTEGER,
                                                        OUT error_code INTEGER,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName    TEXT;
    json_object JSON;
    count       INTEGER = 0;
    json_record RECORD;
    l_rekv_id   INTEGER;
    l_laps_id   INTEGER;
    l_vanem_id  INTEGER;
    l_id        INTEGER;

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
                         json_object) AS x (lapse_ik TEXT, vanem_ik TEXT, sugulus TEXT, arveldus TEXT, paper TEXT,
                                            earve TEXT, email TEXT, esindaja TEXT);

            -- ищем ребенка
            SELECT id INTO l_laps_id
            FROM lapsed.laps
            WHERE isikukood = json_record.lapse_ik
              AND staatus <> 3
            ORDER BY id
            LIMIT 1;

            -- ищем родителя
            SELECT id INTO l_vanem_id
            FROM libs.asutus
            WHERE regkood = json_record.vanem_ik
              AND staatus <> 3
            ORDER BY id
            LIMIT 1;

            IF l_laps_id IS NOT NULL AND l_vanem_id IS NOT NULL
            THEN
                json_object = to_jsonb(row)
                              FROM (SELECT CASE WHEN json_record.arveldus ILIKE '%jah%' THEN 'Jah' ELSE 'Ei' END               AS arved,
                                           json_record.sugulus                                                                 AS suhtumine,
                                           json_record.paper IS NOT NULL AND
                                           (json_record.paper ILIKE '%jah%' OR json_record.paper ILIKE '%yes%')::BOOLEAN       AS kas_paberil,
                                           json_record.email IS NOT NULL AND
                                           (json_record.email ILIKE '%jah%' OR json_record.email ILIKE '%yes%')::BOOLEAN       AS kas_email,
                                           json_record.esindaja IS NOT NULL AND
                                           (json_record.esindaja ILIKE '%jah%' OR json_record.esindaja ILIKE '%yes%')::BOOLEAN AS kas_esindaja,
                                           json_record.earve IS NOT NULL AND
                                           (json_record.earve ILIKE '%jah%' OR json_record.earve ILIKE '%yes%')::BOOLEAN       AS kas_earve) row;


                -- проверяем уникальность записи
                IF NOT exists(SELECT id FROM lapsed.vanemad WHERE parentid = l_laps_id AND asutusid = l_vanem_id)
                THEN

                    -- сохраняем
                    INSERT INTO lapsed.vanemad (parentid, asutusid, properties)
                    VALUES (l_laps_id, l_vanem_id, json_object) RETURNING id INTO l_id;
                ELSE
                    UPDATE lapsed.vanemad
                    SET properties = properties::JSONB || json_object::JSONB
                    WHERE parentid = l_laps_id
                      AND asutusid = l_vanem_id RETURNING id INTO l_id;

                END IF;
                -- ответственный родитель
                IF (json_record.arveldus ILIKE '%jah%')
                THEN
                    DELETE
                    FROM lapsed.vanem_arveldus
                    WHERE rekvid = user_rekvid
                      AND parentid = l_laps_id;

                    INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus)
                    VALUES (l_laps_id, l_vanem_id, user_rekvid, TRUE);
                END IF;


                IF l_id > 0
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

GRANT EXECUTE ON FUNCTION lapsed.import_vanem_register(JSONB, INTEGER, INTEGER) TO arvestaja;

/*
select * from lapsed.import_vanem_register('[{"lapse_ik":"51311090109","vanem_ik":"49112123758","sugulus":"Ema","arveldus":"Jah","paper":"Yes","earve":"Yes","email":"","esindaja":"Yes"},{"lapse_ik":"51309270095","vanem_ik":"49212063739","sugulus":"Ema","arveldus":"Jah","paper":"Yes","earve":"","email":"","esindaja":"Yes"},{"lapse_ik":"51409250198","vanem_ik":"48610223723","sugulus":"","arveldus":"Jah","paper":"Yes","earve":"","email":"","esindaja":""}]'::jsonb, 70, 63)

SELECT id FROM lapsed.vanemad WHERE parentid = 5004 AND asutusid = 16070
delete from lapsed.vanemad where id = 43
*/


