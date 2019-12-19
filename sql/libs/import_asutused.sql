DROP FUNCTION IF EXISTS lapsed.import_asutused(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_asutused(IN data JSONB,
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
    v_asutus         RECORD;
    l_asutus_id      INTEGER;
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
                         json_object) AS x (isikukood TEXT, nimi TEXT, aadress TEXT);

            -- проверяем уникальность записи по pank_id
            l_asutus_id = (SELECT a.id
                           FROM libs.asutus a
                           WHERE a.regkood::TEXT = json_record.isikukood
                           ORDER BY id DESC
                           LIMIT 1);

            IF (l_asutus_id IS NULL)
            THEN
                -- подготавливаем параметры для сохранения
                -- в справочнике контр-агентов
                SELECT json_record.isikukood AS regkood,
                       json_record.nimi      AS nimetus,
                       json_record.aadress   AS aadress,
                       'ISIK'::TEXT          AS omvorm
                       INTO v_asutus;

                SELECT row_to_json(row) INTO json_save_params
                FROM (SELECT 0                             AS id,
                             (SELECT to_jsonb(v_asutus.*)) AS data) row;

                SELECT libs.sp_salvesta_asutus(json_save_params :: JSON, user_id, user_rekvid) INTO l_asutus_id;

                IF l_asutus_id > 0
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

GRANT EXECUTE ON FUNCTION lapsed.import_asutused (JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.import_asutused (JSONB, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.import_asutused (JSONB, INTEGER, INTEGER) TO dbkasutaja;


/*

SELECT error_code, result, error_message
                  FROM lapsed.import_vanemad( '[{"isikukood":"33905103722","nimi":"Pugachenko Adolf","aadress":"Rahu 34-51 20604 Narva"}]'::jsonb, 70::integer, 63::integer) as id


*/

