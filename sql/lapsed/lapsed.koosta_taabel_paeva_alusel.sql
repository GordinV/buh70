-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_taabel_paeva_alusel(JSONB, INTEGER);

CREATE OR REPLACE FUNCTION lapsed.koosta_taabel_paeva_alusel(IN params JSONB,
                                                             IN user_id INTEGER,
                                                             OUT error_code INTEGER,
                                                             OUT result INTEGER,
                                                             OUT doc_type_id TEXT,
                                                             OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid       INTEGER = (SELECT rekvid
                              FROM ou.userid u
                              WHERE id = user_id
                              LIMIT 1);
    doc_id         INTEGER = params ->> 'doc_id';
    l_kpv          DATE    = params ->> 'kpv';
    json_object    JSONB;

    v_laste_taabel RECORD;
    v_taabel       RECORD;
    l_taabel_id    INTEGER;
    l_status       INTEGER;
    json_ajalugu   JSONB;
    l_count        INTEGER = 0;
    userName       TEXT;

BEGIN
    -- логгирование

    json_ajalugu = to_jsonb(row)
                   FROM (SELECT now()    AS created,
                                userName AS user) row;


    doc_type_id = 'LAPSE_TAABEL';
    -- will return docTypeid of new doc

    -- делаем выборку услуг, не предоплатных

    FOR v_laste_taabel IN
        SELECT lk.id                               AS lapse_kaart_id,
               t1.laps_id                          AS parentid,
               t1.nom_id                           AS nomid,
               sum(coalesce(t1.kogus, 0))::NUMERIC AS kogus,
               month(l_kpv)                        AS kuu,
               year(l_kpv)                         AS aasta
        FROM lapsed.day_taabel t
                 INNER JOIN lapsed.day_taabel1 t1 ON t.id = t1.parent_id
                 INNER JOIN lapsed.lapse_kaart lk
                            ON lk.nomid = t1.nom_id AND lk.parentid = t1.laps_id AND lk.staatus <> 3

        WHERE t.grupp_id = doc_id
          AND year(t.kpv) = year(l_kpv)
          AND month(t.kpv) = month(l_kpv)
--          AND t.kpv <= l_kpv
          AND t.staatus <> 3
        GROUP BY lk.id, t1.laps_id, t1.nom_id
        LOOP
            -- ищем аналогичный табель в периоде
            -- критерий
            -- 2. ребенок
            -- 3. период
            -- 4. услуги

            SELECT lt.id,
                   lt.staatus
                   INTO l_taabel_id, l_status
            FROM lapsed.lapse_taabel lt
            WHERE lt.lapse_kaart_id = v_laste_taabel.lapse_kaart_id
              AND aasta = year(l_kpv)
              AND kuu = month(l_kpv)
            LIMIT 1;

            IF l_taabel_id IS NULL OR l_status <> 2
            THEN
                -- продолжаем расчет

                -- подготавливаем параметры для сохранения
                SELECT row_to_json(row) INTO json_object
                FROM (SELECT coalesce(l_taabel_id, 0)            AS id,
                             (SELECT to_jsonb(v_laste_taabel.*)) AS data) row;

                SELECT lapsed.sp_salvesta_lapse_taabel(json_object :: JSONB, user_id, l_rekvid) INTO l_taabel_id;

                IF l_taabel_id > 0
                THEN
                    -- устанавливаем связи
                    UPDATE lapsed.day_taabel1
                    SET taabel_id = l_taabel_id
                    WHERE parent_id IN (
                        SELECT id
                        FROM lapsed.day_taabel
                        WHERE grupp_id = doc_id
                          AND month(kpv) = month(l_kpv)
                          AND year(kpv) = year(l_kpv)
                          AND staatus <> 3
                    )
                      AND laps_id = v_laste_taabel.parentid
                      AND nom_id = v_laste_taabel.nomid;

                    -- меняем статус табеля
                    UPDATE lapsed.day_taabel
                    SET staatus   = 2,
                        timestamp = now(),
                        ajalugu   = coalesce(ajalugu, '[]') :: JSONB || json_ajalugu
                    WHERE grupp_id = doc_id
                      AND month(kpv) = month(l_kpv)
                      AND year(kpv) = year(l_kpv)
                      AND staatus <> 3;

                    -- обновляем счетчик
                    l_count = l_count + 1;
                END IF;

            END IF;

        END LOOP;
    result = l_count;
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

REVOKE EXECUTE ON FUNCTION lapsed.koosta_taabel_paeva_alusel(JSONB, INTEGER) FROM dbkasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.koosta_taabel_paeva_alusel(JSONB, INTEGER) FROM dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_taabel_paeva_alusel(JSONB, INTEGER) TO arvestaja;


/*
select lapsed.koosta_paevad_taabel('{"kpv":"2020-03-20","grupp_id":"214107"}', 70)

*/