-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.arvesta_taabel(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.arvesta_taabel(IN user_id INTEGER,
                                                 IN l_laps_id INTEGER,
                                                 IN l_kpv DATE DEFAULT current_date,
                                                 OUT error_code INTEGER,
                                                 OUT result INTEGER,
                                                 OUT doc_type_id TEXT,
                                                 OUT error_message TEXT,
                                                 OUT viitenr TEXT)
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
    userName    TEXT    = (SELECT ametnik
                           FROM ou.userid
                           WHERE id = user_id);
    l_message   TEXT;
    v_laps      RECORD;
BEGIN
    doc_type_id = 'LAPSE_TAABEL';
    -- will return docTypeid of new doc

    -- логируем имя, кому считаем
    SELECT *, lapsed.get_viitenumber(l_rekvid, l_laps_id) AS viitenr INTO v_laps
    FROM lapsed.laps
    WHERE id = l_laps_id;

    l_message = 'Isikukood: ' || ltrim(rtrim(v_laps.isikukood)) || ', Nimi:' || ltrim(rtrim(v_laps.nimi));
    viitenr = v_laps.viitenr;
    -- делаем выборку услуг, не предоплатных

    FOR v_kaart IN
        SELECT lk.nomid,
               lk.id                                             AS lapse_kaart_id,
               lk.parentid,
               n.uhik,
               ltrim(rtrim(n.kood))                              AS kood,
               coalesce((lk.properties ->> 'kogus')::NUMERIC, 0) AS kogus,
               date_part('month'::TEXT, l_kpv::DATE)             AS kuu,
               date_part('year'::TEXT, l_kpv::DATE)              AS aasta
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.parentid = l_laps_id
          AND lk.rekvid = l_rekvid
          AND lk.staatus = DOC_STATUS
          AND (lk.properties ->> 'alg_kpv' IS NULL OR
               (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
--          AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
          AND (lk.properties ->> 'lopp_kpv' IS NULL OR make_date(year((lk.properties ->> 'lopp_kpv')::date), month((lk.properties ->> 'lopp_kpv')::date),1) + interval '1 month' >= l_kpv)          
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

                SELECT lapsed.sp_salvesta_lapse_taabel(json_object :: JSONB, user_id, l_rekvid) INTO l_taabel_id;

                IF l_taabel_id > 0
                THEN
                    l_message = l_message || ',kood:' || ltrim(rtrim(v_kaart.kood)) || ' taabel koostatud';
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

            ELSE
                l_message = l_message || ' taabel juba arvestatud ja kinni';

            END IF;

        END LOOP;

    IF (l_count = 0)
    THEN
        l_message = l_message || ':teenused ei leidnud';
    END IF;

    result = coalesce(l_taabel_id, 0);
    error_message = l_message;
    viitenr = v_laps.viitenr;
    -- проверка
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

REVOKE EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) FROM dbkasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) FROM dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select lapsed.arvesta_taabel(70, 5573,'2020-10-30')

 */