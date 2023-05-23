-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION lapsed.koosta_arve_taabeli_alusel(IN user_id INTEGER,
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
    l_rekvid        INTEGER = (SELECT rekvid
                               FROM ou.userid u
                               WHERE id = user_id
                                   LIMIT 1);

    l_asutus_id     INTEGER = (SELECT asutusid
                               FROM lapsed.vanem_arveldus v
                                        INNER JOIN libs.asutus a ON a.id = v.asutusid
                               WHERE v.parentid = l_laps_id
                                 AND v.rekvid = l_rekvid
                                 AND arveldus
                                   ORDER BY v.id DESC
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
    l_aa            TEXT    = (SELECT arve
                               FROM ou.aa
                               WHERE parentid IN (SELECT rekvid FROM ou.userid WHERE id = user_id)
                                 AND kassa = 1
                                   ORDER BY default_ DESC
                                   LIMIT 1);

    l_db_konto      TEXT    = '10300029'; -- согдасно описанию отдела культуры
    v_laps          RECORD;
    l_arve_kogus    NUMERIC = 0; -- для проверки кол-ва услуг в счете
    l_selg          TEXT; -- доп. пояснение

BEGIN

    IF date_part('year', l_kpv) < 2023
    THEN
        -- контроль года
        result = 0;
        error_message = 'Vale aasta';
        error_code = 1;
        RETURN;

    END IF;

    SELECT *,
           lapsed.get_viitenumber(l_rekvid, l_laps_id) AS viitenr,
           l.properties ->> 'eritunnus'                AS eritunnus
    INTO v_laps
    FROM lapsed.laps l
    WHERE id = l_laps_id;

    viitenr = v_laps.viitenr;

    IF l_asutus_id IS NULL
    THEN
        -- контр-анет не найден, выходим
        result = 0;
        error_message = 'Puudub kontragent, Isikukood:' || v_laps.isikukood || ', Nimi:' || v_laps.nimi;
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
               coalesce(lt.hind)                                                     AS hind,
               coalesce(lt.soodustus)                                                AS soodustus,
               coalesce(lt.summa)                                                    AS summa,
               coalesce(lt.vahe)                                                     AS vahe,
               coalesce((lk.properties ->> 'kas_protsent')::BOOLEAN, FALSE)::BOOLEAN AS kas_protsent,
               coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE)::BOOLEAN   AS kas_eraldi,
               (lk.properties ->> 'sooduse_alg')::DATE                               AS sooduse_alg,
               (lk.properties ->> 'sooduse_lopp')::DATE                              AS sooduse_lopp,
               coalesce(n.properties ->> 'tyyp', '')                                 AS tyyp,
               lt.soodustus                                                          AS real_soodus,
               'Üksus: ' || (gr.nimetus::TEXT)::TEXT                                 AS muud,
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
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)                     AS artikkel,
               lt.umberarvestus,
               coalesce(lt.muud, '')                                                 AS markused,
               lt.properties ->> 'kas_asendus'                                       AS kas_asendus,
               at.rekvid                                                             AS asendus_rekvid,
               ltrim(rtrim(CASE WHEN r.muud IS NULL or empty(r.muud)  THEN r.nimetus ELSE r.muud END)) AS asendus_asutus,
               at.id                                                                 AS asendus_id
        FROM lapsed.lapse_taabel lt
                 INNER JOIN lapsed.lapse_kaart lk
                            ON lk.id = lt.lapse_kaart_id AND lt.nomid = lk.nomid AND lt.rekvid = lk.rekvid
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
                 LEFT OUTER JOIN libs.library gr ON gr.library = 'LAPSE_GRUPP' AND gr.rekvid = lt.rekvid AND
                                                    gr.kood::TEXT = (lk.properties ->> 'yksus')::TEXT
                 LEFT OUTER JOIN lapsed.asendus_taabel at ON at.id = (lt.properties ->> 'asendus_id')::INTEGER
                 LEFT OUTER JOIN ou.rekv r ON r.id = at.rekvid

        WHERE lt.parentid = l_laps_id
          AND lt.staatus <> 3
          AND lk.staatus <> 3
          AND gr.status <> 3
          AND lt.kuu = month(l_kpv)
          AND lt.aasta = year(l_kpv)
          AND lk.rekvid = l_rekvid
          AND n.rekvid = lk.rekvid
          AND (lt.summa <> 0 OR lt.kogus <> 0)
            ORDER BY coalesce((lk.properties ->> 'kas_eraldi')::BOOLEAN, FALSE) DESC


        LOOP

            -- если украинец, то ставим признак 3008
            IF NOT empty(coalesce(v_laps.eritunnus, ''))
            THEN
                v_taabel.tunnus = v_laps.eritunnus;
            END IF;

            l_arve_kogus = l_arve_kogus + v_taabel.kogus;
            -- формируем строку
            json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                          FROM (SELECT v_taabel.nomid                                  AS nomid,
                                                       v_taabel.kogus                                  AS kogus,
                                                       v_taabel.hind,
                                                       v_taabel.summa                                  AS kbmta,
                                                       v_taabel.summa * (v_taabel.vat / 100)           AS kbm,
                                                       (v_taabel.summa *
                                                        (v_taabel.vat / 100)) +
                                                       round(CASE
                                                                 WHEN TRUE THEN 1 -- временно
                                                                 WHEN v_taabel.tyyp = 'SOODUSTUS' AND NOT v_taabel.umberarvestus
                                                                     THEN 0

                                                                 ELSE 1 END * v_taabel.summa, 2) -
                                                       v_taabel.vahe                                   AS summa,
                                                       v_taabel.tegev                                  AS kood1,
                                                       v_taabel.allikas                                AS kood2,
                                                       v_taabel.rahavoog                               AS kood3,
                                                       v_taabel.artikkel                               AS kood5,
                                                       v_taabel.konto                                  AS konto,
                                                       v_taabel.tunnus,
                                                       v_taabel.projekt,
                                                       v_taabel.yksus,
                                                       v_taabel.all_yksus,
                                                       v_taabel.lapse_taabel_id,
                                                       v_taabel.real_soodus                            AS soodustus,
                                                       v_taabel.muud || CASE
/*                                                                            WHEN v_taabel.real_soodus > 0
                                                                                THEN ' kasutatud soodustus summas ' ||
                                                                                     round(v_taabel.real_soodus::NUMERIC, 2)::TEXT
*/
                                                                            WHEN v_taabel.umberarvestus
                                                                                THEN ' Ümberarvestus '
                                                                            WHEN v_taabel.asendus_id IS NOT NULL THEN
                                                                                ' (Osutatavad teenused: ' || v_taabel.asendus_asutus || ')'
                                                                            ELSE (CASE WHEN len(coalesce(v_taabel.muud, '')) > 0 THEN ',' ELSE '' END) ||
                                                                                 v_taabel.markused END AS muud,
                                                       v_taabel.asendus_id                             AS asendus_id,
                                                       l_tp                                            AS tp) row) :: JSONB;

/*            IF v_taabel.kas_asendus IS NOT NULL
            THEN
                l_selg = CASE
                             WHEN v_taabel.asendus_asutus IS NOT NULL
                                 THEN ' (Osutatavad teenused: ' || v_taabel.asendus_asutus || ')'
                             ELSE '' END;
            END IF;
*/

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
                                   FROM (SELECT coalesce(l_arv_id, 0)                                   AS id,
                                                l_number                                                AS number,
                                                l_doklausend_id                                         AS doklausid,
                                                l_liik                                                  AS liik,
                                                l_kpv                                                   AS kpv,
                                                (l_kpv +
                                                 coalesce(
                                                             (SELECT tahtpaev FROM ou.config WHERE rekvid = l_rekvid LIMIT 1),
                                                             20)::INTEGER)::DATE                        AS tahtaeg,
                                                l_asutus_id                                             AS asutusid,
                                                l_aa                                                    AS aa,
                                                l_laps_id                                               AS lapsid,
                                                'Arve, taabeli alus ' || date_part('month', l_kpv)::TEXT ||
                                                '/' ||
                                                date_part('year', l_kpv)::TEXT || ' kuu eest' || l_selg AS muud,
                                                v_taabel.asendus_id                                     AS asendus_id,
                                                json_arvrea                                             AS "gridData") row);

                    -- подготавливаем параметры для создания счета
                    SELECT row_to_json(row)
                    INTO json_object
                    FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data) row;

                    IF (v_taabel.hind - v_taabel.real_soodus) * v_taabel.kogus <> 0 OR l_arve_kogus <> 0
                    THEN
                        SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;
                    ELSE
                        l_arve_kogus = 0; -- обнулим кол-во услуг
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
                   FROM (SELECT coalesce(l_arv_id, 0)                                   AS id,
                                l_number                                                AS number,
                                l_doklausend_id                                         AS doklausid,
                                l_liik                                                  AS liik,
                                l_kpv                                                   AS kpv,
                                (l_kpv +
                                 coalesce(
                                             (SELECT tahtpaev FROM ou.config WHERE rekvid = l_rekvid LIMIT 1),
                                             20)::INTEGER)::DATE                        AS tahtaeg,
                                l_asutus_id                                             AS asutusid,
                                l_laps_id                                               AS lapsid,
                                l_aa                                                    AS aa,
                                'Arve, taabeli alus ' || date_part('month', l_kpv)::TEXT || '/' ||
                                date_part('year', l_kpv)::TEXT || ' kuu eest' || l_selg AS muud,
                                jsonb_print                                             AS print,
                                v_taabel.asendus_id                                     AS asendus_id,
                                json_arvread                                            AS "gridData") row);


    IF (jsonb_array_length(json_arvread) > 0)
    THEN

        -- подготавливаем параметры для создания счета
        SELECT row_to_json(row)
        INTO json_object
        FROM (SELECT coalesce(l_arv_id, 0) AS id, l_json_arve AS data) row;


        -- check for arve summa
/*    IF l_arve_summa < 0
    THEN
        result = 0;
        error_message = 'Dokumendi summa = 0';
        error_code = 1;
        RETURN;
    ELSE
*/


        IF l_arve_kogus <> 0
        THEN
            SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;

        END IF;
    ELSE
        IF l_arve_kogus = 0
        THEN
            l_arv_id = NULL;
            result = 0;
            error_code = 1;
            error_message =
                            'Kehtiv teenused ei leidnud,  Isikukood: ' || v_laps.isikukood || ', Nimi:' || v_laps.nimi;
            RETURN;
        END IF;
    END IF;


    -- проверка

    IF l_arv_id IS NOT NULL AND l_arv_id > 0
    THEN
        -- контируем
        PERFORM docs.gen_lausend_arv(l_arv_id, user_id);
        error_message = 'Isikukood: ' || v_laps.isikukood || ', Nimi:' || v_laps.nimi || ', arveId:' ||
                        coalesce(l_arv_id, 0)::TEXT;

        result = l_arv_id;
    ELSE
        IF l_arve_kogus = 0
        THEN
            error_code = 1;
            error_message =
                            'Dokumendi koostamise viga,  Isikukood: ' || v_laps.isikukood || ', Nimi:' || v_laps.nimi;
        ELSE
            -- счет создан как отдельный
            error_message = 'Isikukood: ' || v_laps.isikukood || ', Nimi:' || v_laps.nimi;
            result = l_arve_kogus;
        END IF;
    END IF;
    RETURN;

EXCEPTION
    WHEN OTHERS
        THEN
            RAISE NOTICE ' error % %', SQLERRM, SQLSTATE;
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
REVOKE EXECUTE ON FUNCTION lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE) FROM arvestaja;

--GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE) TO arvestaja;


/*
N user_id INTEGER,
                                                             IN l_laps_id INTEGER,
                                                             IN l_kpv DATE DEFAULT current_date,

select lapsed.koosta_arve_taabeli_alusel(5394, 6636, '2023-04-18')
 */

