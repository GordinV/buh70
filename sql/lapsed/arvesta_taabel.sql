-- Function: docs.sp_delete_mk(integer, integer)

DROP FUNCTION IF EXISTS lapsed.arvesta_taabel(INTEGER, INTEGER, DATE);
DROP FUNCTION IF EXISTS lapsed.arvesta_taabel_(INTEGER, INTEGER, DATE);

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
    l_rekvid     INTEGER = (SELECT rekvid
                            FROM ou.userid u
                            WHERE id = user_id
                            LIMIT 1);

    v_kaart      RECORD;
    jsonb_row    JSONB;
    json_object  JSONB;

    l_status     INTEGER;
    DOC_STATUS   INTEGER = 1; -- только активные услуги
    l_taabel_id  INTEGER;
    l_count      INTEGER = 0;
    userName     TEXT    = (SELECT ametnik
                            FROM ou.userid
                            WHERE id = user_id);
    l_message    TEXT;
    v_laps       RECORD;
    l_too_paevad INTEGER;
    l_kulastused INTEGER = 0;
    l_muud       TEXT;
    l_soodustus  NUMERIC = 0;

BEGIN
    doc_type_id = 'LAPSE_TAABEL';
    -- will return docTypeid of new doc

    -- логируем имя, кому считаем
    SELECT *, lapsed.get_viitenumber(l_rekvid, l_laps_id) AS viitenr
    INTO v_laps
    FROM lapsed.laps
    WHERE id = l_laps_id;

    l_message = 'Isikukood: ' || ltrim(rtrim(v_laps.isikukood)) || ', Nimi:' || ltrim(rtrim(v_laps.nimi));
    viitenr = v_laps.viitenr;

    -- удаляем табель
    PERFORM lapsed.sp_delete_lapse_taabel(user_id, t.id)
    FROM lapsed.lapse_taabel t
    WHERE t.parentid = l_laps_id
      AND kuu = month(l_kpv)
      AND aasta = year(l_kpv)
      AND rekvid = l_rekvid
      AND NOT umberarvestus
      AND staatus < 2;

    -- делаем выборку услуг, не предоплатных

    FOR v_kaart IN
        SELECT lk.nomid,
               lk.id                                                      AS lapse_kaart_id,
               lk.parentid,
               n.uhik,
               coalesce(n.properties ->> 'algoritm', 'konstantne')::TEXT  AS algoritm,
               ltrim(rtrim(n.kood))                                       AS kood,
               coalesce((lk.properties ->> 'kogus')::NUMERIC, 0)::NUMERIC AS kogus,
               date_part('month'::TEXT, l_kpv::DATE)                      AS kuu,
               date_part('year'::TEXT, l_kpv::DATE)                       AS aasta,
               lk.hind,
               (lk.properties ->> 'kas_protsent')::BOOLEAN                AS kas_protsent,
               (n.properties ->> 'tyyp')                                  AS tyyp,
               CASE
                   WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS' THEN lk.hind
                   WHEN lk.properties ->> 'soodus' IS NOT NULL THEN coalesce((lk.properties ->> 'soodus')::NUMERIC, 0)
                   ELSE 0 END ::NUMERIC * CASE
                                              WHEN (lk.properties ->> 'kas_protsent')::BOOLEAN THEN (0.01 * lk.hind)
                                              ELSE 1 END::NUMERIC         AS soodustus,

               CASE
                   WHEN (n.properties ->> 'tyyp') IS NOT NULL AND (n.properties ->> 'tyyp') = 'SOODUSTUS' THEN -1
                   WHEN (lk.properties ->> 'sooduse_alg')::DATE < l_kpv
                       AND (lk.properties ->> 'sooduse_lopp')::DATE >=
                           CASE
                               WHEN upper(n.uhik) = ('KUU') THEN make_date(year(l_kpv), month(l_kpv), 1)
                               WHEN (lk.properties ->> 'sooduse_lopp')::DATE <
                                    l_kpv AND
                                    (lk.properties ->> 'lopp_kpv')::DATE = (lk.properties ->> 'sooduse_lopp')::DATE
                                   THEN make_date(year(l_kpv), month(l_kpv), 1)
                               ELSE l_kpv END
                       THEN 1
                   ELSE 0 END                                             AS sooduse_kehtivus,

               NULL::TEXT                                                 AS muud,
               0                                                          AS too_paevad,
               0                                                          AS kulastused,
               0                                                          AS kovid,
               lk.properties ->> 'yksus'                                  AS yksus,
               0                                                          AS kovid_kokku,
               0::NUMERIC                                                 AS vahe,
               0::NUMERIC                                                 AS summa
        FROM lapsed.lapse_kaart lk
                 INNER JOIN libs.nomenklatuur n ON n.id = lk.nomid
        WHERE lk.parentid = l_laps_id
          AND lk.rekvid = l_rekvid
          AND lk.staatus <= DOC_STATUS
          AND (lk.properties ->> 'alg_kpv' IS NULL OR
               (lk.properties ->> 'alg_kpv')::DATE <= l_kpv) -- услуга должны действоаать в периоде
          AND (lk.properties ->> 'lopp_kpv' IS NULL OR
               make_date(year((lk.properties ->> 'lopp_kpv')::DATE), month((lk.properties ->> 'lopp_kpv')::DATE), 1) +
               INTERVAL '1 month' >= l_kpv)
          AND ((lk.properties ->> 'kas_ettemaks') IS NULL OR NOT (lk.properties ->> 'kas_ettemaks')::BOOLEAN)
        LOOP

            -- ищем аналогичный табель в периоде
            -- критерий
            -- 2. ребенок
            -- 3. период
            -- 4. услуги


            IF upper(v_kaart.uhik) IN ('PAEV', 'PÄEV')
            THEN
                SELECT sum(kogus)
                INTO v_kaart.kogus
                FROM lapsed.day_taabel1 t1
                         INNER JOIN lapsed.day_taabel t ON t.id = t1.parent_id
                         INNER JOIN libs.library l ON l.id = t.grupp_id

                WHERE t.staatus <> 3
                  AND t.rekv_id = l_rekvid
                  AND t1.laps_id = v_kaart.parentid
                  AND t1.nom_id = v_kaart.nomid
                  AND l.kood = v_kaart.yksus
                  AND month(t.kpv) = month(l_kpv::DATE)
                  AND year(t.kpv) = year(l_kpv::DATE);

--                v_kaart.hind = NULL;
                l_muud = NULL;
                -- нет расчета цены

            ELSIF lower(v_kaart.algoritm) IN ('külastamine')
            THEN
                -- на основании табеля посещений
                --  за основу берется кол-во рабочих дней в месяце и кол-во посещений. Указанная цена в карточке умножается на расчётный коэффициент посещений.
                --  коэффициент посещений. = цена / раб. дни в месяце * кол-во посещений

                l_too_paevad = (SELECT palk.get_work_days(
                                               (SELECT json_build_object('kuu', MONTH(l_kpv), 'aasta', YEAR(l_kpv)))::JSON));

                l_kulastused = (SELECT count(*) AS kulastavus
                                FROM (
                                         SELECT DISTINCT dt.id, dt1.laps_id, dt.rekv_id, dt.kpv
                                         FROM lapsed.day_taabel dt
                                                  INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
                                         WHERE dt1.laps_id = v_kaart.parentid
                                           AND month(dt.kpv) = month(l_kpv::DATE)
                                           AND year(dt.kpv) = year(l_kpv::DATE)
                                           AND dt.staatus < 3
                                           AND coalesce(dt1.osalemine, 0) = 1
                                     ) qry);
                IF (coalesce(l_kulastused, 0)) > 0
                THEN
                    l_muud = 'Hinna arvestuse selgitus: ' || v_kaart.hind::TEXT || '/' || l_too_paevad::TEXT ||
                             '*' || l_kulastused::TEXT;
                    v_kaart.hind = v_kaart.hind / l_too_paevad * l_kulastused;
                ELSE
                    l_muud = 'Hinna arvestuse selgitus: ' || v_kaart.hind:: TEXT || '/' || l_too_paevad::TEXT ||
                             '*' || l_kulastused::TEXT;
                    v_kaart.hind = 0; -- нет посещений
                END IF;

            ELSE

                -- поправка с 25.05. расчет идет с учетом отсутствия по причине ковида

                SELECT (visidid_kokku + puudumised_kokku), covid_kokku
                INTO l_too_paevad, l_kulastused
                FROM (
                         WITH day_taabel AS (
                             SELECT DISTINCT dt.id, dt1.osalemine, dt1.covid
                             FROM lapsed.day_taabel dt
                                      INNER JOIN lapsed.day_taabel1 dt1 ON dt.id = dt1.parent_id
                             WHERE month(dt.kpv) = month(l_kpv::DATE)
                               AND year(dt.kpv) = year(l_kpv::DATE)
                               AND dt.staatus < 3
                               AND rekv_id = l_rekvid
                               AND dt1.laps_id = v_kaart.parentid
                         )

                         SELECT count(*) FILTER (WHERE osalemine = 1)               AS visidid_kokku,
                                count(*) FILTER (WHERE osalemine = 0)               AS puudumised_kokku,
                                count(*) FILTER (WHERE osalemine = 0 AND covid = 1) AS covid_kokku
                         FROM day_taabel
                     ) qry;

                -- расчет кол-во табелей в группе за месяц
                v_kaart.too_paevad = (SELECT count(dt.id)
                                      FROM lapsed.day_taabel dt
                                               INNER JOIN libs.library l ON l.id = dt.grupp_id
                                      WHERE month(dt.kpv) = month(l_kpv::DATE)
                                        AND year(dt.kpv) = year(l_kpv::DATE)
                                        AND dt.staatus < 3
                                        AND rekv_id = l_rekvid
                                        AND l.kood = v_kaart.yksus
                );

--                v_kaart.kogus = 1;
                v_kaart.kulastused = l_kulastused;

                -- поправка на расчет из-за неполного табеля
--                l_too_paevad = v_kaart.too_paevad;

                v_kaart.kovid = (l_too_paevad - l_kulastused)::NUMERIC;
                IF coalesce(l_kulastused, 0) > 0 AND v_kaart.hind >= 0
                THEN

                    -- были пропуски с причиной = ковид
                    v_kaart.kogus = (l_too_paevad - l_kulastused)::NUMERIC / v_kaart.too_paevad::NUMERIC;

                END IF;
--                v_kaart.hind = NULL; -- нет расчета цены
                l_muud = NULL;
                IF coalesce(l_too_paevad, 0) > 0
                THEN
                    --                    А в счете желательно в строке с услугой справочно вставить количество получившихся расчетных дней - 18.
                    l_muud = '(' || (l_too_paevad - l_kulastused)::TEXT + ' päeva)';
                END IF;

            END IF;

            SELECT lt.id,
                   lt.staatus
            INTO l_taabel_id, l_status
            FROM lapsed.lapse_taabel lt
            WHERE lt.lapse_kaart_id = v_kaart.lapse_kaart_id
              AND aasta = date_part('year'::TEXT, l_kpv::DATE)
              AND kuu = date_part('month'::TEXT, l_kpv::DATE)
              AND NOT lt.umberarvestus
              AND lt.staatus <> 3 -- удаленный
            LIMIT 1;

            -- расчет разницы алгоритмов

            v_kaart.vahe = lapsed.get_differ_from_algoritm(v_kaart.hind, (v_kaart.soodustus * v_kaart.sooduse_kehtivus),
                                                           v_kaart.kogus) AS vahe;

            -- расчет суммы
            v_kaart.summa = (v_kaart.hind * v_kaart.kogus - v_kaart.soodustus * v_kaart.kogus)::NUMERIC(12, 2);

            v_kaart.soodustus = v_kaart.soodustus * v_kaart.sooduse_kehtivus ;

            IF l_taabel_id IS NULL OR l_status <> 2
            THEN
                json_object = NULL;

                -- продолжаем расчет
                -- подготавливаем параметры для сохранения

                jsonb_row = to_jsonb(v_kaart.*) || jsonb_build_object('muud', l_muud);

                SELECT row_to_json(row)
                INTO json_object
                FROM (SELECT coalesce(l_taabel_id, 0) AS id,
                             jsonb_row                AS data) row;

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
    ELSE
        -- формируем извещение
/*        INSERT INTO ou.noticed (userid, teatis,task_name)
        VALUES (user_id, l_message,'Arvesta tabel');
*/
    END IF;

    result = COALESCE(l_taabel_id, 0);
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
END;
$BODY$ LANGUAGE plpgsql
    VOLATILE
    COST 100;

REVOKE EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) FROM dbkasutaja;
REVOKE EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) FROM dbpeakasutaja;
GRANT EXECUTE ON FUNCTION lapsed.arvesta_taabel(INTEGER, INTEGER, DATE) TO arvestaja;


/*
-- 19201
select lapsed.arvesta_taabel(28, 6762,'2022-10-31')

select * from lapsed.lapsed_taabel where rekvid = 69

ыудусе * акщь

 */