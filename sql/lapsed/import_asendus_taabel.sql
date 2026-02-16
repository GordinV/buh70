DROP FUNCTION IF EXISTS lapsed.import_asendus_taabelid(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.import_asendus_taabelid(IN user_id INTEGER,
                                                          IN user_rekvid INTEGER,
                                                          IN l_kpv DATE,
                                                          OUT error_code INTEGER,
                                                          OUT result INTEGER,
                                                          OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    userName         TEXT;
    json_object      JSON;
    count            INTEGER = 0;
    l_lapse_kaart_id INTEGER;
    l_nom_id         INTEGER;
    l_id             INTEGER;
    json_save_params JSONB;
    v_taabel         RECORD;

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

    FOR v_taabel IN
        SELECT at.*, n.kood AS nom_kood, l.isikukood, l.nimi
        FROM lapsed.asendus_taabel at
                 INNER JOIN libs.nomenklatuur n ON at.nomid = n.id
                 INNER JOIN lapsed.laps l ON l.id = at.parentid
        WHERE left(viitenumber, 3)::INTEGER = user_rekvid
          AND at.aasta = date_part('year', l_kpv)
          AND at.kuu = date_part('month', l_kpv)
          AND at.staatus = 1 -- только не импортированные
--          AND l.isikukood = '62006290071'
        LOOP

            -- ищем услугу по коду другово учреждения
            SELECT id
            INTO l_nom_id
            FROM libs.nomenklatuur n
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim(v_taabel.nom_kood))
              AND rekvid = user_rekvid
              AND n.status <> 3
            ORDER BY id
            LIMIT 1;

            -- ищем запись в карте
            SELECT id
            INTO l_lapse_kaart_id
            FROM lapsed.lapse_kaart lk
            WHERE parentid = v_taabel.parentid
              AND nomid = l_nom_id
              AND rekvid = user_rekvid
              AND staatus <> 3
              AND (lk.properties ->> 'alg_kpv')::DATE <= l_kpv
            ORDER BY (lk.properties ->> 'lopp_kpv')::DATE DESC
            LIMIT 1;

            IF (l_nom_id IS NULL OR l_lapse_kaart_id IS NULL)
            THEN
                result = 0;
                error_message = 'Puudub teenused, Isikukood:' || v_taabel.isikukood || ', Nimi:' || v_taabel.nimi ||
                                ', Kood:' || v_taabel.nom_kood;
                error_code = 1;
                RETURN;
            END IF;


            json_object = to_jsonb(row)
                          FROM (SELECT 0                       AS id,
                                       v_taabel.parentid       AS parentid,
                                       l_lapse_kaart_id        AS lapse_kaart_id,
                                       l_nom_id                AS nomid,
                                       v_taabel.kogus          AS kogus,
                                       0                       AS soodustus,
                                       v_taabel.hind::NUMERIC  AS hind,
                                       v_taabel.summa::NUMERIC AS summa,
                                       v_taabel.kuu::INTEGER   AS kuu,
                                       v_taabel.aasta::INTEGER AS aasta,
                                       v_taabel.id             AS asendus_id,
                                       TRUE                    AS kas_asendus
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
                -- табель создан как отдельный
                error_message = 'Isikukood: ' || v_taabel.isikukood || ', Nimi:' || v_taabel.nimi;
            ELSE
                RAISE EXCEPTION 'salvestamine eba onnestus, %',json_save_params;
            END IF;

        END LOOP;

    -- расшифруем платежи
    result = count;
    RETURN;

END ;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.import_asendus_taabelid(INTEGER, INTEGER, DATE) TO arvestaja;


/*

SELECT *
FROM lapsed.import_asendus_taabelid(2477,
  63,'2023-05-31')


            SELECT id, *
            FROM libs.nomenklatuur n
            WHERE ltrim(rtrim(kood)) = ltrim(rtrim('322000-004'))
              AND rekvid = 63
              AND n.status <> 3
            ORDER BY id
            LIMIT 1;


*/