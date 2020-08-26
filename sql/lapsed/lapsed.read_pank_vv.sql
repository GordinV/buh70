
DROP FUNCTION IF EXISTS lapsed.read_pank_vv(IN user_id INTEGER, IN TIMESTAMP);
DROP FUNCTION IF EXISTS lapsed.read_pank_vv(IN user_id INTEGER, IN TEXT);


CREATE OR REPLACE FUNCTION lapsed.read_pank_vv(IN user_id INTEGER, IN l_timestamp TEXT,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT error_message TEXT)
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
BEGIN
    -- ищем платежи
    FOR v_pank_vv IN
        SELECT *
        FROM lapsed.pank_vv v
        WHERE timestamp::TIMESTAMP = l_timestamp::TIMESTAMP
          AND (doc_id IS NULL OR doc_id = 0)
        ORDER BY kpv, id
        LOOP
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

            -- обнуляем счетчик найденных счетов
            l_count = 0;
            l_makse_summa = 0;

            -- запоминаем сумму платежа
            l_tasu_jaak = v_pank_vv.summa;
            -- ищкм счет

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
                END IF;


            END IF;
            IF l_count = 0
            THEN
                UPDATE lapsed.pank_vv v SET markused = 'Arved ei leidnud' WHERE id = v_pank_vv.id;
            END IF;

        END LOOP;
    result = l_count_kokku;
    RETURN;
EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
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

SELECT lapsed.read_pank_vv(70, '2020-02-15 10:36:32.748115')


       SELECT *
        FROM lapsed.pank_vv v
        WHERE timestamp::TIMESTAMP = '2020-02-15 10:36:32.748115'::TIMESTAMP
          AND (doc_id IS NULL OR doc_id = 0)
        ORDER BY kpv, id


doc_aa_id 11,  user_rekvid 63
[2019-12-10 20:52:57] [00000] l_tasu_summa 7.0000, l_kpv 2019-12-10
[2019-12-10 20:52:57] [00000] l_tasu_summa 7.0000, l_kpv 2019-12-10
[2019-12-10 20:52:57] [00000] l_mk_id 1616718, l_error <NULL>, v_arv.id 1616712
[2019-12-10 20:52:57] [00000] l_tasu_jaak 0.00
*/
