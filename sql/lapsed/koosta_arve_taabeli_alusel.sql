-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.koosta_arve_taabeli_alusel(IN user_id INTEGER,
                                                             IN l_laps_id INTEGER,
                                                             IN l_kpv DATE DEFAULT current_date,
                                                             OUT error_code INTEGER,
                                                             OUT result INTEGER,
                                                             OUT doc_type_id TEXT,
                                                             OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid        INTEGER = (SELECT rekvid
                               FROM ou.userid u
                               WHERE id = user_id
                               LIMIT 1);

    l_asutus_id     INTEGER = (SELECT asutusid
                               FROM lapsed.vanemad v
                                        INNER JOIN libs.asutus a ON a.id = v.asutusid
                               WHERE v.parentid = l_laps_id
                                 AND libs.check_asutus(a.id::INTEGER, l_rekvid ::INTEGER)
                                 AND v.staatus <> 3
                               ORDER BY (coalesce(v.properties ->> 'arved', 'ei')) DESC, v.id DESC
                               LIMIT 1);
    l_doklausend_id INTEGER;
    l_liik          INTEGER = 0;
    v_taabel        RECORD;
    json_object     JSONB;
    l_json_arve     JSON;
    json_arvrea     JSONB   = '[]';
    json_arvread    JSONB   = '[]';

    l_tp            TEXT    = '800699'; -- (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

    l_arv_id        INTEGER = 0;
    l_status        INTEGER;
    l_number        TEXT;
    l_arve_summa    NUMERIC = 0;
    l_taabel_ids    INTEGER[];
    i               INTEGER = 1;
    v_maksja        RECORD;
    jsonb_print     JSONB   = '[]';

BEGIN
    SELECT id,
           coalesce((v.properties ->> 'kas_paberil')::BOOLEAN, FALSE)::BOOLEAN AS kas_paber,
           coalesce((v.properties ->> 'kas_earve')::BOOLEAN, FALSE)::BOOLEAN   AS kas_earve,
           coalesce((v.properties ->> 'kas_email')::BOOLEAN, FALSE)::BOOLEAN   AS kas_email
           INTO v_maksja
    FROM lapsed.vanemad v
    WHERE asutusid = l_asutus_id
      AND v.parentid = l_laps_id;

    jsonb_print = jsonb_print || coalesce(CASE
                                              WHEN v_maksja.kas_paber THEN '[
                                                "paber"
                                              ]'::JSONB END, '[]'::JSONB) ::JSONB ||
                  coalesce(CASE
                               WHEN v_maksja.kas_email THEN '[
                                 "email"
                               ]'::JSONB END, '[]'::JSONB)::JSONB ||
                  coalesce(CASE
                               WHEN v_maksja.kas_earve THEN '[
                                 "earve"
                               ]'::JSONB END, '[]'::JSONB)::JSONB;



    -- will return docTypeid of new doc
    doc_type_id = 'ARV';

    -- ищем аналогичный счет в периоде
    -- критерий
    -- 1. получатель
    -- 2. ребенок
    -- 3. период
    -- 4. услуги из списка табеля


    -- читаем табель и создаем детали счета
    FOR v_taabel IN
        SELECT lt.nomid,
               coalesce(lt.kogus, 0)                                                 AS kogus,
               coalesce(lk.hind, 0)                                                  AS hind,
               coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)::NUMERIC           AS soodus,
               coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN AS kas_protsent,
               coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE)::BOOLEAN   AS kas_eraldi,
               (lk.properties ->> 'sooduse_alg')::DATE                               AS sooduse_alg,
               (lk.properties ->> 'sooduse_lopp')::DATE                              AS sooduse_lopp,
               CASE
                   WHEN coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN
                       THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0) / 100 * lk.hind
                   ELSE coalesce((lk.properties ->> 'soodus')::NUMERIC, 0) END *
               CASE
                   WHEN (lk.properties ->> 'sooduse_alg')::DATE <= l_kpv
                       AND (lk.properties ->> 'sooduse_lopp')::DATE >= l_kpv
                       THEN 1
                   ELSE 0 END                                                        AS real_soodus,
               (lk.properties ->> 'yksus')::TEXT || CASE
                                                        WHEN (lk.properties ->> 'all_yksus')::TEXT IS NOT NULL
                                                            THEN '(' || (lk.properties ->> 'all_yksus')::TEXT || ')'
                                                        ELSE '' END                  AS muud,
               lk.properties ->> 'yksus'                                             AS yksus,
               lk.properties ->> 'all_yksus'                                         AS all_yksus,
               lt.id                                                                 AS lapse_taabel_id,
               lk.id                                                                 AS lapse_kaart_id,
               coalesce((n.properties ->> 'vat')::NUMERIC, 0)::NUMERIC               AS vat,
               (n.properties::JSONB ->> 'konto')::VARCHAR(20)                        AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)                      AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)                       AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)                        AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)                      AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)                     AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)                     AS artikkel

        FROM lapsed.lapse_taabel lt
                 INNER JOIN lapsed.lapse_kaart lk ON lk.id = lt.lapse_kaart_id
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid

        WHERE lt.parentid = l_laps_id
          AND lt.staatus <> 3
          AND lt.kuu = month(l_kpv)
          AND lt.aasta = year(l_kpv)
        ORDER BY coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE) DESC


        LOOP
            -- формируем строку
            json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                          FROM (SELECT v_taabel.nomid                                          AS nomid,
                                                       v_taabel.kogus                                          AS kogus,
                                                       v_taabel.hind - v_taabel.real_soodus                    AS hind,
                                                       (v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus AS kbmta,
                                                       ((v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus *
                                                        (v_taabel.vat / 100))                                  AS kbm,
                                                       ((v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus *
                                                        (v_taabel.vat / 100)) +
                                                       (v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus AS summa,
                                                       v_taabel.tegev                                          AS kood1,
                                                       v_taabel.allikas                                        AS kood2,
                                                       v_taabel.rahavoog                                       AS kood3,
                                                       v_taabel.artikkel                                       AS kood5,
                                                       v_taabel.konto                                          AS konto,
                                                       v_taabel.tunnus,
                                                       v_taabel.projekt,
                                                       v_taabel.yksus,
                                                       v_taabel.all_yksus,
                                                       v_taabel.lapse_taabel_id,
                                                       v_taabel.muud || CASE
                                                                            WHEN v_taabel.real_soodus > 0
                                                                                THEN ' kasutatud soodustus summas ' ||
                                                                                     round(v_taabel.real_soodus::NUMERIC, 2)::TEXT
                                                                            ELSE '' END                        AS muud,
                                                       l_tp                                                    AS tp) row) :: JSONB;


            IF v_taabel.kas_eraldi
            THEN
                -- проверка на уже имеющийся счет

                SELECT d.id,
                       d.status,
                       a.number
                       INTO l_arv_id, l_status, l_number
                FROM docs.doc d
                         INNER JOIN docs.arv a ON a.parentid = d.id
                         INNER JOIN lapsed.liidestamine l ON l.docid = d.id
                         INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
                         INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.parentid
                         INNER JOIN lapsed.lapse_taabel lt ON lt.parentid = l.parentid AND
                                                              lt.id = coalesce((a1.properties ->> 'lapse_taabel_id')::INTEGER, 0) AND
                                                              lt.lapse_kaart_id = lk.id
                WHERE l.parentid = l_laps_id
                  AND lk.id = v_taabel.lapse_kaart_id
                  AND d.rekvid IN (SELECT rekvid FROM ou.userid u WHERE id = user_id)

                ORDER BY D.ID DESC
                LIMIT 1;

                IF coalesce(l_status, 0) <> 2
                THEN

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
                                                'Arve, taabeli alus ' || date_part('month', current_date)::TEXT ||
                                                '/' ||
                                                date_part('year', current_date)::TEXT || ' kuu eest' AS muud,
                                                json_arvrea                                          AS "gridData") row);

                    -- подготавливаем параметры для создания счета
                    SELECT row_to_json(row) INTO json_object
                    FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data) row;

                    IF (v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus > 0
                    THEN
                        SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;
                    END IF;
                END IF;
                -- обнуляем строку
                l_json_arve = '[]'::JSONB;
                l_taabel_ids[i] = v_taabel.lapse_taabel_id;

            ELSE
                json_arvread = json_arvread || json_arvrea;
                -- calc arve summa
                l_arve_summa = l_arve_summa + (v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus;

            END IF;
            i = i + 1;
        END LOOP;

    -- проверяем на имеющийся счет
    SELECT d.id,
           d.status,
           a.number
           INTO l_arv_id, l_status, l_number
    FROM docs.doc d
             INNER JOIN docs.arv a ON a.parentid = d.id
             INNER JOIN docs.arv1 a1 ON a.id = a1.parentid
             INNER JOIN lapsed.liidestamine l ON l.docid = d.id
             INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.parentid
             INNER JOIN lapsed.lapse_taabel lt ON lt.parentid = l.parentid AND lt.lapse_kaart_id = lk.id AND
                                                  (a1.properties ->> 'lapse_taabel_id')::INTEGER = lt.id

    WHERE l.parentid = l_laps_id
      AND NOT coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE)::BOOLEAN
      AND a.asutusid = l_asutus_id
      AND lt.aasta = date_part('year', l_kpv)
      AND lt.kuu = date_part('month', l_kpv)
      AND d.rekvid IN (SELECT rekvid FROM ou.userid u WHERE id = user_id)

    ORDER BY D.ID DESC
    LIMIT 1;

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
                                'Arve, taabeli alus ' || date_part('month', current_date)::TEXT || '/' ||
                                date_part('year', current_date)::TEXT || ' kuu eest' AS muud,
                                jsonb_print                                          AS print,
                                json_arvread                                         AS "gridData") row);

    -- подготавливаем параметры для создания счета
    SELECT row_to_json(row) INTO json_object
    FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data) row;


    -- check for arve summa
    IF l_arve_summa <= 0
    THEN
        result = 0;
        error_message = 'Dokumendi summa = 0';
        error_code = 1;
        RETURN;
    ELSE
        SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;

    END IF;


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

GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE) TO dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select lapsed.koosta_arve_taabeli_alusel(70, 16)
 */

