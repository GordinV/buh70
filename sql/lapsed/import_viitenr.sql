DROP FUNCTION IF EXISTS lapsed.import_viitenr(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_viitenr(IN data JSONB,
                                                 IN user_id INTEGER,
                                                 IN user_rekvid INTEGER,
                                                 OUT result INTEGER,
                                                 OUT error_code INTEGER,
                                                 OUT error_message TEXT,
                                                 OUT tulemus JSONB)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName     TEXT;
    json_object  JSON;
    count        INTEGER = 0;
    json_record  RECORD;
    l_viitenr_id INTEGER;
    l_rekv_id    INTEGER;
    v_tulemus    RECORD;
    l_params     JSONB;
BEGIN
    SELECT kasutaja
    INTO userName
    FROM ou.userid u
    WHERE u.rekvid = user_rekvid
      AND u.id = user_id;
    IF userName IS NULL
    THEN
        error_message = 'User not found';
        SELECT error_message, error_code INTO v_tulemus;
        l_params = to_jsonb(v_tulemus);
        tulemus = coalesce(tulemus, '[]'::JSONB) || l_params::JSONB;
        RETURN;
    END IF;

    FOR json_object IN
        SELECT *
        FROM jsonb_array_elements(data)
        LOOP

            SELECT *
            INTO json_record
            FROM json_to_record(
                         json_object) AS x (isikukood TEXT, viitenr TEXT, asutus TEXT, nimetus TEXT);

            -- ищем ид учреждения
            SELECT id
            INTO l_rekv_id
            FROM ou.rekv
            WHERE nimetus LIKE json_record.asutus || '%'
            ORDER BY id DESC
            LIMIT 1;

            IF l_rekv_id IS NOT NULL
            THEN
                -- проверяем уникальность записи

                RAISE NOTICE 'l_rekv_id %', l_rekv_id;
                IF exists(SELECT 1 FROM lapsed.viitenr WHERE viitenumber = json_record.viitenr)
                THEN
                    DELETE FROM lapsed.viitenr WHERE viitenumber = json_record.viitenr;
                END IF;

                IF NOT exists(SELECT 1 FROM lapsed.viitenr WHERE viitenumber = json_record.viitenr)
                THEN
                    INSERT INTO lapsed.viitenr (isikukood, rekv_id, viitenumber)
                    VALUES (ltrim(rtrim(json_record.isikukood)), l_rekv_id, ltrim(rtrim(json_record.viitenr))) RETURNING id INTO l_viitenr_id;

                    IF l_viitenr_id > 0
                    THEN
                        l_params = to_jsonb(row.*)
                                   FROM (
                                            SELECT l_viitenr_id  AS id,
                                                   json_record.isikukood,
                                                   json_record.viitenr,
                                                   l_rekv_id     AS rekv_id,
                                                   'Salvestatud' AS status
                                        ) row;
                        count = count + 1;
                    ELSE
                        l_params = to_jsonb(row.*)
                                   FROM (
                                            SELECT 0                          AS id,
                                                   json_record.isikukood,
                                                   json_record.viitenr,
                                                   l_rekv_id                  AS rekv_id,
                                                   'Salvestamine ebaõnnestus' AS status
                                        ) row;

                    END IF;
                ELSE
                    l_params = to_jsonb(row.*)
                               FROM (
                                        SELECT 0         AS id,
                                               json_record.isikukood,
                                               json_record.viitenr,
                                               l_rekv_id AS rekv_id,
                                               'Olemas'  AS status
                                    ) row;

                END IF;
            ELSE
                l_params = to_jsonb(row.*)
                           FROM (
                                    SELECT 0               AS id,
                                           json_record.isikukood,
                                           json_record.viitenr,
                                           0               AS rekv_id,
                                           'Puudub asutus' AS status
                                ) row;

            END IF;

            -- report
            tulemus = coalesce(tulemus, '[]'::JSONB) || l_params::JSONB;
            RAISE NOTICE 'tulemus %, l_params %',tulemus, l_params;
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

/*
select  lapsed.import_viitenr('[{"isikukood":"60911153738",
"viitenr":"8446514", "asutus":"0951004", "nimetus":"0951004 Narva Muusikakool T"}]'::jsonb,
                                                 2477,
                                                 63)

select * from ou.userid where rekvid = 63 and kasutaja = 'vlad'
 */