-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS hooldekodu.koosta_arve_hootaabeli_alusel(INTEGER, INTEGER, DATE);

CREATE OR REPLACE FUNCTION hooldekodu.koosta_arve_hootaabeli_alusel(IN user_id INTEGER,
                                                                    IN l_isik_id INTEGER,
                                                                    IN l_kpv DATE DEFAULT current_date,
                                                                    OUT error_code INTEGER,
                                                                    OUT result INTEGER,
                                                                    OUT doc_type_id TEXT,
                                                                    OUT error_message TEXT,
                                                                    OUT viitenr TEXT)
    RETURNS RECORD AS
$BODY$

DECLARE
    l_rekvid                 INTEGER        = (SELECT rekvid
                                               FROM ou.userid u
                                               WHERE id = user_id
                                               LIMIT 1);

    l_doklausend_id          INTEGER;
    l_liik                   INTEGER        = 0;
    v_taabel                 RECORD;
    json_object              JSONB;
    l_json_arve              JSON;
    json_arvrea              JSONB          = '[]';
    json_arvread             JSONB          = '[]';

    l_tp                     TEXT           = '800699'; -- (SELECT tp FROM libs.asutus a WHERE id = l_asutus_id);

    l_arv_id                 INTEGER        = 0;
    l_number                 TEXT;
    l_arve_summa             NUMERIC        = 0;
    i                        INTEGER        = 1;
    l_aa                     TEXT           = (SELECT arve
                                               FROM ou.aa
                                               WHERE parentid IN (SELECT rekvid FROM ou.userid WHERE id = user_id)
                                                 AND kassa = 1
                                               ORDER BY default_ DESC
                                               LIMIT 1);

    l_db_konto               TEXT           = '10300002'; -- согдасно описанию отдела культуры
    v_isik                   RECORD;
    l_arve_kogus             NUMERIC        = 0; -- для проверки кол-ва услуг в счете
    l_isiku_summa_85         NUMERIC        = 0;
    l_isiku_summa_vara       NUMERIC        = 0;
    l_isiku_summa_muud       NUMERIC        = 0;
    l_sugulane_summa         NUMERIC(12, 2) = 0;
    l_arv_summa_kokku        NUMERIC        = 0;
    l_arve_rea_summa         NUMERIC        = 0;
    l_isiku_jaak_85          NUMERIC        = 0 ; --coalesce((SELECT pension85 FROM hooldekodu.hoojaak WHERE isikid = l_isik_id LIMIT 1), 0);
    l_isiku_jaak_vara        NUMERIC        = 0;
    l_isiku_jaak_muud        NUMERIC        = 0;
    l_selgetama_summa        NUMERIC        = 0; -- суммируем не распределенный остаток счета

    l_omavalitsuse_summa     NUMERIC        = 0;
    l_umardamine             NUMERIC        = 0;
    l_nom_id                 INTEGER;
    l_vat                    NUMERIC        = 0;
    l_kuu                    INTEGER        = date_part('month', l_kpv);
    l_aasta                  INTEGER        = date_part('year', l_kpv);
    l_paevad_kokku           NUMERIC;
    l_kogus_kokku            NUMERIC        = 1; -- кол-во при расчете hoolduskulud
    l_kalendri_paevad        INTEGER        = palk.get_days_of_month_in_period(l_kuu, l_aasta,
                                                                               make_date(l_aasta, l_kuu, 01),
                                                                               gomonth(make_date(l_aasta, l_kuu, 01), 1) - 1,
                                                                               FALSE,
                                                                               FALSE);
    l_hoolduskulu            NUMERIC(12, 2) = (SELECT summa
                                               FROM hooldekodu.hoo_config hc
                                               WHERE hc.library = 'RIIGI_TOETUS'
                                                 AND hc.kpv <= l_kpv
                                                 AND hc.status < 3
                                               ORDER BY hc.id DESC
                                               LIMIT 1);
    l_taskuraha_kov          NUMERIC(12, 2) = 0;
    l_taskuraha_details_json JSONB          = '[]'::JSONB;
    l_taskuraha_doc_json     JSONB          = '{}'::JSONB;
    l_journal_id             INTEGER;
    l_correction_summa       NUMERIC        = 0;

BEGIN

    IF l_isik_id IS NULL
    THEN
        -- контр-анет не найден, выходим
        result = 0;
        error_message = 'Puudub kontragent';
        error_code = 1;
        RETURN;
    END IF;


    SELECT j.pension_85, j.vara, j.muud
    INTO l_isiku_jaak_85, l_isiku_jaak_vara, l_isiku_jaak_muud
    FROM hooldekodu.get_jaak(l_rekvid, l_isik_id, l_kpv) j;


    SELECT j.taskuraha_kov
    INTO l_taskuraha_kov
    FROM hooldekodu.hoojaak j
    WHERE j.isikid = l_isik_id
    LIMIT 1;

    SELECT * INTO v_isik FROM libs.asutus WHERE id = l_isik_id;
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

    -- will return docTypeid of new doc
    doc_type_id = 'ARV';

    -- читаем табель и создаем детали счета
    FOR v_taabel IN
        SELECT ht.nomid,
               ht.arvid,
               ht.sugulane_arv_id,
               coalesce(ht.kogus, 0)                                               AS kogus,
               coalesce(ht.hind)                                                   AS hind,
               coalesce(ht.soodustus)                                              AS soodustus,
               coalesce(ht.summa)                                                  AS summa,
               CASE WHEN upper(n.uhik) = 'KUU' THEN ht.alus_hind ELSE ht.summa END AS summa_kokku,
               coalesce((ht.properties ->> 'umardamine')::NUMERIC, 0)::NUMERIC     AS umardamine,
               ht.id                                                               AS ht_taabel_id,
               hl.id                                                               AS hl_leping_id,
               hl.sugulane_osa                                                     AS sugulane_osa,
               hl.sugulane_id,
               coalesce((hl.properties ->> 'algoritm')::INTEGER, 0)::INTEGER       AS algoritm,
               0                                                                   AS vat,
               (n.properties::JSONB ->> 'konto')::VARCHAR(20)                      AS konto,
               (n.properties::JSONB ->> 'projekt')::VARCHAR(20)                    AS projekt,
               (n.properties::JSONB ->> 'tunnus')::VARCHAR(20)                     AS tunnus,
               (n.properties::JSONB ->> 'tegev')::VARCHAR(20)                      AS tegev,
               (n.properties::JSONB ->> 'allikas')::VARCHAR(20)                    AS allikas,
               (n.properties::JSONB ->> 'rahavoog')::VARCHAR(20)                   AS rahavoog,
               (n.properties::JSONB ->> 'artikkel')::VARCHAR(20)                   AS artikkel,
               coalesce(ht.muud, '')                                               AS markused,
               n.uhik,
               n.hind                                                              AS alus_hind,
               hl.makse_viis,
               hl.bruttosissetulek,
               hl.netosissetulek,
               hl.loppkpv
        FROM libs.asutus a
                 INNER JOIN hooldekodu.hootaabel ht ON ht.isikid = a.id
                 INNER JOIN libs.nomenklatuur n ON n.id = ht.nomid
                 INNER JOIN hooldekodu.hooleping hl ON hl.id = ht.lepingid

        WHERE a.id = l_isik_id
          AND ht.status < 3
          AND date_part('month', ht.kpv) = month(l_kpv)
          AND date_part('year', ht.kpv) = year(l_kpv)
          AND hl.rekvid = l_rekvid
          AND ht.summa > 0
        ORDER BY hl.algkpv
                , ht.summa DESC
        LOOP

            -- проверим на алгоритм. 0 - на конец месяца (дефолт), иначе общий остаток, 2 - начисляется на полную сумму за минусом карманных от города
            IF v_taabel.algoritm <> 0 AND v_taabel.algoritm < 2
            THEN
                -- используем весь остаток
                SELECT hj.pension85 AS pension_85, vara, muud
                INTO l_isiku_jaak_85, l_isiku_jaak_vara, l_isiku_jaak_muud
                FROM hooldekodu.hoojaak hj
                WHERE hj.isikid = l_isik_id
                LIMIT 1;

            END IF;


            l_umardamine = coalesce(v_taabel.umardamine, 0);

            l_arv_id = v_taabel.arvid;
            l_arve_kogus = l_arve_kogus + v_taabel.kogus;
            l_arv_summa_kokku = v_taabel.summa + l_umardamine;

            IF (v_taabel.kogus <> l_kalendri_paevad)
            THEN
                -- суцмма в табеле не верная, пересчитваем сумму и округление
/*
 Месяц 1150 евро.  Родственников нет.

 541 – Hoolduskulud будут всегда.

609/31*22=432,19 евро. По дням считаем только долю, подлежащую оплате клиентом (на сегодня 1150-541  или 1050-541)


 */
                l_correction_summa =
                        round((v_taabel.alus_hind - l_hoolduskulu) * (v_taabel.kogus / l_kalendri_paevad), 2);
                l_arv_summa_kokku = l_correction_summa + l_hoolduskulu;
                v_taabel.hind = l_arv_summa_kokku / v_taabel.kogus;
                v_taabel.summa = l_arv_summa_kokku;

            END IF;


            IF l_arv_id IS NOT NULL AND NOT exists(SELECT id FROM docs.arv WHERE parentid = l_arv_id)
            THEN
                -- удаленный счет
                UPDATE hooldekodu.hootaabel SET arvid = NULL WHERE id = v_taabel.arvid;
                l_arv_id = NULL;
            END IF;

            IF l_nom_id IS NULL
            THEN
                -- сохраним ид первой услуги
                l_nom_id = v_taabel.nomid;
                l_vat = v_taabel.vat;
            END IF;

            -- если не полный месяц, кооректируем сумму пособия на дни
/*
    -- Руководство SAA опять решило изменить методику расчета для лиц, находящихся в Hooldekodu не полный месяц. Hoolduskulud будет 541евро независимо от того, лежал в больнице или нет
    l_hoolduskulu = l_hoolduskulu * v_taabel.kogus / l_kalendri_paevad;
*/

            IF (v_taabel.loppkpv < date(year(l_kpv), month(l_kpv), l_kalendri_paevad))
            THEN
                l_paevad_kokku = l_kalendri_paevad - (l_kalendri_paevad - day(v_taabel.loppkpv));
                l_kogus_kokku = round((l_paevad_kokku / l_kalendri_paevad), 3)::NUMERIC;
                l_hoolduskulu = l_hoolduskulu * (l_paevad_kokku / l_kalendri_paevad)::NUMERIC;
            END IF;


            -- проверяем на наличие у пенсионера денег на оплату
            IF coalesce(l_sugulane_summa, 0) = 0
            THEN
                l_arv_summa_kokku = (v_taabel.vat / 100) + v_taabel.summa + l_umardamine;
                -- за вычитом суммы от гос-ва
                l_isiku_summa_85 = l_isiku_summa_85 + (l_arv_summa_kokku - l_hoolduskulu);

                -- распределяем сумму по источникам
                IF l_isiku_jaak_85 >= 0
                THEN
                    IF l_isiku_jaak_85 >= (l_arv_summa_kokku - l_hoolduskulu)
                    THEN
                        l_isiku_summa_85 = (l_arv_summa_kokku - l_hoolduskulu);
                        l_isiku_jaak_85 = l_isiku_jaak_85 - (l_arv_summa_kokku - l_hoolduskulu);
                        l_selgetama_summa = 0;
                    ELSE
                        -- источника пенсия 85 не хватает для покрытия, запоминаем разницу
                        l_selgetama_summa = (l_arv_summa_kokku - l_hoolduskulu) - l_isiku_jaak_85;
                        l_isiku_summa_85 = l_isiku_jaak_85;
                        l_isiku_jaak_85 = 0;
                    END IF;
                END IF;

                IF l_selgetama_summa > 0 AND l_isiku_jaak_vara > 0
                THEN
                    IF l_selgetama_summa > l_isiku_jaak_vara
                    THEN
                        -- остаток суммы превышает накопления по источнику имущщество
                        l_selgetama_summa = l_selgetama_summa - l_isiku_jaak_vara;
                        l_isiku_summa_vara = l_isiku_jaak_vara;
                        l_isiku_jaak_vara = 0;
                    ELSE
                        -- распределяем сумму с истоника имущество.
                        l_isiku_summa_vara = l_selgetama_summa;
                        l_isiku_jaak_vara = l_isiku_jaak_vara - l_selgetama_summa;
                        l_selgetama_summa = 0;
                    END IF;
                END IF;

                -- если расходы не покрыты, то смотрим на источник прочее
                IF l_selgetama_summa > 0 AND l_isiku_jaak_muud > 0
                THEN
                    -- покрываем сумму из источника прочее
                    IF l_selgetama_summa > l_isiku_jaak_muud
                    THEN
                        l_isiku_summa_muud = l_isiku_jaak_muud;
                        l_selgetama_summa = l_selgetama_summa - l_isiku_jaak_muud;
                        l_isiku_jaak_muud = 0;
                    ELSE
                        l_isiku_summa_muud = l_selgetama_summa;
                        l_isiku_jaak_muud = l_isiku_jaak_muud - l_selgetama_summa;
                        l_selgetama_summa = 0;
                    END IF;
                END IF;

                -- если осталось не покрытые расходы и есть доля родственников
                IF l_selgetama_summa > 0 AND
                   coalesce(v_taabel.sugulane_osa, 0) > 0
                THEN

                    -- превышает , уменьшаем за счет родственников
                    IF l_selgetama_summa > coalesce(v_taabel.sugulane_osa, 0)
                    THEN
                        l_sugulane_summa = v_taabel.sugulane_osa;
                        l_selgetama_summa = l_selgetama_summa - l_sugulane_summa;

                    ELSE
                        l_sugulane_summa = l_selgetama_summa;
                        l_selgetama_summa = 0;
                    END IF;
                END IF;

                -- остаток суммы покрываем за счет самоуправления
                IF l_selgetama_summa > 0 AND v_taabel.algoritm <> 2
                THEN
                    l_omavalitsuse_summa = l_selgetama_summa;
                    l_selgetama_summa = 0;
                ELSE
                    -- используем пенсию для расчета доли города для алгоритмы кроме Tulu arve
                    -- если сумма (509) не превышает доход пенсионера, то он платит сам, иначе на разнику

                    l_omavalitsuse_summa = CASE
                                               WHEN (l_selgetama_summa - v_taabel.netosissetulek) > 0 AND
                                                    v_taabel.algoritm = 2 THEN
                                                   -- сумма больше дохода, город оплачивает разницу
                                                   l_selgetama_summa - v_taabel.netosissetulek
                                               WHEN (l_selgetama_summa - v_taabel.netosissetulek) < 0 AND
                                                    v_taabel.algoritm = 2
                                                   THEN
                                                   -- неттодоход превышает расходы, город не участвует
                                                   0
                                               ELSE l_selgetama_summa END;
                    l_selgetama_summa = l_selgetama_summa - l_omavalitsuse_summa;
                END IF;

            ELSE
                l_selgetama_summa = (l_arv_summa_kokku - l_hoolduskulu);

                -- списываем остаток с доли родственников
                IF (l_sugulane_summa - coalesce(v_taabel.sugulane_osa, 0)) > 0 AND
                   l_selgetama_summa > (coalesce(v_taabel.sugulane_osa, 0) - l_sugulane_summa)
                THEN
                    -- остались деньги родственников
                    l_selgetama_summa = l_selgetama_summa - (coalesce(v_taabel.sugulane_osa, 0) - l_sugulane_summa);
                    l_sugulane_summa = v_taabel.sugulane_osa;
                    -- только не для алгоритма 2
                    IF v_taabel.algoritm <> 2
                    THEN
                        l_omavalitsuse_summa = l_omavalitsuse_summa + l_selgetama_summa;
                    ELSE

                        -- в данном алгоритме мы вичитыем брутто пенсию и получаем долю города
                        l_omavalitsuse_summa = CASE
                                                   WHEN (l_selgetama_summa - v_taabel.netosissetulek) > 0 AND
                                                        v_taabel.algoritm = 2
                                                       THEN
                                                       -- неттодоход меньше затрат, на разницу компенсация
                                                       l_selgetama_summa - v_taabel.netosissetulek
                                                   WHEN (l_selgetama_summa - v_taabel.netosissetulek) < 0 AND
                                                        v_taabel.algoritm = 2
                                                       THEN
                                                       -- город не участвует
                                                       0
                                                   ELSE l_selgetama_summa END;
                        l_selgetama_summa = l_selgetama_summa - l_omavalitsuse_summa;
                    END IF;


                ELSE
                    -- списываем остаток не распределенной суммы на родственников
                    l_sugulane_summa = l_sugulane_summa + l_selgetama_summa;
                    l_selgetama_summa = 0;
                END IF;
            END IF;

            l_arve_rea_summa = (l_arv_summa_kokku);

            -- формируем строку
            json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                          FROM (SELECT v_taabel.nomid                                               AS nomid,
                                                       v_taabel.kogus                                               AS kogus,
                                                       v_taabel.hind,
                                                       l_arve_rea_summa / (1 + (v_taabel.vat / 100)) - l_umardamine AS kbmta,
                                                       l_arve_rea_summa - l_umardamine -
                                                       l_arve_rea_summa / (1 + (v_taabel.vat / 100))                AS kbm,
                                                       l_arve_rea_summa - l_umardamine                              AS summa,
                                                       l_isiku_summa_85                                             AS allikas_85,
                                                       l_isiku_summa_vara                                           AS allikas_vara,
                                                       l_isiku_summa_muud                                           AS allikas_muud,
                                                       v_taabel.tegev                                               AS kood1,
                                                       v_taabel.allikas                                             AS kood2,
                                                       v_taabel.rahavoog                                            AS kood3,
                                                       v_taabel.artikkel                                            AS kood5,
                                                       v_taabel.konto                                               AS konto,
                                                       v_taabel.tunnus,
                                                       v_taabel.projekt,
                                                       l_tp                                                         AS tp) row) :: JSONB;

            json_arvread = json_arvread || json_arvrea;
            l_isiku_summa_85 = 0;
            l_isiku_summa_vara = 0;
            l_isiku_summa_muud = 0;

-- минусуем hooluskulu
            IF l_hoolduskulu > 0
            THEN
                json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                              FROM (SELECT v_taabel.nomid                               AS nomid,
                                                           l_kogus_kokku                                AS kogus,
                                                           -1 * round(l_hoolduskulu / l_kogus_kokku, 2) AS hind,
                                                           -1 * l_hoolduskulu                           AS kbmta,
                                                           0                                            AS kbm,
                                                           -1 * l_hoolduskulu                           AS summa,
                                                           'Hoolduskulu'                                AS muud,
                                                           v_taabel.tegev                               AS kood1,
                                                           v_taabel.allikas                             AS kood2,
                                                           v_taabel.rahavoog                            AS kood3,
                                                           v_taabel.artikkel                            AS kood5,
                                                           v_taabel.konto                               AS konto,
                                                           v_taabel.tunnus,
                                                           v_taabel.projekt,
                                                           l_tp                                         AS tp) row) :: JSONB;

                json_arvread = json_arvread || json_arvrea;

                l_hoolduskulu = 0;
            END IF;


            -- taskuraha kov
            IF l_umardamine <> 0
            THEN
                json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                              FROM (SELECT v_taabel.nomid    AS nomid,
                                                           1                 AS kogus,
                                                           l_umardamine      AS hind,
                                                           l_umardamine      AS kbmta,
                                                           0                 AS kbm,
                                                           l_umardamine      AS summa,
                                                           0                 AS allikas_85,
                                                           0                 AS allikas_vara,
                                                           0                 AS allikas_muud,
                                                           l_umardamine      AS umardamine,
                                                           v_taabel.tegev    AS kood1,
                                                           v_taabel.allikas  AS kood2,
                                                           v_taabel.rahavoog AS kood3,
                                                           v_taabel.artikkel AS kood5,
                                                           v_taabel.konto    AS konto,
                                                           v_taabel.tunnus,
                                                           v_taabel.projekt,
                                                           'UMARDAMINE'      AS muud,
                                                           l_tp              AS tp) row) :: JSONB;

                json_arvread = json_arvread || json_arvrea;

            END IF;

            IF l_omavalitsuse_summa > 0
            THEN
                -- формируем строку
                json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                              FROM (SELECT v_taabel.nomid            AS nomid,
                                                           1                         AS kogus,
                                                           -1 * l_omavalitsuse_summa,
                                                           -1 * l_omavalitsuse_summa AS kbmta,
                                                           0                         AS kbm,
                                                           -1 * l_omavalitsuse_summa AS summa,
                                                           l_omavalitsuse_summa      AS omavalitsuse_osa,
                                                           v_taabel.tegev            AS kood1,
                                                           v_taabel.allikas          AS kood2,
                                                           v_taabel.rahavoog         AS kood3,
                                                           v_taabel.artikkel         AS kood5,
                                                           v_taabel.konto            AS konto,
                                                           v_taabel.tunnus,
                                                           v_taabel.projekt,
                                                           'Omavalitsuse osa'        AS muud,
                                                           l_tp                      AS tp) row) :: JSONB;

                json_arvread = json_arvread || json_arvrea;
            END IF;

            IF l_sugulane_summa > 0
            THEN
                -- формируем строку
                json_arvrea = '[]'::JSONB || (SELECT row_to_json(row)
                                              FROM (SELECT v_taabel.nomid        AS nomid,
                                                           1                     AS kogus,
                                                           -1 * l_sugulane_summa,
                                                           -1 * l_sugulane_summa AS kbmta,
                                                           0                     AS kbm,
                                                           -1 * l_sugulane_summa AS summa,
                                                           l_sugulane_summa      AS sugulane_osa,
                                                           v_taabel.tegev        AS kood1,
                                                           v_taabel.allikas      AS kood2,
                                                           v_taabel.rahavoog     AS kood3,
                                                           v_taabel.artikkel     AS kood5,
                                                           v_taabel.konto        AS konto,
                                                           v_taabel.tunnus,
                                                           v_taabel.projekt,
                                                           'Sugulane osa'        AS muud,
                                                           l_tp                  AS tp) row) :: JSONB;

                json_arvread = json_arvread || json_arvrea;

            END IF;

            -- calc arve summa
            l_arve_summa = l_arve_summa + l_arve_rea_summa - l_taskuraha_kov;
            l_isiku_jaak_85 = l_isiku_jaak_85 - l_isiku_summa_85;
            i = i + 1;

        END LOOP;

    -- создаем параметры
    -- number
    -- HKOP
    l_number = 'HKOP' || docs.sp_get_number(l_rekvid, 'ARV', YEAR(l_kpv), l_doklausend_id);

    l_json_arve = (SELECT to_json(ROW)
                   FROM (SELECT COALESCE(l_arv_id, 0)                         AS id,
                                l_number                                      AS number,
                                l_doklausend_id                               AS doklausid,
                                l_liik                                        AS liik,
                                l_kpv                                         AS kpv,
                                l_kpv + 15                                    AS tahtaeg,
                                l_isik_id                                     AS asutusid,
                                l_aa                                          AS aa,
                                'Arve,  ' || date_part('month', l_kpv)::TEXT || '/' ||
                                date_part('year', l_kpv)::TEXT || ' kuu eest' AS lisa,
                                'HOOLDEKODU_ISIKU_OSA'                        AS tyyp,
                                CASE
                                    WHEN l_taskuraha_kov > 0 AND v_taabel.makse_viis = 3 THEN l_taskuraha_kov
                                    ELSE 0 END                                AS taskuraha_kov,
                                json_arvread                                  AS "gridData") ROW);

    -- check for arve summa
    IF (l_arve_summa = 0 AND l_sugulane_summa = 0) OR jsonb_array_length(json_arvread) = 0
    THEN
        result = 0;
        error_message = 'Dokumendi summa = 0';
        error_code = 1;
        RETURN;
    END IF;

    -- сохраним расчет сумм

    UPDATE hooldekodu.hootaabel
    SET properties = COALESCE(properties, '{}'::JSONB) ||
                     jsonb_build_object('isiku_osa', l_arve_summa, 'sugulane_osa', l_sugulane_summa, 'omavalitsus_osa',
                                        l_omavalitsuse_summa)
    WHERE isikid = l_isik_id
      AND status < 3
      AND date_part('month', kpv) = MONTH(l_kpv)
      AND date_part('year', kpv) = YEAR(l_kpv)
      AND rekvid = l_rekvid;


    -- подготавливаем параметры для создания счета
    SELECT row_to_json(ROW)
    INTO json_object
    FROM (SELECT COALESCE(l_arv_id, 0) AS id, l_json_arve AS DATA) ROW;


    IF l_arve_kogus <> 0
    THEN
        SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;
    ELSE
        l_arv_id = NULL;
        result = 0;
        error_code = 1;
        error_message =
                    'Kehtiv teenused ei leidnud,  Isikukood: ' || v_isik.regkood || ', Nimi:' ||
                    v_isik.nimetus;
        RETURN;
    END IF;

    IF l_arv_id IS NOT NULL AND l_arv_id > 0
    THEN
        -- суммируем сумму счета

        SELECT a.summa
        INTO l_arve_summa
        FROM docs.arv a
        WHERE a.parentid = l_arv_id;

        IF l_arve_summa > 0
        THEN
            -- контируем
            PERFORM docs.gen_lausend_arv(l_arv_id, user_id);
        END IF;

        IF l_taskuraha_kov > 0 AND v_taabel.makse_viis = 3
        THEN
            -- формируем проводку , как оплату счета по алгоритму taskuraha kov

            l_taskuraha_details_json = '[]'::JSONB ||
                                       jsonb_build_object('id', 0, 'summa', l_taskuraha_kov, 'deebet', '20356001',
                                                          'kreedit', '10300002', 'lisa_d', '800699', 'lisa_k', '800699',
                                                          'tunnus', v_taabel.tunnus, 'proj', v_taabel.projekt, 'kood1',
                                                          v_taabel.tegev, 'kood2', v_taabel.allikas, 'kood3',
                                                          v_taabel.rahavoog, 'kood5', v_taabel.artikkel
                                           );

            l_taskuraha_doc_json = jsonb_build_object('id', 0, 'doc_type_id', 'JOURNAL', 'kpv', l_kpv, 'selg',
                                                      'Taskuraha taasarveldus', 'asutusid', l_isik_id, 'dok', l_number,
                                                      'gridData', l_taskuraha_details_json
                );

            l_taskuraha_doc_json = jsonb_build_object('id', 0, 'data', l_taskuraha_doc_json);

            l_journal_id = docs.sp_salvesta_journal(l_taskuraha_doc_json :: JSON, user_Id, l_rekvid);

            IF coalesce(l_taskuraha_kov, 0) = 0
            THEN
                RAISE EXCEPTION 'Viga, taskuraha taasarvelduse koostamine viga';
            END IF;
            l_taskuraha_kov = 0;

        END IF;


        -- связь
        UPDATE hooldekodu.hootaabel
        SET arvid = l_arv_id
        WHERE isikid = l_isik_id
          AND status < 3
          AND date_part('month', kpv) = MONTH(l_kpv)
          AND date_part('year', kpv) = YEAR(l_kpv)
          AND rekvid = l_rekvid;

        error_message = 'Isikukood: ' || v_isik.regkood || ', Nimi:' || v_isik.nimetus || ', arveId:' ||
                        COALESCE(l_arv_id, 0)::TEXT;

        result = l_arv_id;
    ELSE
        error_code = 1;
        error_message =
                    'Dokumendi koostamise viga,  Isikukood: ' || v_isik.regkood || ', Nimi:' ||
                    v_isik.nimetus;

    END IF;

    -- если есть доля родственника, то формируем второй счет на сумму его доли
    IF coalesce(l_sugulane_summa, 0) > 0
    THEN
        l_arv_id = (SELECT sugulane_arv_id
                    FROM hooldekodu.hootaabel
                    WHERE isikid = l_isik_id
                      AND status < 3
                      AND date_part('month', kpv) = MONTH(l_kpv)
                      AND date_part('year', kpv) = YEAR(l_kpv)
                      AND rekvid = l_rekvid
                    ORDER BY id
                    LIMIT 1);

        -- формируем строку
        json_arvrea = '[]'::JSONB || (SELECT row_to_json(ROW)
                                      FROM (SELECT l_nom_id                                                      AS nomid,
                                                   1                                                             AS kogus,
                                                   l_sugulane_summa,
                                                   l_sugulane_summa / (1 + (l_vat / 100))                        AS kbmta,
                                                   (l_sugulane_summa - (l_sugulane_summa / (1 + (l_vat / 100)))) AS kbm,
                                                   l_sugulane_summa                                              AS summa,
                                                   v_taabel.tegev                                                AS kood1,
                                                   v_taabel.allikas                                              AS kood2,
                                                   v_taabel.rahavoog                                             AS kood3,
                                                   v_taabel.artikkel                                             AS kood5,
                                                   v_taabel.konto                                                AS konto,
                                                   v_taabel.tunnus,
                                                   v_taabel.projekt,
                                                   l_tp                                                          AS tp) ROW) :: JSONB;

        -- calc arve summa
        l_arve_summa = l_sugulane_summa;
        -- ищем подходящий профиль
        l_doklausend_id = (SELECT dp.id
                           FROM libs.dokprop dp
                                    INNER JOIN libs.library l ON l.id = dp.parentid
                           WHERE dp.rekvid = l_rekvid
                             AND (dp.details ->> 'konto')::TEXT = '10300019'::TEXT
                             AND l.kood = 'ARV'
                           ORDER BY dp.id DESC
                           LIMIT 1
        );


        -- HKOL
        l_number = 'HKOL' || docs.sp_get_number(l_rekvid, 'ARV', YEAR(l_kpv), l_doklausend_id);

        l_arv_id = v_taabel.sugulane_arv_id;

        l_json_arve = (SELECT to_json(ROW)
                       FROM (SELECT COALESCE(l_arv_id, 0)                         AS id,
                                    l_number                                      AS number,
                                    l_doklausend_id                               AS doklausid,
                                    l_liik                                        AS liik,
                                    l_kpv                                         AS kpv,
                                    l_kpv + 15                                    AS tahtaeg,
                                    l_isik_id                                     AS asutusid,
                                    l_aa                                          AS aa,
                                    'Arve,  ' || date_part('month', l_kpv)::TEXT || '/' ||
                                    date_part('year', l_kpv)::TEXT || ' kuu eest' AS lisa,
                                    'HOOLDEKODU_SUGULUANE_OSA'                    AS tyyp,
                                    json_arvrea                                   AS "gridData") ROW);

        -- подготавливаем параметры для создания счета
        SELECT row_to_json(ROW)
        INTO json_object
        FROM (SELECT 0 AS id, l_json_arve AS DATA) ROW;

        SELECT docs.sp_salvesta_arv(json_object :: JSON, user_id, l_rekvid) INTO l_arv_id;

        IF coalesce(l_arv_id, 0) > 0
        THEN
            PERFORM docs.gen_lausend_arv(l_arv_id, user_id);
            -- связь
            UPDATE hooldekodu.hootaabel
            SET sugulane_arv_id = l_arv_id
            WHERE isikid = l_isik_id
              AND status < 3
              AND date_part('month', kpv) = MONTH(l_kpv)
              AND date_part('year', kpv) = YEAR(l_kpv)
              AND rekvid = l_rekvid;

        END IF;
    END IF;
END;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

GRANT EXECUTE ON FUNCTION hooldekodu.koosta_arve_hootaabeli_alusel(INTEGER, INTEGER, DATE) TO soametnik;
GRANT EXECUTE ON FUNCTION hooldekodu.koosta_arve_hootaabeli_alusel(INTEGER, INTEGER, DATE) TO hkametnik;

--GRANT EXECUTE ON FUNCTION lapsed.koosta_arve_taabeli_alusel(INTEGER, INTEGER, DATE) TO arvestaja;


/*

select * from libs.asutus where regkood = '43708183722'

select hooldekodu.koosta_arve_hootaabeli_alusel(5175, 21639, '2023-07-31')

select * from ou.userid where rekvid = 132 and kasutaja = 'vlad'

select * from cur_journal where asutusid = 43192

 */

