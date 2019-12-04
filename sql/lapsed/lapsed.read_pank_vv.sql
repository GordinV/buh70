DROP FUNCTION IF EXISTS lapsed.read_pank_vv(IN user_id INTEGER, IN TIMESTAMP);
DROP FUNCTION IF EXISTS lapsed.read_pank_vv(IN user_id INTEGER, IN TEXT);

CREATE OR REPLACE FUNCTION lapsed.read_pank_vv(IN user_id INTEGER, IN l_timestamp TEXT,
                                               OUT error_code INTEGER,
                                               OUT result INTEGER,
                                               OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$
DECLARE
    l_arv_id         INTEGER;
    l_dok            TEXT           = 'MK';
    l_mk_id          INTEGER;
    v_arv            RECORD;
    json_object      JSONB;
    v_params         RECORD;
    json_mk1         JSONB;
    l_pank_id        INTEGER;
    l_laps_id        INTEGER;
    v_pank_vv        RECORD;
    l_rekvid         INTEGER;
    l_error          TEXT; -- извещение о том, что пошло не так
    l_count          INTEGER        = 0;
    l_count_kokku    INTEGER        = 0;
    l_makse_summa    NUMERIC(12, 2) = 0;
    l_tasu_jaak      NUMERIC(12, 2) = 0;
    l_db_konto       TEXT           = '100100'; -- дебетовая (банк) сторона
    l_kr_konto       TEXT           = '103000'; -- кредитовая сторона
    l_dokprop_id     INTEGER;
    l_target_user_id INTEGER        = user_id;
    l_user_kood      TEXT           = (SELECT kasutaja
                                       FROM ou.userid
                                       WHERE id = user_id
                                       LIMIT 1);
BEGIN
    -- ищем платежи
    FOR v_pank_vv IN
        SELECT *
        FROM lapsed.pank_vv v
        WHERE timestamp::TIMESTAMP = l_timestamp::TIMESTAMP
          AND (doc_id IS NULL OR doc_id = 0)
        ORDER BY kpv, id
        LOOP

            -- читаем ссылку и ищем учреждение
            l_rekvid = substr(v_pank_vv.viitenumber, 1, len(v_pank_vv.viitenumber::TEXT) - 7)::INTEGER;

            -- ищем пользователя в целевом цчреждении
            SELECT id INTO l_target_user_id
            FROM ou.userid
            WHERE rekvid = l_rekvid AND kasutaja::TEXT = l_user_kood::TEXT
            LIMIT 1;

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
                SELECT id, jaak, rekvid, asutusid, asutus AS maksja
                FROM lapsed.cur_laste_arved a
                WHERE a.rekvid = l_rekvid
                  AND (a.viitenr = v_pank_vv.viitenumber OR a.viitenr::TEXT = '0'::TEXT || v_pank_vv.viitenumber::TEXT)
                  AND a.jaak > 0
                ORDER BY kpv ASC
                LOOP


                    -- считаем остаток не списанной суммы
                    l_makse_summa = CASE
                                        WHEN l_tasu_jaak > v_arv.jaak THEN v_arv.jaak
                                        ELSE l_tasu_jaak END;

                    -- создаем параметры для расчета платежкм
                    SELECT row_to_json(row) INTO json_object
                    FROM (SELECT v_arv.id              AS arv_id,
                                 l_dokprop_id          AS dokprop_id,
                                 v_pank_vv.viitenumber AS viitenumber,
                                 v_pank_vv.selg        AS selg,
                                 l_makse_summa         AS summa) row;

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
SELECT lapsed.read_pank_vv(70, '2019-11-04 19:36:00.119068')
SELECT lapsed.read_pank_vv(70,'2019-10-31 15:17:27.681873')

*/