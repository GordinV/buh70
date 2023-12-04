DROP FUNCTION IF EXISTS palk.sp_calc_sots(INTEGER, INTEGER, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS palk.sp_calc_sots(params JSONB);
DROP FUNCTION IF EXISTS palk.sp_calc_sots(user_id INTEGER, params JSON);

DROP FUNCTION IF EXISTS palk.sp_calc_sots_(user_id INTEGER, params JSON);


CREATE OR REPLACE FUNCTION palk.sp_calc_sots(user_id INTEGER, params JSON,
                                             OUT summa NUMERIC,
                                             OUT sm NUMERIC,
                                             OUT selg TEXT,
                                             OUT error_code INTEGER,
                                             OUT result INTEGER,
                                             OUT error_message TEXT,
                                             OUT data JSONB)
    LANGUAGE plpgsql
AS
$$
DECLARE
    l_lepingid                         INTEGER        = params ->> 'lepingid';
    l_libId                            INTEGER        = params ->> 'libid';
    l_kpv                              DATE           = coalesce((params ->> 'kpv') :: DATE, current_date);
    l_pk_summa                         NUMERIC        = coalesce((params ->> 'summa') :: NUMERIC, 33);
    is_percent                         BOOLEAN        = coalesce((params ->> 'is_percent') :: BOOLEAN,
                                                                 TRUE); -- kas pk summa percentis (33%)
    l_min_sots                         INTEGER        = ((coalesce((params ->> 'minsots') :: INTEGER, 0)) :: INTEGER);
    l_alus_summa                       NUMERIC(12, 4) = params ->> 'alus_summa'; -- tulud , milliest arvestame sots.maks
    kas_arvesta_min_sots               BOOLEAN        = coalesce((params ->> 'kas_min_sots')::BOOLEAN, FALSE);
    l_round                            NUMERIC        = 0.01;
    l_params                           JSON;

    v_tooleping                        RECORD;
    l_min_palk                         NUMERIC(12, 4) = 584; --alus arvestada sots.maks min palgast (2021)

    ln_umardamine                      NUMERIC(14, 4) = 0;
    l_sotsmaks_min_palgast             NUMERIC(14, 4) = 0;
    l_enne_sotsmaks_min_palgast_alus   NUMERIC(14, 4) = 0;
    l_enne_arvestatud_sotsmaks         NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks
    l_enne_arvestatud_sotsmaks_palgast NUMERIC(14, 4) = 0; -- summa, mis ole arvestatud koos tulu summaga, palk.oper.sotsmaks, va puhkus

    l_enne_koostatud_sotsmaks          NUMERIC(14, 4) = 0; -- sotsmaks, arvestatus selles kuues enne kaesolev arvestus
    l_too_paevad                       INTEGER        = 30;
    l_puudu_paevad                     INTEGER        = 0;
    l_last_paev                        DATE           =
            (date(year(l_kpv), month(l_kpv), 1) + INTERVAL '1 month') :: DATE - 1;
    l_paevad_periodis                  INTEGER        = 30;
    l_min_sotsmaks_alus                NUMERIC(14, 4) = 0; -- основание для до расчет до мин. соц. налога
    l_lisa_sm                          NUMERIC(14, 4) = 0; -- до начисленные соц. налог
    l_1090_isik                        NUMERIC(14, 4) = 0; -- до начисленные соц. налог? итого по работнику
    l_selg                             TEXT           = '';


BEGIN

    IF l_alus_summa IS NULL
    THEN
        -- meil ei ole alus summa, vaja arvestada alus

        -- select lepinguandmed
        SELECT t.pohikoht,
               t.rekvid,
               t.algab,
               t.lopp,
               t.parentid
        INTO v_tooleping
        FROM palk.tooleping t
        WHERE t.id = l_lepingid;


        SELECT pk.summa,
               empty(pk.percent_ :: INTEGER),
               coalesce(pk.minsots, 0) AS minsots,
               coalesce(pc.minpalk, 0) AS minpalk,
               l.round
               --    INTO v_palk_kaart
        INTO l_pk_summa, is_percent, l_min_sots, l_min_palk, l_round
        FROM palk.palk_kaart pk
                 LEFT OUTER JOIN palk.palk_config pc ON pc.rekvid = v_tooleping.rekvid
                 INNER JOIN palk.com_palk_lib l ON pk.libid = l.id
        WHERE pk.lepingid = l_lepingid
          AND libId = l_libId;


        IF coalesce(l_min_sots, 0) > 0 AND kas_arvesta_min_sots
        THEN
            -- расчет СН с мин. ЗП
            -- kontrollime enne arvestatud sotsmaks

            SELECT sum(po.summa)
                   FILTER ( WHERE po.palk_liik :: TEXT = 'SOTSMAKS' AND (po.sotsmaks IS NULL OR po.sotsmaks = 0)),
                   sum(po.summa) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED' AND po.is_sotsmaks AND
                                                right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25')),
                   sum(po.sotsmaks) FILTER ( WHERE po.palk_liik :: TEXT = 'ARVESTUSED' AND po.is_sotsmaks AND
                                                   right(rtrim(po.konto), 2) NOT IN ('21', '23', '24', '25'))
            INTO l_enne_arvestatud_sotsmaks, l_min_sotsmaks_alus, l_enne_arvestatud_sotsmaks_palgast
            FROM (
                     SELECT p.summa,
                            p.sotsmaks,
                            p.konto,
                            p.kpv,
                            p.period,
                            (lib.properties :: JSONB ->> 'sots') :: BOOLEAN                                            AS is_sotsmaks,
                            ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                            p.lepingid
                     FROM docs.doc d
                              INNER JOIN palk.palk_oper p ON p.parentid = d.id
                              INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
                              INNER JOIN palk.tooleping t ON p.lepingid = t.id
                 ) po
            WHERE year(po.kpv) = year(l_kpv)
              AND month(po.kpv) = month(l_kpv)
              AND po.period IS NULL
              AND po.lepingid IN (SELECT t.id
                                  FROM palk.tooleping t
                                  WHERE t.parentid = v_tooleping.parentid
                                    AND t.rekvid = v_tooleping.rekvId);

            l_enne_arvestatud_sotsmaks = coalesce(l_enne_arvestatud_sotsmaks, 0);
            l_enne_arvestatud_sotsmaks_palgast = coalesce(l_enne_arvestatud_sotsmaks_palgast, 0);

            -- отсутствие на раб.месте
            -- params
            SELECT row_to_json(row)
            INTO l_params
            FROM (SELECT month(l_kpv) AS kuu,
                         year(l_kpv)  AS aasta,
                         TRUE         AS kas_kalendripaevad,
                         TRUE         AS puudumised,
                         l_lepingid   AS lepingid) row;

            l_puudu_paevad = palk.get_puudumine(l_params :: JSONB);

            IF coalesce(l_puudu_paevad, 0) > 0
            THEN
                --parandame tööpäevad, kui töötaja töötas mitte täis kuu
                l_too_paevad = CASE
                                   WHEN COALESCE(v_tooleping.lopp, l_last_paev) < l_last_paev
                                       THEN v_tooleping.lopp
                                   ELSE l_last_paev END -
                               CASE
                                   WHEN v_tooleping.algab > date(YEAR(l_kpv), MONTH(l_kpv), 1)
                                       THEN v_tooleping.algab
                                   ELSE date(YEAR(l_kpv), MONTH(l_kpv), 1) END +
                               1 - l_puudu_paevad;


            END IF;


            -- считаем календарные дни
            l_paevad_periodis =
                    palk.get_days_of_month_in_period(month(l_kpv), year(l_kpv), date(year(l_kpv), month(l_kpv), 01),
                                                     l_kpv);
            -- за вычитом отпуска и больничного
            l_paevad_periodis = l_paevad_periodis - l_puudu_paevad;
            IF l_puudu_paevad = 0
            THEN
                l_paevad_periodis = 30;
            END IF;

-- если не полный раб. месяц
            IF make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab OR
               l_kpv > coalesce(v_tooleping.lopp, l_kpv)
            THEN

                l_paevad_periodis = l_paevad_periodis - l_puudu_paevad - CASE
                                                                             WHEN make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab
                                                                                 THEN (day(v_tooleping.algab) + 1)
                                                                             ELSE 0 END -
                                    CASE
                                        WHEN l_kpv > v_tooleping.lopp THEN (day(l_kpv) - (day(v_tooleping.lopp) - 1))
                                        ELSE 0 END;

            END IF;

            IF NOT empty(l_min_sots) OR NOT empty(l_min_palk) AND
                                        (coalesce(l_min_sotsmaks_alus, 0) * l_pk_summa * 0.01) <
                                        (l_min_palk * l_min_sots * l_pk_summa * 0.01) --arvetsame sotsmaks min.palgast
            THEN

                -- 584* 0.33 с поправкой на дни
                IF (coalesce(l_puudu_paevad, 0) > 0 OR make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab OR
                    l_kpv > coalesce(v_tooleping.lopp, l_kpv)) AND NOT empty(l_min_palk) AND
                   (coalesce(l_min_sotsmaks_alus, 0) * l_pk_summa * 0.01) <
                   (l_min_palk * l_min_sots * l_pk_summa * 0.01)
                THEN
                    l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01) / 30 * (l_paevad_periodis));
                ELSE
                    l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01));
                END IF;

            ELSE
                -- отсутствий нет (Если работник не отсутствовал ни дня на работе, то не должно быть никаких расчетов по дням. Просто 192,72.)
                l_sotsmaks_min_palgast = ((l_min_palk * l_min_sots * l_pk_summa * 0.01));

            END IF;

            -- не может быть больше мин. соц. налога
            IF l_sotsmaks_min_palgast > (l_min_palk * l_min_sots * l_pk_summa * 0.01)
            THEN
                l_sotsmaks_min_palgast = (l_min_palk * l_min_sots * l_pk_summa * 0.01);
            END IF;

            raise notice 'l_sotsmaks_min_palgast %, l_min_palk %, l_min_sots %,l_puudu_paevad %', l_sotsmaks_min_palgast, l_min_palk, l_min_sots, l_puudu_paevad;

            IF l_sotsmaks_min_palgast > l_enne_arvestatud_sotsmaks_palgast -- Поправка 17.06.2022 . Берем в зачет только соц. налог без учета отпускных
            THEN

                -- считаем необходимую для до начисления сумму налога
                summa = l_sotsmaks_min_palgast - coalesce(l_enne_arvestatud_sotsmaks_palgast, 0);
                -- основа начисления соц. налога

                IF coalesce(l_puudu_paevad, 0) > 0 OR make_date(year(l_kpv), month(l_kpv), 01) < v_tooleping.algab OR
                   l_kpv > coalesce(v_tooleping.lopp, l_kpv)

                THEN
                    sm = f_round(l_min_palk / 30 * coalesce(l_paevad_periodis, 30) - coalesce(l_min_sotsmaks_alus, 0),
                                 l_round);
                ELSE
                    sm = f_round(l_min_palk - coalesce(l_min_sotsmaks_alus, 0), l_round);
                END IF;

                selg = 'lisa SM (' + l_min_palk::TEXT + '/30 * ' ||
                       coalesce(l_paevad_periodis, 30)::TEXT || '-' + coalesce(l_min_sotsmaks_alus, 0)::TEXT +
                                                                ') = ' + coalesce(sm, 0)::TEXT ||
                       '* 0.33 = ' || coalesce(summa, 0)::TEXT;

            ELSE
                -- не используем см с мин. ЗП
                summa = 0;
                sm = 0;
            END IF;


        ELSE
            -- обычный соц. налог
            SELECT sum(po.sotsmaks) AS sotsmaks,
                   sum(po.summa)
            INTO summa, l_alus_summa
            FROM (SELECT p.summa,
                         p.sotsmaks,
                         p.konto,
                         p.kpv,
                         p.rekvid,
                         p.libid,
                         p.period,
                         (lib.properties :: JSONB ->> 'sots') :: BOOLEAN                                            AS is_sotsmaks,
                         ((enum_range(NULL :: PALK_LIIK))[(lib.properties :: JSONB ->> 'liik') :: INTEGER]) :: TEXT AS palk_liik,
                         p.lepingid
                  FROM docs.doc d
                           INNER JOIN palk.palk_oper p ON p.parentid = d.id
                           INNER JOIN libs.library lib ON p.libid = lib.id AND lib.library = 'PALK'
                           INNER JOIN palk.tooleping t ON p.lepingid = t.id
                 ) po
                     INNER JOIN libs.library l ON l.id = po.libid
            WHERE po.kpv = l_kpv
              AND po.rekvid = v_tooleping.rekvId
              AND po.lepingId = l_lepingid
              AND po.palk_liik = 'ARVESTUSED'
              AND po.period IS NULL
              AND po.sotsmaks IS NOT NULL;

            selg = 'Enne arvestatud SM ' || summa::TEXT || ', alus ' || l_alus_summa::TEXT;

        END IF;

    ELSE
        -- arvestus
        summa = l_alus_summa * l_pk_summa * 0.01;
        selg = l_alus_summa :: TEXT || ' * ' || (l_pk_summa * 0.01) :: TEXT;

    END IF;

    result = 1;
    summa = coalesce(f_round(summa, l_round), 0);
    l_params = to_jsonb(row.*)
               FROM (
                        SELECT NULL                   AS doc_id,
                               'Õnnestus'             AS error_message,
                               0::INTEGER             AS error_code,
                               summa                  AS summa,
                               selg                   AS selg,
                               sm:: NUMERIC           AS sm,
                               l_sotsmaks_min_palgast AS sotsmaks_min_palgast
                    ) row;
    data = coalesce(data, '[]'::JSONB) || l_params::JSONB;

    RETURN;

END;

$$;


/*
SELECT *
FROM palk.sp_calc_sots_(70, '        {
  "lepingid": 31001,
  "libid": 146704,
  "kpv": 20210531,
  "kas_min_sots": true
}'::JSON)

select * from palk.sp_calc_sots(88, '{"lepingid":35183,"libid":149081,"kpv":20220228,"kas_min_sots":true}'::JSON)


 */