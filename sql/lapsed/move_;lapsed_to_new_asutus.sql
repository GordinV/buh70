DROP FUNCTION IF EXISTS lapsed.move_laspsed_to_new_asutus(IN vana_asutus INTEGER,
    IN uus_asutus INTEGER);

CREATE OR REPLACE FUNCTION lapsed.move_laspsed_to_new_asutus(IN vana_asutus INTEGER,
                                                             IN uus_asutus INTEGER)
    RETURNS INTEGER
AS
$BODY$

DECLARE
    json_object       JSON;
    count             INTEGER = 0;
    l_id              INTEGER;
    json_save_params  JSONB;
    v_lapsed          RECORD;
    v_teenused        RECORD;
    v_yksus           RECORD;
    user_id           INTEGER;
    l_lopp_kpv        DATE;
    uus_grupp         INTEGER;
    vana_grupp        INTEGER;
    l_group_teenused  JSONB   = '[]';
    l_uus_teenused    JSONB   = '[]';
    l_group_params    JSONB   = '{}';
    l_group_teenus    JSONB   = '{}';
    l_vana_tyyp       INTEGER;
    l_uus_tyyp        INTEGER;
    l_vana_nom_id     INTEGER;
    l_uus_nom_id      INTEGER;
    l_jsonb_nom       JSONB;
    v_nom             RECORD;
    l_uus_yksuse_kood TEXT;
BEGIN
    /*    vana_asutus = 94;
        vana_grupp = 269154;
        uus_grupp = 273115;
        uus_asutus = 92;

1. Из садика 0911009 Narva Lasteaed Muinasjutt в 0911027 Narva Lasteaed Pongerjas
vana_asutus = 83;
        uus_asutus = 92;

    */
    user_id = (SELECT id FROM ou.userid WHERE kasutaja = 'vlad' AND rekvid = uus_asutus AND status < 3 LIMIT 1);

    -- 1. выбираем детей из группы
--    1. Вносятся все без исключения дети и сотрудники кроме тех, у кого услуги закончились ранее 01.08.2024
    FOR v_lapsed IN (
        SELECT lk.parentid,
               max((lk.properties ->> 'lopp_kpv')::DATE) AS lopp_kpv,
               lk.properties ->> 'yksus'                 AS yksus,
               l.isikukood
        FROM lapsed.laps l
                 INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
        WHERE lk.rekvid = vana_asutus
          AND l.staatus < 3
          AND lk.staatus < 3
--  limit 10
--          AND (lk.properties ->> 'yksus')::TEXT IN (SELECT kood FROM libs.library WHERE id = vana_grupp)
          AND (lk.properties ->> 'lopp_kpv')::DATE > '2024-08-01'::DATE
          AND NOT exists(SELECT id
                         FROM lapsed.lapse_kaart llk
                         WHERE llk.parentid = l.id
                           AND llk.rekvid = uus_asutus
                           AND llk.staatus < 3
                           AND llk.properties ->> 'alg_kpv' = '2024-08-01')
--          AND l.id NOT IN (14753, 4402) -- test
        GROUP BY lk.parentid, lk.properties ->> 'yksus', l.isikukood
    )
        LOOP
            RAISE NOTICE 'import laps %', v_lapsed.parentid;

            l_uus_yksuse_kood = overlay(v_lapsed.yksus PLACING '3' FROM 10 FOR 1);

            IF v_lapsed.yksus LIKE '%-T1'
            THEN
                l_uus_yksuse_kood = overlay(v_lapsed.yksus PLACING 'T3' FROM 10 FOR 2);
            END IF;

            -- ищем ид группы
            uus_grupp = (SELECT id
                         FROM libs.library l
                         WHERE l.kood = l_uus_yksuse_kood
                           AND l.rekvid = uus_asutus
                           AND l.status < 3
                           AND l.library = 'LAPSE_GRUPP');

            SELECT id,
                   kood,
                   overlay(l.nimetus PLACING '3' FROM 1 FOR 1) AS nimetus,
                   properties
            INTO v_yksus
            FROM libs.library l
            WHERE id = uus_grupp;

/*            6. Теперь про группы, которые надо создать с соответствующими услугами.
Если, например, ребенок в старом садике получает услугу в группе LAED-001-03 или LAED-002-01, то, при переносе в новом садике он должен получать услугу в группе соответственно:
                                                    Kood                 Nimetus
- старая LAED-001-03 - новая LAED-001-33 ... 33 Sõimerühm
- старая LAED-002-01 - новая LAED-002-31 ... 31 Lasteaiarühm
- старая Т1 - новая Т3 ... T3 Töötaja
*/
            IF uus_grupp IS NULL
            THEN

                -- старая группа

                vana_grupp = (SELECT id
                              FROM libs.library l
                              WHERE l.kood = v_lapsed.yksus
                                AND l.rekvid = vana_asutus
                                AND l.status < 3
                                AND l.library = 'LAPSE_GRUPP');

                v_yksus.nimetus = (SELECT overlay(l.nimetus PLACING '3' FROM 1 FOR 1) AS nimetus
                                   FROM libs.library l
                                   WHERE id = vana_grupp);

                -- создаем группу и услуги
                l_group_teenused = '[]'::JSONB;

                l_group_params = (SELECT properties::JSONB FROM libs.library WHERE id = vana_grupp);
                l_vana_tyyp = (l_group_params ->> 'tyyp')::INTEGER;
                l_uus_tyyp = (SELECT id
                              FROM libs.library l
                              WHERE kood IN (
                                  SELECT kood
                                  FROM libs.library
                                  WHERE id = l_vana_tyyp
                              )
                                AND l.library = 'KOOLITUSE_TYYP'
                                AND l.rekvid = uus_asutus
                                AND l.status < 3
                              ORDER BY id DESC
                              LIMIT 1
                );
                l_group_params = l_group_params || jsonb_build_object('tyyp', l_uus_tyyp);
                l_group_teenused = l_group_params -> 'teenused';
                RAISE NOTICE 'l_teenused %', l_group_teenused;
                l_uus_teenused = '[]'::JSONB;
                FOR i IN 0..jsonb_array_length(l_group_teenused)
                    LOOP
                        l_vana_nom_id = (l_group_teenused -> i ->> 'nomid')::INTEGER;
                        IF l_vana_nom_id IS NOT NULL
                        THEN

                            l_group_teenus = l_group_teenused -> i;

                            l_uus_nom_id = (SELECT id
                                            FROM libs.nomenklatuur n
                                            WHERE n.kood IN (SELECT kood FROM libs.nomenklatuur WHERE id = l_vana_nom_id)
                                              AND rekvid = uus_asutus
                                              AND n.dok = 'ARV'
                                              AND status < 3
                                            ORDER BY id DESC
                                            LIMIT 1
                            );

                            RAISE NOTICE 'l_uus_nom_id %, l_vana_nom_id %, i %', l_uus_nom_id, l_vana_nom_id, i;

                            IF l_uus_nom_id IS NULL
                            THEN
                                -- создаем копию услуги
                                SELECT n.*,
                                       n.properties ->> 'allikas'   AS allikas,
                                       n.properties ->> 'tegev'     AS tegev,
                                       n.properties ->> 'konto'     AS konto,
                                       n.properties ->> 'artikkel'  AS artikkel,
                                       n.properties ->> 'vat'       AS vat,
                                       n.properties ->> 'kas_inf3'  AS kas_inf3,
                                       n.properties ->> 'oppe_tyyp' AS oppe_tyyp
                                INTO v_nom
                                FROM libs.nomenklatuur n
                                WHERE id = l_vana_nom_id;
                                l_jsonb_nom = jsonb_build_object('allikas', v_nom.allikas,
                                                                 'tegev', v_nom.tegev,
                                                                 'artikkel', v_nom.artikkel,
                                                                 'konto', v_nom.konto,
                                                                 'vat', v_nom.vat,
                                                                 'kas_inf3', v_nom.kas_inf3,
                                                                 'oppe_tyyp', v_nom.oppe_tyyp,
                                                                 'dok', v_nom.dok,
                                                                 'kood', v_nom.kood,
                                                                 'nimetus', v_nom.nimetus,
                                                                 'uhik', v_nom.uhik,
                                                                 'hind', v_nom.hind);
                                l_jsonb_nom = jsonb_build_object('id', 0, 'data', l_jsonb_nom);
--                            l_uus_nom_id = libs.sp_salvesta_nomenclature(l_jsonb_nom, user_id, uus_asutus);

                                IF coalesce(l_uus_nom_id, 0) = 0
                                THEN
                                    RAISE EXCEPTION 'Uus nom koostamine viga %', l_vana_nom_id;
                                END IF;

                            END IF;
                            -- подменяем
                            l_group_teenus =
                                        l_group_teenus || jsonb_build_object('nomid', l_uus_nom_id, 'id', l_uus_nom_id);
                            RAISE NOTICE 'l_vana_nomid ->> %, uus ->  %', l_vana_nom_id, l_uus_nom_id;
                            l_uus_teenused = l_uus_teenused || l_group_teenus;
                            l_group_params = l_group_params ||
                                             jsonb_build_object('kood', l_uus_yksuse_kood, 'nimetus', v_yksus.nimetus,
                                                                'teenused', l_uus_teenused, 'gridData', l_uus_teenused);

                        END IF;

                    END LOOP;

--                RAISE NOTICE 'l_group_params %', l_group_params;

                uus_grupp =
                        lapsed.sp_salvesta_lapse_grupp((jsonb_build_object('id', 0, 'data', l_group_params)), user_id,
                                                       uus_asutus);
                IF coalesce(uus_grupp, 0) = 0
                THEN
                    RAISE EXCEPTION 'Viga, koostamise uus grupp %', vana_grupp;
                END IF;

            END IF;

            RAISE NOTICE 'Alustan teenused koopeerimine';
            -- копируем услуги ребенку
            FOR v_teenused IN
                SELECT lk.nomid,
                       (lk.properties ->> 'kogus')::NUMERIC            AS kogus,
                       CASE
                           WHEN (lk.properties ->> 'sooduse_alg') IS NOT NULL AND
                                (lk.properties ->> 'sooduse_alg')::DATE < '2024-08-01'::DATE
                               AND (lk.properties ->> 'sooduse_lopp')::DATE >= '2024-08-01'::DATE
                               THEN '2024-08-01'
                           ELSE NULL END                               AS sooduse_alg,
                       CASE
                           WHEN (lk.properties ->> 'sooduse_lopp') IS NOT NULL AND
                                (lk.properties ->> 'sooduse_lopp')::DATE < '2024-08-01'::DATE THEN NULL
                           ELSE (lk.properties ->> 'sooduse_lopp') END AS sooduse_lopp,
                       (lk.properties ->> 'soodus')                    AS soodus,
                       (lk.properties ->> 'kas_protsent')              AS kas_protsent,

                       lk.hind
                FROM lapsed.lapse_kaart lk
                WHERE lk.parentid = v_lapsed.parentid
                  AND lk.rekvid = vana_asutus
                  AND lk.staatus < 3
                  AND (lk.properties ->> 'lopp_kpv')::DATE > '2024-08-01'::DATE
                LOOP
                    RAISE NOTICE 'v_lapsed.lopp_kpv %, v_lapsed.parentid %',v_lapsed.lopp_kpv, v_lapsed.parentid;

                    l_uus_nom_id = (SELECT id
                                    FROM libs.nomenklatuur n
                                    WHERE n.kood IN (SELECT kood FROM libs.nomenklatuur WHERE id = v_teenused.nomid)
                                      AND rekvid = uus_asutus
                                      AND n.dok = 'ARV'
                                      AND status < 3
                                    ORDER BY id DESC
                                    LIMIT 1
                    );

                    -- параметры
                    json_object = to_jsonb(row)
                                  FROM (SELECT 0                               AS id,
                                               v_lapsed.parentid               AS parentid,
                                               l_uus_nom_id                    AS nomid,
                                               ltrim(rtrim(l_uus_yksuse_kood)) AS yksus,
                                               NULL                            AS all_yksus,
                                               v_teenused.kogus                AS kogus,
                                               v_teenused.hind                 AS hind,
                                               v_teenused.sooduse_alg          AS sooduse_alg,
                                               v_teenused.sooduse_lopp         AS sooduse_lopp,
                                               CASE
                                                   WHEN v_teenused.sooduse_alg IS NULL THEN NULL
                                                   ELSE v_teenused.soodus END  AS soodus,
                                               v_teenused.kas_protsent         AS kas_protsent,
                                               '2024-08-01'                    AS alg_kpv,
                                               v_lapsed.lopp_kpv
                                       ) ROW;

                    -- сохраняем
                    -- подготавливаем параметры для сохранения
                    SELECT row_to_json(row)
                    INTO json_save_params
                    FROM (SELECT 0           AS id,
                                 json_object AS data) row;

                    SELECT lapsed.sp_salvesta_lapse_kaart(json_save_params :: JSONB, user_id, uus_asutus) INTO l_id;
                    RAISE NOTICE 'l_id %', l_id;
                    IF l_id > 0
                    THEN
                        count = count + 1;
                    ELSE
                        RAISE EXCEPTION 'salvestamine eba onnestus, %',json_save_params;
                    END IF;


                END LOOP;
-- 5. Виитенумбер будет принимающего учреждения. Но древний виитенумбер типа 9360071 пусть тоже останется прежний.

            IF NOT exists(SELECT id FROM lapsed.viitenr WHERE rekv_id = uus_asutus AND isikukood = v_lapsed.isikukood)
            THEN
                INSERT INTO lapsed.viitenr (isikukood, rekv_id, viitenumber)
                SELECT v.isikukood, uus_asutus, v.viitenumber
                FROM lapsed.viitenr v
                WHERE v.rekv_id = vana_asutus
                  AND v.isikukood = v_lapsed.isikukood
                LIMIT 1;
            END IF;

            -- Ответственный остается тот, кто был в прежнем учреждении
            IF NOT exists(
                    SELECT id
                    FROM lapsed.vanem_arveldus va
                    WHERE va.parentid = v_lapsed.parentid
                      AND va.rekvid = uus_asutus
                )
            THEN
                INSERT INTO lapsed.vanem_arveldus (parentid, asutusid, rekvid, arveldus, properties, kas_email,
                                                   kas_paberil)
                SELECT parentid, asutusid, uus_asutus, arveldus, properties, kas_email, kas_paberil
                FROM lapsed.vanem_arveldus va
                WHERE parentid = v_lapsed.parentid
                  AND rekvid = vana_asutus;
            END IF;

        END LOOP;

/*    FOR v_lapsed IN
        SELECT lk.*
        FROM lapsed.laps l
                 INNER JOIN lapsed.lapse_kaart lk ON l.id = lk.parentid
        WHERE lk.rekvid = vana_asutus
--  limit 10
          AND lk.properties ->> 'yksus' IN (SELECT kood FROM libs.library WHERE id = vana_grupp)
          AND (lk.properties ->> 'lopp_kpv')::date >= '2023-06-30'::DATE
        LOOP
            UPDATE lapsed.lapse_kaart
            SET properties = properties || jsonb_build_object('lopp_kpv', '2023-06-30')
            WHERE id = v_lapsed.id;
        END LOOP;
*/ RETURN count;

END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;


/*
SELECT *
FROM lapsed.move_laspsed_to_new_asutus(99, 96);

SELECT *
FROM lapsed.move_laspsed_to_new_asutus(83, 92);


DROP FUNCTION IF EXISTS lapsed.move_laspsed_to_new_asutus(IN vana_asutus INTEGER,
    IN uus_asutus INTEGER);
*/


