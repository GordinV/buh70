DROP FUNCTION IF EXISTS lapsed.loe_makse(IN user_id INTEGER, IN INTEGER);


CREATE OR REPLACE FUNCTION lapsed.loe_makse(IN user_id INTEGER, IN l_id INTEGER,
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
    l_count          INTEGER        = 0;
    l_count_kokku    INTEGER        = 0;
    l_makse_summa    NUMERIC(12, 2) = 0;
    l_tasu_jaak      NUMERIC(12, 2) = 0;
    l_db_konto       TEXT           = '100100'; -- дебетовая (банк) сторона
    l_dokprop_id     INTEGER;
    l_target_user_id INTEGER        = user_id;
    l_user_kood      TEXT           = (SELECT kasutaja
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
    l_error_code     INTEGER        = 0;
    l_viitenr        TEXT;
    l_kas_vigane     BOOLEAN        = TRUE;
BEGIN
    -- ищем платежи
    FOR v_pank_vv IN
        SELECT *
        FROM lapsed.pank_vv v
        WHERE v.id = l_id
          AND (doc_id IS NULL OR doc_id = 0)
        ORDER BY kpv, id
        LOOP

            l_message = 'Tehingu nr.: ' || ltrim(rtrim(v_pank_vv.pank_id)) ||
                        ',Maksja:' || ltrim(rtrim(v_pank_vv.maksja));
            l_viitenr = v_pank_vv.viitenumber;

            -- ишем плательшика
            SELECT row_to_json(row) INTO json_object
            FROM (SELECT v_pank_vv.isikukood AS regkood,
                         v_pank_vv.maksja    AS nimetus,
                         v_pank_vv.iban      AS aa,
                         'ISIK'::TEXT        AS omvorm) row;

            l_maksja_id = (SELECT a.result FROM libs.create_new_asutus(user_id, json_object::JSONB) a);

            -- проверяем viitenumber
            -- если длина ссылки меньше 9, то это старый  номер
            IF (len(v_pank_vv.viitenumber::TEXT)) < 9
            THEN
                l_new_viitenr = lapsed.get_viitenumber_from_old(v_pank_vv.viitenumber::TEXT);

            ELSE
                l_new_viitenr = v_pank_vv.viitenumber;

            END IF;

            -- читаем ссылку и ищем учреждение
            l_rekvid = substr(l_new_viitenr, 1, len(l_new_viitenr::TEXT) - 7)::INTEGER;

            -- получим ид ребенка
            l_laps_id = left(right(l_new_viitenr::TEXT, 7), 6)::INTEGER;

            -- ищем пользователя в целевом цчреждении
            SELECT id INTO l_target_user_id
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

                SELECT row_to_json(row) INTO json_object
                FROM (SELECT 0       AS id,
                             v_vanem AS data) row;

                l_vanem = (SELECT lapsed.sp_salvesta_vanem(json_object :: JSONB, l_target_user_id, l_rekvid));

                -- в лог о создании нового плательщика
                IF (l_vanem IS NOT NULL AND l_vanem > 0)
                THEN
                    l_message = l_message || ',maksja puudub, uus maksja salvestatud';
                ELSE
                    l_error_code = 1;
                    l_kas_vigane = TRUE;
                    l_message = l_message || ',maksja puudub';
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
                            ORDER BY dp.id DESC
                            LIMIT 1
            );

            IF l_dokprop_id IS NULL
            THEN
                l_dokprop_id = (SELECT id
                                FROM com_dokprop l
                                WHERE (l.rekvId = l_rekvId OR l.rekvid IS NULL)
                                  AND kood = 'SMK'
                                ORDER BY id DESC
                                LIMIT 1
                );
            END IF;

            -- обнуляем счетчик найденных счетов
            l_count = 0;
            l_makse_summa = 0;

            -- запоминаем сумму платежа
            l_tasu_jaak = v_pank_vv.summa;
            -- ищем счет

            FOR v_arv IN
                SELECT a.id, a.jaak, a.rekvid, a.asutusid, a.asutus AS maksja
                FROM lapsed.cur_laste_arved a
                         INNER JOIN docs.arv arv ON a.id = arv.parentid
                WHERE a.rekvid = l_rekvid
                  AND (a.viitenr = l_new_viitenr OR a.viitenr::TEXT = '0'::TEXT || l_new_viitenr::TEXT)
                  AND a.jaak > 0
                  AND (arv.properties ->> 'ettemaksu_period' IS NULL OR
                       arv.properties ->> 'tyyp' = 'ETTEMAKS') -- только обычные счета или предоплаты
                ORDER BY a.kpv, a.id
                LOOP
                    -- считаем остаток не списанной суммы
                    l_makse_summa = CASE
                                        WHEN l_tasu_jaak > v_arv.jaak THEN v_arv.jaak
                                        ELSE l_tasu_jaak END;

                    -- создаем параметры для расчета платежкм
                    SELECT row_to_json(row) INTO json_object
                    FROM (SELECT v_arv.id         AS arv_id,
                                 l_maksja_id      AS maksja_id,
                                 l_dokprop_id     AS dokprop_id,
                                 l_new_viitenr    AS viitenumber,
                                 v_pank_vv.selg   AS selg,
                                 v_pank_vv.number AS number,
                                 v_pank_vv.kpv    AS kpv,
                                 v_pank_vv.aa     AS aa,
                                 v_pank_vv.iban   AS maksja_arve,
                                 l_makse_summa    AS summa) row;

                    -- создаем платежку
                    SELECT fnc.result, fnc.error_message INTO l_mk_id, l_error
                    FROM docs.create_new_mk(l_target_user_id, json_object) fnc;

                    -- проверим на соответствие платильщика
                    IF upper(v_arv.maksja)::TEXT <> upper(v_pank_vv.maksja)::TEXT
                    THEN
                        l_error = l_error || ' ' || upper(v_arv.maksja)::TEXT || '<>' || upper(v_pank_vv.maksja);
                        l_message = l_message || l_error;

                    END IF;

                    -- сохраняем пулученную информаци.
                    UPDATE lapsed.pank_vv v SET doc_id = l_mk_id, markused = l_error WHERE id = v_pank_vv.id;

                    IF l_mk_id IS NOT NULL AND l_mk_id > 0
                    THEN
                        l_count = l_count + 1;
                        l_count_kokku = l_count_kokku + 1;
                        -- считаем остаток средств
                        l_tasu_jaak = l_tasu_jaak - l_makse_summa;

                        -- lausend
                        PERFORM docs.gen_lausend_smk(l_mk_id, l_target_user_id);
                    END IF;

                    IF (l_tasu_jaak <= 0)
                    THEN
                        -- вся оплата списана
                        l_message = l_message || ',kogu summa kasutatud';
                        EXIT;
                    END IF;

                END LOOP;
            IF (l_tasu_jaak > 0)
            THEN
                -- оплата не списана
                -- создаем поручение с суммой равной остатку, без привязки к счету

                -- создаем параметры для расчета платежкм
                SELECT row_to_json(row) INTO json_object
                FROM (SELECT NULL             AS arv_id,
                             l_maksja_id      AS maksja_id,
                             l_dokprop_id     AS dokprop_id,
                             l_new_viitenr    AS viitenumber,
                             v_pank_vv.selg   AS selg,
                             v_pank_vv.number AS number,
                             v_pank_vv.kpv    AS kpv,
                             v_pank_vv.kpv    AS maksepaev,
                             v_pank_vv.aa     AS aa,
                             v_pank_vv.iban   AS maksja_arve,
                             l_tasu_jaak      AS summa) row;

                -- создаем платежку

                SELECT fnc.result, fnc.error_message INTO l_mk_id, l_error
                FROM docs.create_new_mk(l_target_user_id, json_object) fnc;

                -- сохраняем пулученную информаци.
                UPDATE lapsed.pank_vv v
                SET doc_id   = l_mk_id,
                    markused = 'Koostatud eetemaks ' || coalesce(l_error, '')
                WHERE id = v_pank_vv.id;

                IF l_mk_id IS NOT NULL AND l_mk_id > 0
                THEN
                    -- считаем остаток средств
                    l_tasu_jaak = 0;

                    -- lausend
                    PERFORM docs.gen_lausend_smk(l_mk_id, l_target_user_id);
                    -- log
                    l_message = l_message || ', koostatud ettemaks';
                    l_count_kokku = l_count_kokku + 1;
                    l_kas_vigane = FALSE;
                END IF;

            END IF;
            IF l_count = 0
            THEN
                UPDATE lapsed.pank_vv v SET markused = 'Arved ei leidnud' WHERE id = v_pank_vv.id;

                --log
                l_message = l_message || ',arved ei leidnud';
            END IF;
            -- report

            -- get mk number

            IF l_mk_id IS NOT NULL AND l_mk_id > 0
            THEN
                l_mk_number = (SELECT number FROM docs.mk WHERE parentid = l_mk_id);
                l_message = l_message || ',mk nr.:' || ltrim(rtrim(l_mk_number));
            ELSE
                l_mk_number = '';
            END IF;

            json_object = to_jsonb(row.*)
                          FROM (
                                   SELECT l_mk_id               AS doc_id,
                                          l_message             AS error_message,
                                          l_viitenr             AS viitenr,
                                          l_kas_vigane          AS kas_vigane,
                                          l_error_code::INTEGER AS error_code
                               ) row;
            data = coalesce(data, '[]'::JSONB) || json_object::JSONB;
        END LOOP;
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

            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            RETURN;
END;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.loe_makse(IN user_id INTEGER, IN INTEGER) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.loe_makse(IN user_id INTEGER, IN INTEGER) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.loe_makse(IN user_id INTEGER, IN INTEGER) TO arvestaja;


/*

SELECT lapsed.loe_makse(70, 9498)
*/
