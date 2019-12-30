DROP FUNCTION IF EXISTS lapsed.import_groups(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_groups(IN data JSONB,
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
    v_group          RECORD;
    v_details        RECORD;
    v_row            RECORD;
    l_group_id       INTEGER;
    details          JSONB   = '[]'::JSONB;
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
                         json_object) AS x (asutus TEXT,
                                            kood TEXT,
                                            nimetus TEXT,
                                            grupi_liik TEXT,
                                            koolituse_tyyp TEXT,
                                            all_yksused_1 TEXT,
                                            all_yksused_2 TEXT,
                                            all_yksused_3 TEXT,
                                            all_yksused_4 TEXT,
                                            all_yksused_5 TEXT,
                                            teenus TEXT, kogus NUMERIC, hind NUMERIC);

            -- проверяем уникальность записи по kood
            l_group_id = (SELECT l.id
                          FROM libs.library l
                              WHERE l.kood::TEXT = json_record.kood
                                   AND library = 'LAPSE_GRUPP'
                                   AND l.rekvid = user_rekvid
                                   AND l.status <> 3
                              LIMIT 1);

            -- подготавливаем параметры для сохранения
            IF l_group_id IS NULL
            THEN

                -- готовим список услуг
                FOR v_details IN
                    WITH qryJsons AS (
                        SELECT *
                        FROM jsonb_to_recordset(data::JSONB)
                                 AS x(asutus TEXT, kood TEXT, nimetus TEXT, grupi_liik TEXT,
                                      all_yksus_1 TEXT,
                                      all_yksus_2 TEXT,
                                      all_yksus_3 TEXT,
                                      all_yksus_4 TEXT,
                                      all_yksus_5 TEXT,
                                      koolituse_liik TEXT,
                                      teenus TEXT, kogus NUMERIC, hind NUMERIC)
                    )
                    SELECT *
                    FROM qryJsons
                        WHERE kood = json_record.kood
                    LOOP
                        SELECT n.id,
                               n.id             AS nomid,
                               v_details.teenus AS kood,
                               n.nimetus        AS nimetus,
                               v_details.kogus  AS kogus,
                               v_details.hind   AS hind
                               INTO v_row
                        FROM libs.nomenklatuur n
                            WHERE n.rekvid = user_rekvid
                                 AND kood = v_details.teenus
                                 AND n.dok = 'ARV'
                            ORDER BY id DESC LIMIT 1;

                        IF v_row IS NOT NULL
                        THEN
                            details = details::JSONB || row_to_json(v_row)::JSONB;
                        END IF;
                    END LOOP;


                SELECT coalesce(l_group_id, 0)   AS id,
                       json_record.kood          AS kood,
                       json_record.nimetus       AS nimetus,
                       json_record.all_yksused_1 AS all_yksus_1,
                       json_record.all_yksused_2 AS all_yksus_2,
                       json_record.all_yksused_3 AS all_yksus_3,
                       json_record.all_yksused_4 AS all_yksus_4,
                       json_record.all_yksused_5 AS all_yksus_5,
                       details                   AS gridData
                       INTO v_group;

                SELECT row_to_json(row) INTO json_save_params
                FROM (SELECT 0                            AS id,
                             (SELECT to_jsonb(v_group.*)) AS data) row;

                SELECT lapsed.sp_salvesta_lapse_grupp(json_save_params :: JSONB, user_id, user_rekvid) INTO l_group_id;

                IF l_group_id > 0
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

GRANT EXECUTE ON FUNCTION lapsed.import_groups (JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.import_groups (JSONB, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.import_groups (JSONB, INTEGER, INTEGER) TO dbkasutaja;


/*

SELECT error_code, result, error_message
                  FROM lapsed.import_groups( '[{"asutus":"",
                  "kood":"SPOR-001-01",
                  "nimetus":"01 Jäähoki",
                  "grupi_liik":"Spordikool",
                  "koolituse_tyyp":"Spordikool",
                  "all_yksused_1":"Jäähoki",
                  "all_yksused_2":"",
                  "all_yksused_3":"",
                  "all_yksused_4":"",
                  "all_yksused_5":"",
                  "teenus": "322210-002",
                    "kogus": 1,
                    "hind": 7}]' ::jsonb, 68::integer, 66::integer) as id

{"asutus":"0810203 Narva Paemurru Spordikool T",
"kood":"SPOR-001-01",
"nimetus":"01 Jäähoki",
"grupi_liik":"Spordikool",
"koolituse_tyyp":"Jäähoki",
"all_yksused_1":"","all_yksused_2":"","all_yksused_3":"","all_yksused_4":"","all_yksused_5":"","koolituse_liik":"322210-002","teenus":"1","kogus":"7"}

*/

