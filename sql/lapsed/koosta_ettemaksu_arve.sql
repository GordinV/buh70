-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.koosta_ettemaksu_arve(IN user_id INTEGER,
                                                        IN l_laps_id INTEGER,
                                                        IN l_kpv DATE DEFAULT current_date,
                                                        OUT error_code INTEGER,
                                                        OUT result INTEGER,
                                                        OUT doc_type_id TEXT,
                                                        OUT error_message TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid           INTEGER = (SELECT rekvid
                                  FROM ou.userid u
                                  WHERE id = user_id
                                  LIMIT 1);

    l_asutus_id        INTEGER = (SELECT asutusid
                                  FROM lapsed.vanem_arveldus v
                                           INNER JOIN libs.asutus a ON a.id = v.asutusid
                                  WHERE v.parentid = l_laps_id
                                    AND v.rekvid = l_rekvid
                                    AND libs.check_asutus(a.id::INTEGER, l_rekvid ::INTEGER)
                                  ORDER BY v.arveldus DESC,
                                           v.id DESC
                                  LIMIT
                                      1);

    l_doklausend_id    INTEGER;
    l_liik             INTEGER = 0;
    v_kaart            RECORD;
    json_object        JSONB;
    l_json_arve        JSON;
    json_arvread       JSONB   = '[]';

    l_tp               TEXT    = '800699'; -- (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

    l_arv_id           INTEGER = 0;
    l_status           INTEGER;
    l_number           TEXT;
    l_arve_summa       NUMERIC = 0;
    v_maksja           RECORD;
    jsonb_print        JSONB   = '[]';
    l_aa               TEXT    = (SELECT arve
                                  FROM ou.aa
                                  WHERE parentid IN (SELECT rekvid
                                                     FROM ou.userid
                                                     WHERE id = user_id)
                                    AND kassa = 1
                                  ORDER BY default_ DESC
                                  LIMIT 1);
    l_ettemaksu_period INTEGER = 1;
    l_tulu_arved       INTEGER = 0; -- кол-во доходных счетов, должно быть = кол-ву периодов
    l_db_konto         TEXT    = '103000'; -- согдасно описанию отдела культуры
    l_kr_konto         TEXT    = '203900';

BEGIN
    IF l_asutus_id IS NULL
    THEN
        -- контр-анет не найден, выходим
        result = 0;
        error_message = 'Puudub kontragent,  laps_id = ' || l_laps_id::TEXT;
        error_code = 1;
        RETURN;

    END IF;


    -- ищем ид конфигурации контировки

    l_doklausend_id = (SELECT dp.id
                       FROM libs.dokprop dp
                                INNER JOIN libs.library l ON l.id = dp.parentid
                       WHERE dp.rekvid = l_rekvid
                         AND (dp.details ->> 'konto')::TEXT = l_db_konto::TEXT
                         AND l.kood = 'ARV'
                       ORDER BY dp.id DESC
                       LIMIT 1
    );


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

    doc_type_id = 'ARV';
    -- will return docTypeid of new doc

    -- ищем аналогичный счет в периоде
    -- критерий
    -- 1. получатель
    -- 2. ребенок
    -- 3. период
    -- 4. услуги из списка предоплатных

    SELECT d.id,
           d.status,
           a.number
           INTO l_arv_id, l_status, l_number
    FROM docs.doc d
             INNER JOIN docs.arv a ON a.parentid = d.id
             INNER JOIN lapsed.liidestamine l ON l.docid = d.id
             INNER JOIN lapsed.lapse_kaart lk ON lk.parentid = l.parentid AND lk.rekvid = l_rekvid
             INNER JOIN docs.arv1 a1 ON a.id = a1.parentid AND a1.nomid = lk.nomid
    WHERE l.parentid = l_laps_id
      AND a.asutusid = l_asutus_id
      -- ищем счета в периоде
      AND l_kpv BETWEEN date(year(a.kpv), month(a.kpv), 1) AND (date(year(a.kpv), month(a.kpv), 1) + make_interval(
            months => ((lk.properties ->> 'ettemaksu_period')::INTEGER)))::DATE - 1
      AND (lk.properties ->> 'kas_ettemaks')::BOOLEAN
      AND (a.properties ->> 'tyyp')::TEXT = 'ETTEMAKS'
      AND d.rekvid = l_rekvid
    ORDER BY D.ID DESC
    LIMIT 1;

    IF l_arv_id IS NOT NULL AND l_status < 3
    THEN

        -- в этом периоде счет на предоплату уже авыписан
        error_code = 3;
        result = 0;
        error_message = 'Sellect ajavahemikul ettemaksuarve juba olemas';
        RETURN;
    END IF;


    -- читаем карту услуг и создаем детали счета
    FOR v_kaart IN
        SELECT lk.nomid,
               coalesce((lk.properties ->> 'ettemaksu_period')::INTEGER, 1) AS kogus,
               coalesce(lk.hind, 0)                                         AS hind,
               CASE
                   WHEN coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN
                       THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0) / 100 * lk.hind
                   ELSE coalesce((lk.properties ->> 'soodus')::NUMERIC, 0) END *
               CASE
                   WHEN (lk.properties ->> 'sooduse_alg')::DATE <= l_kpv
                       AND (lk.properties ->> 'sooduse_lopp')::DATE >= l_kpv
                       THEN 1
                   ELSE 0 END                                               AS real_soodus,

               (gr.nimetus::TEXT)::TEXT || CASE
                                               WHEN (lk.properties ->> 'all_yksus')::TEXT IS NOT NULL
                                                   THEN '(' || (lk.properties ->> 'all_yksus')::TEXT || ')'
                                               ELSE '' END                  AS muud,
               lk.properties ->> 'yksus'                                    AS yksus,
               lk.properties ->> 'all_yksus'                                AS all_yksus,
               coalesce((lk.properties ->> 'ettemaksu_period')::INTEGER, 0) AS ettemaksu_period,
               coalesce((n.properties ->> 'vat')::NUMERIC, 0)::NUMERIC      AS vat,
               l_kr_konto::VARCHAR(20)                                      AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)             AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)              AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)               AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)             AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)            AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)            AS artikkel

        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                 LEFT OUTER JOIN libs.library gr
                                 ON gr.library = 'LAPSE_GRUPP' AND gr.status <> 3 AND gr.rekvid = lk.rekvid AND
                                    gr.kood::TEXT = (lk.properties ->> 'yksus')::TEXT
        WHERE lk.parentid = l_laps_id
          AND lk.staatus <> 3
          AND (lk.properties ->> 'kas_ettemaks')::BOOLEAN
          AND coalesce((lk.properties ->> 'ettemaksu_period')::INTEGER, 0) > 0
          AND (lk.properties ->> 'alg_kpv' IS NULL OR
               (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
          AND (lk.properties ->> 'lopp_kpv' IS NULL OR (lk.properties ->> 'lopp_kpv')::DATE >= l_kpv)
          AND lk.rekvid = l_rekvid


        LOOP
            l_ettemaksu_period = CASE
                                     WHEN l_ettemaksu_period < v_kaart.ettemaksu_period THEN v_kaart.ettemaksu_period
                                     ELSE l_ettemaksu_period END;
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
                                                         v_kaart.real_soodus                                  AS soodustus,
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
        error_message = 'Dokumendi summa = 0, laps_id = ' || l_laps_id::TEXT;
        error_code = 1;
        RETURN;

    END IF;

    -- создаем параметры
    l_json_arve = (SELECT to_json(row)
                   FROM (SELECT coalesce(l_arv_id, 0) AS id,
                                l_number              AS number,
                                l_doklausend_id       AS doklausid,
                                l_liik                AS liik,
                                l_kpv                 AS kpv,
                                l_asutus_id           AS asutusid,
                                l_laps_id             AS lapsid,
                                'ETTEMAKS'            AS tyyp,
                                l_ettemaksu_period    AS ettemaksu_period,
                                l_aa                  AS aa,
                                jsonb_print           AS print,
                                'Ettemaksuarve ' || CASE
                                                        WHEN l_ettemaksu_period <= 1 THEN to_char(l_kpv, 'MM.YYYY')::TEXT
                                                        ELSE to_char(l_kpv, 'MM.YYYY')::TEXT || ' - ' ||
                                                             to_char(
                                                                     l_kpv + make_interval(months => l_ettemaksu_period - 1),
                                                                     'MM.YYYY')::TEXT END ||
                                ' kuu eest'           AS muud,

                                json_arvread          AS "gridData") row);

    -- подготавливаем параметры для создания счета
    SELECT row_to_json(row) INTO json_object
    FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data) row;

    SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;


    -- проверка

    IF l_arv_id IS NOT NULL AND l_arv_id > 0
    THEN
        -- контируем
        PERFORM docs.gen_lausend_arv(l_arv_id, user_id);

        -- создаем дохожные счета
        l_tulu_arved = (SELECT fnc.result FROM lapsed.koosta_arve_ettemaksuarve_alusel(user_id, l_arv_id) fnc);
        IF l_tulu_arved IS NOT NULL OR l_tulu_arved = 0
        THEN
            result = l_tulu_arved + 1;

        ELSE
            result = 0;
            error_message = 'Tulu arvete koostamise viga,  laps_id = ' || l_laps_id::TEXT;
            error_code = 1;
        END IF;
    ELSE
        result = 0;
        error_message = 'Dokumendi koostamise viga,  laps_id = ' || l_laps_id::TEXT;
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

GRANT EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) TO dbkasutaja;
GRANT EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) TO dbpeakasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) FROM arvestaja;

--GRANT EXECUTE ON FUNCTION lapsed.koosta_ettemaksu_arve(INTEGER, INTEGER, DATE) TO arvestaja;


/*
select lapsed.koosta_ettemaksu_arve(28,8692,'2020-09-05')

select * from lapsed.laps where id = 8692

select * from lapsed.lapse_taabel

update lapsed.lapse_taabel set staatus = 1 where id = 5

 */

