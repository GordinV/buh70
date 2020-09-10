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
    userName       TEXT;
    json_object    JSON;
    count          INTEGER = 0;
    json_record    RECORD;
    l_rekv_id      INTEGER;
    l_laps_id      INTEGER;
    l_vanem_id     INTEGER;
    l_id           INTEGER;
    l_viitenr      TEXT;
    v_asutus       RECORD;
    json_asutus_aa JSONB;
    l_pank         TEXT    = 'SWED';
    json_params    JSONB;

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
                         json_object) AS x (kpv TEXT, viitenr TEXT, aa TEXT, toiming TEXT, nimi TEXT,
                                            isikukood TEXT, kanal TEXT);

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
                      "pank": null
                    }'::JSONB
                    WHERE parentid = l_laps_id
                      AND asutusid = l_vanem_id;

                    count = count + 1;
                END IF;
                IF upper(json_record.toiming) = 'LISA'
                THEN
                    -- СОЗДАЕМ КАНАЛ БАНК,
                    IF json_record.kanal = 'HABAEE2X'
                    THEN
                        UPDATE lapsed.vanemad
                        SET properties = properties || '{
                          "pank": "SWED"
                        }'::JSONB
                        WHERE parentid = l_laps_id
                          AND asutusid = l_vanem_id;

                        l_pank = 'SWED';
                    ELSE
                        UPDATE lapsed.vanemad
                        SET properties = properties || '{
                          "pank": "SEB"
                        }'::JSONB
                        WHERE parentid = l_laps_id
                          AND asutusid = l_vanem_id;
                        l_pank = 'SEB';

                    END IF;

                    --  пишем в карточку номер расчетного счета
                    -- asutus_aa
                    json_asutus_aa = array_to_json((SELECT array_agg(row_to_json(aa.*))
                                                    FROM (SELECT json_record.aa AS aa,
                                                                 l_pank         AS pank) AS aa
                    ));
                    -- сохранение
                    SELECT a.id                          AS id,
                           a.regkood                     AS regkood,
                           a.nimetus                     AS nimetus,
                           a.omvorm                      AS omvorm,
                           a.kontakt                     AS kontakt,
                           a.aadress                     AS aadress,
                           a.tel                         AS tel,
                           a.email                       AS email,
                           a.mark                        AS mark,
                           a.properties ->> 'kmkr'       AS kmkr,
                           a.properties ->> 'kehtivus'   AS kehtivus,
                           a.properties ->> 'is_tootaja' AS is_tootaja,
                           a.muud                        AS muud,
                           a.tp                          AS tp,
                           json_asutus_aa                AS asutus_aa
                           INTO v_asutus
                    FROM libs.asutus a
                    WHERE id = l_vanem_id;

                    SELECT row_to_json(row) INTO json_params
                    FROM (SELECT l_vanem_id AS id,
                                 FALSE      AS import,
                                 v_asutus   AS data) row;

                    PERFORM libs.sp_salvesta_asutus(json_params :: JSON, user_id, user_rekvid);

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

GRANT EXECUTE ON FUNCTION lapsed.loe_panga_lepingud(JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.loe_panga_lepingud(JSONB, INTEGER, INTEGER) TO admin;



