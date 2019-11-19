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
    l_rekvid     INTEGER = (SELECT rekvid
                            FROM ou.userid u
                            WHERE id = user_id
                            LIMIT 1);

    v_kaart      RECORD;
    json_object  JSONB;

    l_status     INTEGER;
    l_number     TEXT;
    l_arve_summa NUMERIC = 0;
    DOC_STATUS   INTEGER = 1; -- только активные услуги
    l_taabel_id  INTEGER;
    l_count      INTEGER = 0;
BEGIN
    doc_type_id = 'LAPSE_TAABEL';
    -- will return docTypeid of new doc

    -- делаем выборку услуг, не предоплатных

    FOR v_kaart IN
        SELECT lk.nomid,
               lk.id                     AS lapse_kaart_id,
               lk.parentid,
               n.uhik,
               CASE
                   WHEN coalesce((lk.properties ->> 'kogus')::NUMERIC, 0) > 0 THEN (lk.properties ->> 'kogus')::NUMERIC
                   WHEN upper(n.uhik) IN ('PAEV', 'PÄEV') THEN
                       (SELECT palk.get_work_days((SELECT to_jsonb(row)
                                                   FROM (SELECT date_part('month', l_kpv) AS kuu,
                                                                date_part('year', l_kpv)  AS aasta) row
                       )::JSON))
                   ELSE 1 END            AS kogus,
               date_part('month', l_kpv) AS kuu,
               date_part('year', l_kpv)  AS aasta
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.parentid = l_laps_id
          AND lk.staatus = DOC_STATUS
          AND (lk.properties ->> 'alg_kpv' IS NULL OR (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
          AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
          AND ((lk.properties ->> 'kas_ettemaks') is null or NOT (lk.properties ->> 'kas_ettemaks')::BOOLEAN)
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
            WHERE lt.lapse_kaart_id = v_kaart.lapse_kaart_id
              AND kuu = date_part('year', l_kpv)
              AND aasta = date_part('month', l_kpv)
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
                    l_count = l_count + 1;
                END IF;

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
select lapsed.arvesta_taabel(70, 40)

 */