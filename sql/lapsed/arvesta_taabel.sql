-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.arvesta_taabel(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.arvesta_taabel(IN user_id INTEGER,
                                                 IN l_laps_id INTEGER,
                                                 IN l_kpv DATE DEFAULT current_date,
                                                 OUT error_code INTEGER,
                                                 OUT result INTEGER,
                                                 OUT doc_type_id TEXT,
                                                 OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid    INTEGER = (SELECT rekvid
                           FROM ou.userid u
                           WHERE id = user_id
                           LIMIT 1);

    v_kaart     RECORD;
    json_object JSONB;

    l_status    INTEGER;
    DOC_STATUS  INTEGER = 1; -- только активные услуги
    l_taabel_id INTEGER;
    l_count     INTEGER = 0;
    l_kogus     NUMERIC = 0;
BEGIN
    doc_type_id = 'LAPSE_TAABEL';
    -- will return docTypeid of new doc

    -- делаем выборку услуг, не предоплатных

    FOR v_kaart IN
        SELECT lk.nomid,
               lk.id                                             AS lapse_kaart_id,
               lk.parentid,
               n.uhik,
               coalesce((lk.properties ->> 'kogus')::NUMERIC, 0) AS kogus,
               date_part('month'::TEXT, l_kpv::DATE)             AS kuu,
               date_part('year'::TEXT, l_kpv::DATE)              AS aasta
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.parentid = l_laps_id
          AND lk.staatus = DOC_STATUS
          AND (lk.properties ->> 'alg_kpv' IS NULL OR
               (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
          AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
          AND ((lk.properties ->> 'kas_ettemaks') IS NULL OR NOT (lk.properties ->> 'kas_ettemaks')::BOOLEAN)
        LOOP
            -- ищем аналогичный табель в периоде
            -- критерий
            -- 2. ребенок
            -- 3. период
            -- 4. услуги

            IF upper(v_kaart.uhik) IN ('PAEV', 'PÄEV')
            THEN
                SELECT sum(kogus) INTO v_kaart.kogus
                FROM lapsed.day_taabel1 t1
                         INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                WHERE t.staatus <> 3
                  AND t.rekv_id = l_rekvid
                  AND t1.laps_id = v_kaart.parentid
                  AND t1.nom_id = v_kaart.nomid
                  AND month(t.kpv) = month(l_kpv::DATE)
                  AND year(t.kpv) = year(l_kpv::DATE);
            END IF;

            SELECT lt.id,
                   lt.staatus
                   INTO l_taabel_id, l_status
            FROM lapsed.lapse_taabel lt
            WHERE lt.lapse_kaart_id = v_kaart.lapse_kaart_id
              AND aasta = date_part('year'::TEXT, l_kpv::DATE)
              AND kuu = date_part('month'::TEXT, l_kpv::DATE)
            LIMIT 1;

            IF l_taabel_id IS NULL OR l_status <> 2
            THEN
                -- продолжаем расчет

                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row) INTO json_object
                FROM (SELECT coalesce(l_taabel_id, 0)     AS id,
                             (SELECT to_jsonb(v_kaart.*)) AS data) row;

                RAISE NOTICE 'json_object %', json_object;

                SELECT lapsed.sp_salvesta_lapse_taabel(json_object :: JSONB, user_id, l_rekvid) INTO l_taabel_id;

                IF l_taabel_id > 0
                THEN
                    l_count = l_count + 1;
                END IF;

                -- установить статус на табель
                UPDATE lapsed.day_taabel
                SET staatus   = 2,
                    ajalugu   = ajalugu ||
                                (SELECT to_jsonb(row)
                                 FROM (SELECT now()    AS created,
                                              userName AS user) row),
                    timestamp = now()
                WHERE staatus = 1
                  AND rekv_id = l_rekvid
                  AND month(kpv) = month(l_kpv)
                  AND year(kpv) = year(kpv)
                  AND id IN (
                    SELECT t1.parent_id
                    FROM lapsed.day_taabel1 t1
                             INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                    WHERE month(t.kpv) = month(l_kpv)
                      AND year(t.kpv) = year(l_kpv)
                      AND t.rekv_id = l_rekvid
                      AND t1.laps_id = v_kaart.parentid
                );

            END IF;

        END LOOP;


    -- проверка

    IF l_count > 0
    THEN
        result = l_taabel_id ;
    ELSE
        result = 0;
        error_message = 'Dokumendi koostamise viga';
        error_code = 1;
    END IF;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE 'error % %', SQLERRM, SQLSTATE;
            error_code = 1;
            error_message = SQLERRM;
            result = 0;
            RETURN;
END ;
$BODY$
    LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select lapsed.arvesta_taabel(70, 16,'2019-03-30')

 */