DROP FUNCTION IF EXISTS lapsed.read_pank_vv(IN user_id INTEGER, IN TIMESTAMP);
DROP FUNCTION IF EXISTS lapsed.read_pank_vv(IN user_id INTEGER, IN TEXT);


CREATE OR REPLACE FUNCTION lapsed.read_pank_vv(IN user_id INTEGER, IN l_timestamp TEXT,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT error_message TEXT,
                                               OUT data JSONB)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_mk_id          INTEGER;
    v_arv            RECORD;
    json_object      JSONB;
    v_pank_vv        RECORD;
    l_rekvid         INTEGER;
    l_error          TEXT; -- извещение о том, что пошло не так
    l_count          INTEGER = 0;
    l_count_kokku    INTEGER = 0;
    l_db_konto       TEXT    = '100100'; -- дебетовая (банк) сторона
    l_dokprop_id     INTEGER;
    l_target_user_id INTEGER = user_id;
    l_user_kood      TEXT    = (SELECT kasutaja
                                FROM ou.userid
                                WHERE id = user_id
                                    LIMIT 1);
    l_maksja_id      INTEGER;
    l_laps_id        INTEGER;
    v_vanem          RECORD;
    l_vanem          INTEGER;
    l_new_viitenr    TEXT;
    l_mk_number      TEXT;
    l_message        TEXT;
    l_error_code     INTEGER = 0;
    l_viitenr        TEXT;
    l_kas_vigane     BOOLEAN = FALSE;
    l_jsonb          JSONB;
    l_viimane_rea    INTEGER;
    l_tunnus         TEXT;
BEGIN
    -- ищем платежи
    FOR v_pank_vv IN
        SELECT *
        FROM lapsed.pank_vv v
        WHERE timestamp::TIMESTAMP = l_timestamp::TIMESTAMP
          AND (doc_id IS NULL OR doc_id = 0)
          AND isikukood IS NOT NULL
            ORDER BY kpv
            , id
        LOOP
            l_message = 'Tehingu nr.: ' || ltrim(rtrim(v_pank_vv.pank_id)) ||
                        ',Maksja:' || ltrim(rtrim(v_pank_vv.maksja));
            l_viitenr = v_pank_vv.viitenumber;

            l_viimane_rea = v_pank_vv.id;

            -- ишем плательшика
            SELECT row_to_json(row)
            INTO json_object
            FROM (SELECT v_pank_vv.isikukood AS regkood,
                         v_pank_vv.maksja    AS nimetus,
                         v_pank_vv.iban      AS aa,
                         'ISIK'::TEXT        AS omvorm) row;

            l_maksja_id = (SELECT a.result FROM libs.create_new_asutus(user_id, json_object::JSONB) a);

            -- проверяем viitenumber
            -- если длина ссылки меньше 9, то это старый  номер
            IF (char_length(v_pank_vv.viitenumber::TEXT)) < 9
            THEN
                l_new_viitenr = lapsed.get_viitenumber_from_old(v_pank_vv.viitenumber::TEXT);

            ELSE
                l_new_viitenr = v_pank_vv.viitenumber;

            END IF;

            -- контроль длины
            IF len(l_new_viitenr) <> 10
            THEN
                -- ошибка на ВН
                l_new_viitenr = null;
            END IF;


            -- читаем ссылку и ищем учреждение
--            l_rekvid = substr(l_new_viitenr, 1, char_length(l_new_viitenr::TEXT) - 7)::INTEGER;
            l_rekvid = left(l_new_viitenr, 3)::INTEGER;


            -- получим ид ребенка
            l_laps_id = left(right(l_new_viitenr::TEXT, 7), 6)::INTEGER;
            -- проверим на наличие этого ид в бд
            if not exists (select id from lapsed.laps where id = l_laps_id and staatus < 3) then
                l_laps_id = null;
            END IF;

            -- задаем признак
            l_tunnus = (SELECT left(nimetus, 7) FROM ou.rekv WHERE id = l_rekvid);

            IF NOT empty(coalesce((SELECT properties ->> 'eritunnus' FROM lapsed.laps WHERE id = l_laps_id), ''))
            THEN
                l_tunnus = (SELECT properties ->> 'eritunnus' FROM lapsed.laps WHERE id = l_laps_id);
            END IF;


/*
Для всех учреждениях КРОМЕ 0911008, 0911012, 0911018, 0911027, 0911036, 0911038 применить правило не разбирать оплаты,
сделанные до 01.09.2022 (включительно 31.08.2022) с пометкой "Kuni 01.09.2022" (вместо"PUUDUB")

расширено до 01.01.2023. А. Варгунин 02.01.2023
 */

            IF v_pank_vv.kpv::DATE < '2023-01-01'::DATE
            THEN
                UPDATE lapsed.pank_vv v
                SET markused = 'Kuni 01.01.2023'
                WHERE id = v_pank_vv.id;

                l_message = coalesce(l_message, '') || ', Kuni 01.01.2023 ';
                l_mk_id = NULL;

            ELSE

                -- ищем пользователя в целевом цчреждении
                SELECT id
                INTO l_target_user_id
                FROM ou.userid
                WHERE rekvid = l_rekvid
                  AND kasutaja::TEXT = l_user_kood::TEXT
                    LIMIT 1;


                -- ищем родителя
                IF l_laps_id IS NOT NULL AND l_rekvid IS NOT NULL AND NOT exists(
                        SELECT id
                        FROM lapsed.vanemad v
                        WHERE v.asutusid = l_maksja_id
                          AND parentid = l_laps_id
                    )
                THEN
                    -- сохраним плательзика как родителя
                    SELECT l_laps_id AS parentid, l_maksja_id AS asutusid INTO v_vanem;

                    SELECT row_to_json(row)
                    INTO json_object
                    FROM (SELECT 0       AS id,
                                 v_vanem AS data) row;

                    l_vanem = (SELECT lapsed.sp_salvesta_vanem(json_object :: JSONB, l_target_user_id, l_rekvid));

                    -- в лог о создании нового плательщика
                    IF (l_vanem IS NOT NULL AND l_vanem > 0)
                    THEN
                        l_message = coalesce(l_message, '') || ',maksja puudub, uus maksja salvestatud';
                    ELSE
                        l_error_code = 1;
                        l_kas_vigane = TRUE;
                        l_message = coalesce(l_message, '') || ',maksja puudub';
                    END IF;

                END IF;

                -- ищем ид конфигурации контировки
                IF v_pank_vv.pank = 'EEUHEE2X' OR v_pank_vv.pank = '401'
                THEN
                    -- seb
                    l_db_konto = '10010008';
                ELSEIF v_pank_vv.pank = 'HABAEE2X' OR v_pank_vv.pank = '767'
                THEN
                    -- swed
                    l_db_konto = '10010002';
                END IF;

                l_dokprop_id = (SELECT dp.id
                                FROM libs.dokprop dp
                                         INNER JOIN libs.library l ON l.id = dp.parentid
                                WHERE dp.rekvid = l_rekvid
                                  AND (dp.details ->> 'konto')::TEXT = l_db_konto::TEXT
                                    ORDER BY registr DESC
                                    , dp.id DESC
                                    LIMIT 1
                );

                IF l_dokprop_id IS NULL
                THEN
                    l_dokprop_id = (SELECT id
                                    FROM com_dokprop l
                                    WHERE (l.rekvId = l_rekvId OR l.rekvid IS NULL)
                                      AND kood LIKE 'SMK'
                                        ORDER BY id DESC
                                        LIMIT 1
                    );
                END IF;

                -- обнуляем счетчик найденных счетов
                l_count = 0;

                l_mk_id = NULL;
                IF coalesce(l_maksja_id, 0) > 0
                THEN

                    -- создаем параметры для расчета платежкм
                    SELECT row_to_json(row)
                    INTO json_object
                    FROM (SELECT l_maksja_id      AS maksja_id,
                                 l_dokprop_id     AS dokprop_id,
                                 l_new_viitenr    AS viitenumber,
                                 v_pank_vv.selg   AS selg,
                                 v_pank_vv.number AS number,
                                 v_pank_vv.kpv    AS kpv,
                                 v_pank_vv.aa     AS aa,
                                 v_pank_vv.iban   AS maksja_arve,
                                 v_pank_vv.summa  AS summa,
                                 l_tunnus as tunnus) row;

                    -- создаем платежку
                    SELECT fnc.result, fnc.error_message
                    INTO l_mk_id, l_error
                    FROM docs.create_new_mk(l_target_user_id, json_object) fnc;
                END IF;

                IF l_mk_id IS NOT NULL AND l_mk_id > 0
                THEN
                    l_count = l_count + 1;
                    l_count_kokku = l_count_kokku + 1;
                    l_kas_vigane = FALSE;
                    l_message = coalesce(l_message, '') || ', MK ' || ltrim(rtrim(v_pank_vv.number)) || ' koostatud';

                    -- lausend
                    PERFORM docs.gen_lausend_smk(l_mk_id, l_target_user_id);

                    -- сохраняем полученную информаци.
                    UPDATE lapsed.pank_vv v
                    SET doc_id   = l_mk_id,
                        markused = l_error
                    WHERE id = v_pank_vv.id;

                ELSE
                    l_mk_number = '';

                    -- отчет об ошибке
                    l_jsonb = jsonb_build_object('viga', TRUE, 'error_message', l_message);
                    -- сохраняем полученную информаци.
                    UPDATE lapsed.pank_vv v
                    SET properties = coalesce(properties, '{}'::JSONB) || l_jsonb
                    WHERE id = v_pank_vv.id;

                END IF;

            END IF;

            -- report
            json_object = to_jsonb(row.*)
                          FROM (
                                   SELECT l_mk_id               AS doc_id,
                                          l_message             AS error_message,
                                          l_viitenr             AS viitenr,
                                          l_kas_vigane          AS kas_vigane,
                                          l_error_code::INTEGER AS error_code
                               ) row;
            data = coalesce(data, '[]'::JSONB) || json_object::JSONB;
            l_viimane_rea = NULL;
        END LOOP;

    IF (l_count_kokku > 0)
    THEN
        -- формируем извещение
        INSERT INTO ou.noticed (userid, teatis, task_name)
        VALUES (user_id, l_message, 'Loe maksed');
    END IF;

    result = l_count_kokku;
    error_code = l_error_code;
    error_message = l_message;

    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            json_object = to_jsonb(row.*)
                          FROM (
                                   SELECT NULL::INTEGER                     AS doc_id,
                                          l_message || ',' || error_message AS error_message,
                                          l_viitenr                         AS viitenr,
                                          TRUE                              AS kas_vigane,
                                          1::INTEGER                        AS error_code
                               ) row;
            data = coalesce(data, '[]'::JSONB) || json_object::JSONB;

            -- попробуем сохранить ошибку
            IF l_viimane_rea IS NOT NULL
            THEN
                -- отчет об ошибке
                l_jsonb = jsonb_build_object('viga', TRUE, 'error_message', l_message);

                UPDATE lapsed.pank_vv v
                SET properties = coalesce(properties, '{}'::JSONB) || l_jsonb
                WHERE id = l_viimane_rea;

            END IF;

            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.read_pank_vv(IN user_id INTEGER, IN TEXT) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.read_pank_vv(IN user_id INTEGER, IN TEXT) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.read_pank_vv(IN user_id INTEGER, IN TEXT) TO arvestaja;


/*
select * from lapsed.pank_vv
order by id desc limit 100

SELECT lapsed.read_pank_vv(8, '2023-01-16 16:49:23.454950')


       SELECT *
        FROM lapsed.pank_vv v
where kpv = '2023-01-01'
        WHERE timestamp::TIMESTAMP = '2023-01-16 16:49:23.454950'::TIMESTAMP
          AND (doc_id IS NULL OR doc_id = 0)
        ORDER BY kpv, id


doc_aa_id 11,  user_rekvid 63
[2019-12-10 20:52:57] [00000] l_tasu_summa 7.0000, l_kpv 2019-12-10
[2019-12-10 20:52:57] [00000] l_tasu_summa 7.0000, l_kpv 2019-12-10
[2019-12-10 20:52:57] [00000] l_mk_id 1616718, l_error <NULL>, v_arv.id 1616712
[2019-12-10 20:52:57] [00000] l_tasu_jaak 0.00
*/
