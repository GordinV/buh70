DROP FUNCTION IF EXISTS lapsed.loe_panga_lepingud(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.loe_panga_lepingud(IN data JSONB,
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
    l_laps_id   INTEGER;
    l_vanem_id  INTEGER;
    l_id        INTEGER;
    l_viitenr   TEXT;
    l_pank      TEXT    = 'SWED';
    v_vanem     RECORD;

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
        WITH data AS (
            SELECT *
            FROM jsonb_array_elements(data)
        )
        SELECT *
        FROM data
        ORDER BY value -> 'kehtiv'
        LOOP
            SELECT * INTO json_record
            FROM json_to_record(
                         json_object) AS x (kpv TEXT, viitenr TEXT, aa TEXT, toiming TEXT, nimi TEXT,
                                            isikukood TEXT, kanal TEXT, kehtiv TEXT);

            -- ищем ребенка
            -- если длина ссылки меньше 9, то это старый  номер
            IF (len(json_record.viitenr::TEXT)) < 9
            THEN
                l_viitenr = lapsed.get_viitenumber_from_old(json_record.viitenr::TEXT);

            ELSE
                l_viitenr = json_record.viitenr;
            END IF;

            l_laps_id = lapsed.get_laps_from_viitenumber(l_viitenr);

            -- ищем родителя
            SELECT id INTO l_vanem_id
            FROM libs.asutus
            WHERE regkood = json_record.isikukood
              AND staatus <> 3
            ORDER BY id
            LIMIT 1;

            IF l_laps_id IS NOT NULL AND l_vanem_id IS NOT NULL
            THEN
                IF upper(json_record.toiming) = 'KUSTUTA'
                THEN
                    -- удаляем канал банк
                    UPDATE lapsed.vanemad
                    SET properties = properties || '{
                      "pank": null,
                      "iban": null
                    }'::JSONB
                    WHERE parentid = l_laps_id
                      AND asutusid = l_vanem_id;

                    count = count + 1;
                END IF;

                -- удаляем из vanem_arveldus (новый интерфейс)
                UPDATE lapsed.vanem_arveldus
                SET properties = json_build_object('kas_earve', FALSE)
                WHERE parentid = l_laps_id
                  AND asutusid = l_vanem_id
                  AND rekvid = user_rekvid;

                IF upper(json_record.toiming) = 'LISA'
                THEN
                    -- СОЗДАЕМ КАНАЛ БАНК,
                    IF json_record.kanal = 'HABAEE2X'
                    THEN
                        l_pank = 'SWED';

                    ELSE
                        l_pank = 'SEB';

                    END IF;

                    SELECT id,
                           parentid,
                           asutusid,
                           muud,
                           TRUE                                    AS arved,
                           (properties ->> 'suhtumine')            AS suhtumine,
                           (properties ->> 'kas_paberil')::BOOLEAN AS suhtumine,
                           (properties ->> 'kas_email')::BOOLEAN   AS suhtumine,
                           l_pank                                  AS pank,
                           TRUE                                    AS kas_earve,
                           json_record.aa                          AS iban
                           INTO v_vanem
                    FROM lapsed.vanemad v
                    WHERE v.asutusid = l_vanem_id
                      AND v.parentid = l_laps_id
                    LIMIT 1;

                    -- подготавливаем параметры для сохранения
                    SELECT row_to_json(row) INTO json_object
                    FROM (SELECT v_vanem.id                   AS id,
                                 (SELECT to_jsonb(v_vanem.*)) AS data) row;

                    l_id = (SELECT lapsed.sp_salvesta_vanem(json_object :: JSONB, user_id, user_rekvid));

                    IF (l_id IS NOT NULL AND l_id > 0)
                    THEN
                        count = count + 1;
                    END IF;
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

GRANT EXECUTE ON FUNCTION lapsed.loe_panga_lepingud(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.loe_panga_lepingud(JSONB, INTEGER, INTEGER) TO admin;


/*
select from lapsed.loe_panga_lepingud( '[{"kpv":"06.09.2020 08:49:20","viitenr":"9388642","aa":"EE432200221022308307","toiming":"Lisa","nimi":"ANDREI PETRIKOV","isikukood":"37701213739","kanal":"HABAEE2X"}]', 28, 69)

 */