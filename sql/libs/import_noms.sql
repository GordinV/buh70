DROP FUNCTION IF EXISTS lapsed.import_noms(JSONB, INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.import_noms(IN data JSONB,
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
    v_nom            RECORD;
    l_nom_id         INTEGER;
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
                         json_object) AS x (kood TEXT, nimetus TEXT, dok TEXT, maksumaar TEXT, hind NUMERIC, uhik TEXT,
                                            koolituse_liik TEXT, konto TEXT, tegev TEXT, allikas TEXT, artikkel TEXT,
                                            inf3 TEXT, tunnus TEXT, proj TEXT);

            -- проверяем уникальность записи по pank_id
            l_nom_id = (SELECT n.id
                        FROM libs.nomenklatuur n
                        WHERE n.kood::TEXT = json_record.kood
                          AND n.rekvid = user_rekvid
                          AND n.status <> 3
                        LIMIT 1);

            IF (l_nom_id IS NULL)
            THEN
                -- подготавливаем параметры для сохранения
                -- в справочнике контр-агентов
                SELECT json_record.kood                                                            AS kood,
                       json_record.nimetus                                                         AS nimetus,
                       json_record.dok                                                             AS dok,
                       json_record.uhik                                                            AS uhik,
                       json_record.koolituse_liik                                                  AS oppe_tyyp,
                       REGEXP_REPLACE(json_record.maksumaar, '[^0-9]', '', 'g')::TEXT              AS vat,
                       json_record.hind                                                            AS hind,
                       json_record.konto                                                           AS konto,
                       json_record.tegev                                                           AS tegev,
                       json_record.allikas                                                         AS allikas,
                       json_record.artikkel                                                        AS artikkel,
                       CASE WHEN upper(json_record.inf3) = 'YES' THEN TRUE ELSE FALSE END::BOOLEAN AS kas_inf3,
                       json_record.tunnus                                                          AS tunnus,
                       json_record.proj                                                            AS proj
                       INTO v_nom;

                SELECT row_to_json(row) INTO json_save_params
                FROM (SELECT 0                          AS id,
                             (SELECT to_jsonb(v_nom.*)) AS data) row;

                SELECT libs.sp_salvesta_nomenclature(json_save_params :: JSON, user_id, user_rekvid) INTO l_nom_id;

                IF l_nom_id > 0
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

GRANT EXECUTE ON FUNCTION lapsed.import_noms (JSONB, INTEGER, INTEGER) TO arvestaja;
GRANT EXECUTE ON FUNCTION lapsed.import_noms (JSONB, INTEGER, INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.import_noms (JSONB, INTEGER, INTEGER) TO dbkasutaja;


/*

SELECT error_code, result, error_message
                  FROM lapsed.import_noms( '[{"kood":"322210-001","nimetus":"Arvestatud õppetasu","dok":"ARV","maksumaar":"0%","hind":"6","uhik":"kuu","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""},{"kood":"322210-002","nimetus":"Arvestatud õppetasu","dok":"ARV","maksumaar":"0%","hind":"7","uhik":"kuu","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""},{"kood":"322210-003","nimetus":"Arvestatud õppetasu","dok":"ARV","maksumaar":"0%","hind":"9","uhik":"kuu","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""},{"kood":"322210-005","nimetus":"Õppetasu soodustus","dok":"ARV","maksumaar":"0%","hind":"-6","uhik":"tk","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""},{"kood":"322210-006","nimetus":"Õppetasu soodustus","dok":"ARV","maksumaar":"0%","hind":"-7","uhik":"tk","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""},{"kood":"322210-007","nimetus":"Õppetasu soodustus","dok":"ARV","maksumaar":"0%","hind":"-9","uhik":"tk","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""},{"kood":"322210-009","nimetus":"Ümberarvestus (õppetasu)","dok":"ARV","maksumaar":"0%","hind":"0","uhik":"tk","koolituse_liik":"Põhiõpe","konto":"322210 Spordikoolide tulud","tegev":"08102 Sporditegevus (va spordikoolid)","allikas":"80 OMATULU","artikkel":"3222 TULUD SPORDI- JA PUHKEALASEST TEGEVUSEST","inf3":"Yes","tunnus":"","proj":""}]'::jsonb, 70::integer, 63::integer) as id


*/
