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
BEGIN
    doc_type_id = 'LAPSE_TAABEL';
    -- will return docTypeid of new doc

    -- делаем выборку услуг, не предоплатных

    FOR v_kaart IN
        SELECT *
        FROM lapsed.lapse_kaart
        WHERE parentid = l_laps_id
          AND staatus = DOC_STATUS
          AND NOT (properties ->> 'kas_ettemaks')::BOOLEAN
        LOOP

            -- ищем аналогичный табель в периоде
            -- критерий
            -- 2. ребенок
            -- 3. период
            -- 4. услуги

            SELECT d.id,
                   d.status,
                   a.number
                   INTO l_taabel_id, l_status
            FROM lapsed.lapse_taabel lt
            WHERE lt.parentid = l_laps_id
              AND lt.nomid = l_asutus_id
              AND date_part('year', a.kpv) = date_part('year', l_kpv)
              AND date_part('month', a.kpv) = date_part('month', l_kpv)
              AND (lk.properties ->> 'kas_ettemaks')::BOOLEAN
              AND d.rekvid IN (SELECT rekvid FROM ou.userid u WHERE id = user_id)
            ORDER BY D.ID DESC
            LIMIT 1;

        END LOOP;


    IF l_arv_id IS NOT NULL AND l_status = 2
    THEN
        -- в этом периоде счет на предоплату уже авыписан
        error_code = 3;
        result = 0;
        error_message = 'Sellect ajavahemikul ettemaksuarve juba olemas';
        RETURN;
    END IF;


    -- читаем табель и создаем детали счета
    FOR v_kaart IN
        SELECT lk.nomid,
               1                                                       AS kogus,
               coalesce(lk.hind, 0)                                    AS hind,
               CASE
                   WHEN coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN
                       THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0) / 100 * lk.hind
                   ELSE coalesce((lk.properties ->> 'soodus')::NUMERIC, 0) END *
               CASE
                   WHEN (lk.properties ->> 'sooduse_alg')::DATE <= l_kpv
                       AND (lk.properties ->> 'sooduse_lopp')::DATE >= l_kpv
                       THEN 1
                   ELSE 0 END                                          AS real_soodus,

               (lk.properties ->> 'yksus')::TEXT || CASE
                                                        WHEN (lk.properties ->> 'all_yksus')::TEXT IS NOT NULL
                                                            THEN '(' || (lk.properties ->> 'all_yksus')::TEXT || ')'
                                                        ELSE '' END    AS muud,
               lk.properties ->> 'yksus'                               AS yksus,
               lk.properties ->> 'all_yksus'                           AS all_yksus,
               coalesce((n.properties ->> 'vat')::NUMERIC, 0)::NUMERIC AS vat,
               (n.properties::JSONB ->> 'konto')::VARCHAR(20)          AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)        AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)         AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)          AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)        AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)       AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)       AS artikkel

        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.parentid = l_laps_id
          AND lk.staatus <> 3
          AND (lk.properties ->> 'kas_ettemaks')::BOOLEAN
        LOOP
            -- формируем строку
            json_arvread = json_arvread || (SELECT row_to_json(row)
                                            FROM (SELECT v_kaart.nomid                                        AS nomid,
                                                         v_kaart.kogus                                        AS kogus,
                                                         (v_kaart.hind - v_kaart.real_soodus)                 AS hind,
                                                         (v_kaart.hind - v_kaart.real_soodus) * v_kaart.kogus AS kbmta,
                                                         ((v_kaart.hind - v_kaart.real_soodus) * v_kaart.kogus *
                                                          (v_kaart.vat / 100))                                AS kbm,
                                                         ((v_kaart.hind - v_kaart.real_soodus) * v_kaart.kogus *
                                                          (v_kaart.vat / 100)) +
                                                         (v_kaart.hind - v_kaart.real_soodus) * v_kaart.kogus AS summa,
                                                         v_kaart.tegev                                        AS kood1,
                                                         v_kaart.allikas                                      AS kood2,
                                                         v_kaart.rahavoog                                     AS kood3,
                                                         v_kaart.artikkel                                     AS kood5,
                                                         v_kaart.konto                                        AS konto,
                                                         v_kaart.tunnus,
                                                         v_kaart.projekt,
                                                         v_kaart.yksus,
                                                         v_kaart.all_yksus,
                                                         v_kaart.muud || CASE
                                                                             WHEN v_kaart.real_soodus > 0
                                                                                 THEN ' kasutatud soodustus summas ' || round(v_kaart.real_soodus, 2)::TEXT
                                                                             ELSE '' END                      AS muud,
                                                         l_tp                                                 AS tp) row) :: JSONB;

            -- calc arve summa
            l_arve_summa = l_arve_summa + (v_kaart.hind - v_kaart.real_soodus) * v_kaart.kogus;

        END LOOP;


    -- check for arve summa

    IF l_arve_summa <= 0
    THEN
        result = 0;
        error_message = 'Dokumendi summa = 0';
        error_code = 1;
        RETURN;

    END IF;

    -- создаем параметры
    l_json_arve = (SELECT to_json(row)
                   FROM (SELECT coalesce(l_arv_id, 0)                                AS id,
                                l_number                                             AS number,
                                l_doklausend_id                                      AS doklausid,
                                l_liik                                               AS liik,
                                l_kpv                                                AS kpv,
                                l_kpv + 15                                           AS tahtaeg,
                                l_asutus_id                                          AS asutusid,
                                l_laps_id                                            AS lapsid,
                                'Ettemaksuarve ' || date_part('month', current_date)::TEXT || '/' ||
                                date_part('year', current_date)::TEXT || ' kuu eest' AS muud,
                                json_arvread                                         AS "gridData") row);

    -- подготавливаем параметры для создания счета
    SELECT row_to_json(row) INTO json_object
    FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data) row;

    SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;

    -- проверка

    IF l_arv_id IS NOT NULL AND l_arv_id > 0
    THEN
        result = l_arv_id;
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
select lapsed.koosta_arve_taabeli_alusel(70, 16)

select * from lapsed.laps where staatus = 1

select * from lapsed.lapse_taabel

update lapsed.lapse_taabel set staatus = 1 where id = 5
 */